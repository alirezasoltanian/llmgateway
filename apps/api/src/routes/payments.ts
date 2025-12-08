import { createRoute, OpenAPIHono } from "@hono/zod-openapi";
import { HTTPException } from "hono/http-exception";
import Stripe from "stripe";
import { z } from "zod";

import { ensureStripeCustomer } from "@/stripe.js";

import { db, eq, tables } from "@llmgateway/db";
import { calculateFees } from "@llmgateway/shared";

import type { ServerTypes } from "@/vars.js";

export const stripe = new Stripe(
	process.env.STRIPE_SECRET_KEY || "sk_test_123",
	{
		apiVersion: "2025-04-30.basil",
	},
);

export const payments = new OpenAPIHono<ServerTypes>();

const createPaymentIntent = createRoute({
	method: "post",
	path: "/create-payment-intent",
	request: {
		body: {
			content: {
				"application/json": {
					schema: z.object({
						amount: z.number().int().min(5),
					}),
				},
			},
		},
	},
	responses: {
		200: {
			content: {
				"application/json": {
					schema: z.object({
						clientSecret: z.string(),
					}),
				},
			},
			description: "Payment intent created successfully",
		},
	},
});

payments.openapi(createPaymentIntent, async (c) => {
	const user = c.get("user");

	if (!user) {
		throw new HTTPException(401, {
			message: "Unauthorized",
		});
	}
	const { amount } = c.req.valid("json");

	const userOrganization = await db.query.userOrganization.findFirst({
		where: {
			userId: user.id,
		},
		with: {
			organization: true,
		},
	});

	if (!userOrganization || !userOrganization.organization) {
		throw new HTTPException(404, {
			message: "Organization not found",
		});
	}

	const organizationId = userOrganization.organization.id;

	const stripeCustomerId = await ensureStripeCustomer(organizationId);

	const feeBreakdown = calculateFees({
		amount,
		organizationPlan: userOrganization.organization.plan,
	});

	const paymentIntent = await stripe.paymentIntents.create({
		amount: Math.round(feeBreakdown.totalAmount * 100),
		currency: "usd",
		description: `Credit purchase for ${amount} USD (including fees)`,
		customer: stripeCustomerId,
		metadata: {
			organizationId,
			baseAmount: amount.toString(),
			totalFees: feeBreakdown.totalFees.toString(),
			userEmail: user.email,
			userId: user.id,
		},
	});

	return c.json({
		clientSecret: paymentIntent.client_secret || "",
	});
});

const createSetupIntent = createRoute({
	method: "post",
	path: "/create-setup-intent",
	request: {},
	responses: {
		200: {
			content: {
				"application/json": {
					schema: z.object({
						clientSecret: z.string(),
					}),
				},
			},
			description: "Setup intent created successfully",
		},
	},
});

payments.openapi(createSetupIntent, async (c) => {
	const user = c.get("user");

	if (!user) {
		throw new HTTPException(401, {
			message: "Unauthorized",
		});
	}

	const userOrganization = await db.query.userOrganization.findFirst({
		where: {
			userId: user.id,
		},
		with: {
			organization: true,
		},
	});

	if (!userOrganization || !userOrganization.organization) {
		throw new HTTPException(404, {
			message: "Organization not found",
		});
	}

	const organizationId = userOrganization.organization.id;

	const setupIntent = await stripe.setupIntents.create({
		usage: "off_session",
		metadata: {
			organizationId,
		},
	});

	return c.json({
		clientSecret: setupIntent.client_secret || "",
	});
});

const getPaymentMethods = createRoute({
	method: "get",
	path: "/payment-methods",
	request: {},
	responses: {
		200: {
			content: {
				"application/json": {
					schema: z.object({
						paymentMethods: z.array(
							z.object({
								id: z.string(),
								stripePaymentMethodId: z.string(),
								type: z.string(),
								isDefault: z.boolean(),
								cardBrand: z.string().optional(),
								cardLast4: z.string().optional(),
								expiryMonth: z.number().optional(),
								expiryYear: z.number().optional(),
							}),
						),
					}),
				},
			},
			description: "Payment methods retrieved successfully",
		},
	},
});

payments.openapi(getPaymentMethods, async (c) => {
	const user = c.get("user");

	if (!user) {
		throw new HTTPException(401, {
			message: "Unauthorized",
		});
	}

	const userOrganization = await db.query.userOrganization.findFirst({
		where: {
			userId: user.id,
		},
		with: {
			organization: true,
		},
	});

	if (!userOrganization || !userOrganization.organization) {
		throw new HTTPException(404, {
			message: "Organization not found",
		});
	}

	const organizationId = userOrganization.organization.id;

	const paymentMethods = await db.query.paymentMethod.findMany({
		where: {
			organizationId,
		},
	});

	const enhancedPaymentMethods = await Promise.all(
		paymentMethods.map(async (pm) => {
			const stripePaymentMethod = await stripe.paymentMethods.retrieve(
				pm.stripePaymentMethodId,
			);

			let cardDetails = {};
			if (stripePaymentMethod.type === "card" && stripePaymentMethod.card) {
				cardDetails = {
					cardBrand: stripePaymentMethod.card.brand,
					cardLast4: stripePaymentMethod.card.last4,
					expiryMonth: stripePaymentMethod.card.exp_month,
					expiryYear: stripePaymentMethod.card.exp_year,
				};
			}

			return {
				...pm,
				...cardDetails,
			};
		}),
	);

	return c.json({
		paymentMethods: enhancedPaymentMethods,
	});
});

const setDefaultPaymentMethod = createRoute({
	method: "post",
	path: "/payment-methods/default",
	request: {
		body: {
			content: {
				"application/json": {
					schema: z.object({
						paymentMethodId: z.string(),
					}),
				},
			},
		},
	},
	responses: {
		200: {
			content: {
				"application/json": {
					schema: z.object({
						success: z.boolean(),
					}),
				},
			},
			description: "Default payment method set successfully",
		},
	},
});

payments.openapi(setDefaultPaymentMethod, async (c) => {
	const user = c.get("user");

	if (!user) {
		throw new HTTPException(401, {
			message: "Unauthorized",
		});
	}

	const { paymentMethodId } = c.req.valid("json");

	const userOrganization = await db.query.userOrganization.findFirst({
		where: {
			userId: user.id,
		},
		with: {
			organization: true,
		},
	});

	if (!userOrganization || !userOrganization.organization) {
		throw new HTTPException(404, {
			message: "Organization not found",
		});
	}

	const organizationId = userOrganization.organization.id;

	const paymentMethod = await db.query.paymentMethod.findFirst({
		where: {
			id: paymentMethodId,
			organizationId,
		},
	});

	if (!paymentMethod) {
		throw new HTTPException(404, {
			message: "Payment method not found",
		});
	}

	await db
		.update(tables.paymentMethod)
		.set({
			isDefault: false,
		})
		.where(eq(tables.paymentMethod.organizationId, organizationId));

	await db
		.update(tables.paymentMethod)
		.set({
			isDefault: true,
		})
		.where(eq(tables.paymentMethod.id, paymentMethodId));

	return c.json({
		success: true,
	});
});

const deletePaymentMethod = createRoute({
	method: "delete",
	path: "/payment-methods/{id}",
	request: {
		params: z.object({
			id: z.string(),
		}),
	},
	responses: {
		200: {
			content: {
				"application/json": {
					schema: z.object({
						success: z.boolean(),
					}),
				},
			},
			description: "Payment method deleted successfully",
		},
	},
});

payments.openapi(deletePaymentMethod, async (c) => {
	const user = c.get("user");

	if (!user) {
		throw new HTTPException(401, {
			message: "Unauthorized",
		});
	}

	const { id } = c.req.param();

	const userOrganization = await db.query.userOrganization.findFirst({
		where: {
			userId: user.id,
		},
		with: {
			organization: true,
		},
	});

	if (!userOrganization || !userOrganization.organization) {
		throw new HTTPException(404, {
			message: "Organization not found",
		});
	}

	const organizationId = userOrganization.organization.id;

	const paymentMethod = await db.query.paymentMethod.findFirst({
		where: {
			id,
			organizationId,
		},
	});

	if (!paymentMethod) {
		throw new HTTPException(404, {
			message: "Payment method not found",
		});
	}

	await stripe.paymentMethods.detach(paymentMethod.stripePaymentMethodId);

	await db.delete(tables.paymentMethod).where(eq(tables.paymentMethod.id, id));

	return c.json({
		success: true,
	});
});

const topUpWithSavedMethod = createRoute({
	method: "post",
	path: "/top-up-with-saved-method",
	request: {
		body: {
			content: {
				"application/json": {
					schema: z.object({
						amount: z.number().int().min(5),
						paymentMethodId: z.string(),
					}),
				},
			},
		},
	},
	responses: {
		200: {
			content: {
				"application/json": {
					schema: z.object({
						success: z.boolean(),
					}),
				},
			},
			description: "Payment processed successfully",
		},
	},
});

payments.openapi(topUpWithSavedMethod, async (c) => {
	const user = c.get("user");

	if (!user) {
		throw new HTTPException(401, {
			message: "Unauthorized",
		});
	}

	const {
		amount,
		paymentMethodId,
	}: { amount: number; paymentMethodId: string } = c.req.valid("json");

	const paymentMethod = await db.query.paymentMethod.findFirst({
		where: {
			id: paymentMethodId,
		},
	});

	if (!paymentMethod) {
		throw new HTTPException(404, {
			message: "Payment method not found",
		});
	}

	const userOrganization = await db.query.userOrganization.findFirst({
		where: {
			userId: user.id,
		},
		with: {
			organization: true,
		},
	});

	if (
		!userOrganization ||
		!userOrganization.organization ||
		userOrganization.organization.id !== paymentMethod.organizationId
	) {
		throw new HTTPException(403, {
			message: "Unauthorized access to payment method",
		});
	}

	const stripeCustomerId = userOrganization.organization.stripeCustomerId;

	if (!stripeCustomerId) {
		throw new HTTPException(400, {
			message: "No Stripe customer ID found for this organization",
		});
	}

	const stripePaymentMethod = await stripe.paymentMethods.retrieve(
		paymentMethod.stripePaymentMethodId,
	);

	const cardCountry = stripePaymentMethod.card?.country || undefined;

	const feeBreakdown = calculateFees({
		amount,
		organizationPlan: userOrganization.organization.plan,
		cardCountry,
	});

	const paymentIntent = await stripe.paymentIntents.create({
		amount: Math.round(feeBreakdown.totalAmount * 100),
		currency: "usd",
		description: `Credit purchase for ${amount} USD (including fees)`,
		payment_method: paymentMethod.stripePaymentMethodId,
		customer: stripeCustomerId,
		confirm: true,
		off_session: true,
		metadata: {
			organizationId: userOrganization.organization.id,
			baseAmount: amount.toString(),
			totalFees: feeBreakdown.totalFees.toString(),
			userEmail: user.email,
			userId: user.id,
		},
	});

	if (paymentIntent.status !== "succeeded") {
		throw new HTTPException(400, {
			message: `Payment failed: ${paymentIntent.status}`,
		});
	}

	return c.json({
		success: true,
	});
});
const calculateFeesRoute = createRoute({
	method: "post",
	path: "/calculate-fees",
	request: {
		body: {
			content: {
				"application/json": {
					schema: z.object({
						amount: z.number().int().min(5),
						paymentMethodId: z.string().optional(),
					}),
				},
			},
		},
	},
	responses: {
		200: {
			content: {
				"application/json": {
					schema: z.object({
						baseAmount: z.number(),
						stripeFee: z.number(),
						internationalFee: z.number(),
						planFee: z.number(),
						totalFees: z.number(),
						totalAmount: z.number(),
						bonusAmount: z.number().optional(),
						finalCreditAmount: z.number().optional(),
						bonusEnabled: z.boolean(),
						bonusEligible: z.boolean(),
						bonusIneligibilityReason: z.string().optional(),
					}),
				},
			},
			description: "Fee calculation completed successfully",
		},
	},
});

payments.openapi(calculateFeesRoute, async (c) => {
	const user = c.get("user");

	if (!user) {
		throw new HTTPException(401, {
			message: "Unauthorized",
		});
	}

	const {
		amount,
		paymentMethodId,
	}: { amount: number; paymentMethodId?: string } = c.req.valid("json");

	const userOrganization = await db.query.userOrganization.findFirst({
		where: {
			userId: user.id,
		},
		with: {
			organization: true,
			user: true,
		},
	});

	if (!userOrganization || !userOrganization.organization) {
		throw new HTTPException(404, {
			message: "Organization not found",
		});
	}

	let cardCountry: string | undefined;

	if (paymentMethodId) {
		const paymentMethod = await db.query.paymentMethod.findFirst({
			where: {
				id: paymentMethodId,
				organizationId: userOrganization.organization.id,
			},
		});

		if (paymentMethod) {
			try {
				const stripePaymentMethod = await stripe.paymentMethods.retrieve(
					paymentMethod.stripePaymentMethodId,
				);
				cardCountry = stripePaymentMethod.card?.country || undefined;
			} catch {}
		}
	}

	const feeBreakdown = calculateFees({
		amount,
		organizationPlan: userOrganization.organization.plan,
		cardCountry,
	});

	// Calculate bonus for first-time credit purchases
	let bonusAmount = 0;
	let finalCreditAmount = amount;
	let bonusEnabled = false;
	let bonusEligible = false;
	let bonusIneligibilityReason: string | undefined;

	const bonusMultiplier = process.env.FIRST_TIME_CREDIT_BONUS_MULTIPLIER
		? parseFloat(process.env.FIRST_TIME_CREDIT_BONUS_MULTIPLIER)
		: 0;

	bonusEnabled = bonusMultiplier > 1;

	if (bonusEnabled) {
		// Check email verification
		if (!userOrganization.user) {
			bonusIneligibilityReason = "email_not_verified";
		} else {
			// Check if this is the first credit purchase
			const previousPurchases = await db.query.transaction.findFirst({
				where: {
					organizationId: { eq: userOrganization.organization.id },
					type: { eq: "credit_topup" },
					status: { eq: "completed" },
				},
			});

			if (previousPurchases) {
				bonusIneligibilityReason = "already_purchased";
			} else {
				// This is the first credit purchase, apply bonus
				bonusEligible = true;
				const potentialBonus = amount * (bonusMultiplier - 1);
				const maxBonus = 50; // Max $50 bonus

				bonusAmount = Math.min(potentialBonus, maxBonus);
				finalCreditAmount = amount + bonusAmount;
			}
		}
	}

	return c.json({
		...feeBreakdown,
		bonusAmount: bonusAmount > 0 ? bonusAmount : undefined,
		finalCreditAmount: bonusAmount > 0 ? finalCreditAmount : undefined,
		bonusEnabled,
		bonusEligible,
		bonusIneligibilityReason,
	});
});
const createCreditPaymentIntent = createRoute({
	method: "post",
	path: "/create-credit-payment-intent",
	request: {
		body: {
			content: {
				"application/json": {
					schema: z.object({
						amount: z.number().int().min(5),
						promoCode: z.string().optional(),
						organizationId: z.string(),
					}),
				},
			},
		},
	},
	responses: {
		200: {
			content: {
				"application/json": {
					schema: z.object({
						callback: z.string(),
						paymentIntentId: z.string(),
					}),
				},
			},
			description: "Credit payment intent created successfully",
		},
	},
});

payments.openapi(createCreditPaymentIntent, async (c) => {
	const user = c.get("user");
	if (!user) {
		throw new HTTPException(401, {
			message: "Unauthorized",
		});
	}
	const { amount, promoCode, organizationId } = c.req.valid("json");
	const userOrganization = await db.query.userOrganization.findFirst({
		where: {
			userId: user.id,
			organizationId,
		},
		with: {
			organization: true,
			user: true,
		},
	});
	if (!userOrganization || !userOrganization.organization) {
		throw new HTTPException(404, {
			message: "Organization not found",
		});
	}

	let bonusAmount = 0;
	let finalCreditAmount = amount;
	const bonusMultiplier = process.env.FIRST_TIME_CREDIT_BONUS_MULTIPLIER
		? parseFloat(process.env.FIRST_TIME_CREDIT_BONUS_MULTIPLIER)
		: 0;
	if (bonusMultiplier > 1) {
		// Check email verification
		if (!userOrganization.user) {
			// Not eligible for bonus
		} else {
			// Check if this is the first credit purchase
			const previousPurchases = await db.query.transaction.findFirst({
				where: {
					organizationId: { eq: organizationId },
					type: { eq: "credit_topup" },
					status: { eq: "completed" },
				},
			});
			if (!previousPurchases) {
				// This is the first credit purchase, apply bonus
				const potentialBonus = amount * (bonusMultiplier - 1);
				const maxBonus = 50; // Max $50 bonus
				bonusAmount = Math.min(potentialBonus, maxBonus);
				finalCreditAmount = amount + bonusAmount;
			}
		}
	}
	const callbackUrl =
		(process.env.NODE_ENV === "production"
			? process.env.SOLOP_APP_URL
			: "http://localhost:3000") + "/check-payment/credits";

	const feeBreakdown = calculateFees({
		amount,
		organizationPlan: userOrganization.organization.plan,
		cardCountry: "US",
	});
	// Convert USD to Rials (Toman * 10) for gateway
	const amountInRials = feeBreakdown.totalAmount * 1_200_000;
	// Try Zarinpal first, fallback to Zibal
	let resRequestPaymentGateway = null;
	let paymentIntentId: string;
	const paymentMethod =
		process.env.NODE_ENV === "production" ? "gateway" : "zibal";
	// Try Zarinpal
	if (paymentMethod === "gateway") {
		try {
			const zarinpalResponse = await fetch(
				"https://payment.zarinpal.com/pg/v4/payment/request.json",
				{
					method: "POST",
					headers: {
						accept: "application/json",
						"content-type": "application/json",
					},
					body: JSON.stringify({
						merchant_id: process.env.ZARINPAL_MERCHANT || "",
						amount: amountInRials,
						callback_url: callbackUrl,
						description: `Credit purchase for ${amount} USD (including fees)`,
						metadata: {},
					}),
				},
			);
			const zarinpalData = await zarinpalResponse.json();
			if (zarinpalData.data && zarinpalData.data.code === 100) {
				resRequestPaymentGateway = {
					id: zarinpalData.data.authority,
					type: "zarinpal",
					callback: "https://payment.zarinpal.com/pg/StartPay/",
				};
			}
		} catch {
			// Zarinpal failed, try Zibal
		}
	}

	// If Zarinpal failed, try Zibal
	if (!resRequestPaymentGateway || paymentMethod === "zibal") {
		try {
			const zibalResponse = await fetch("https://gateway.zibal.ir/v1/request", {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
				},
				body: JSON.stringify({
					merchant: process.env.ZIBAL_MERCHANT || "zibal",
					amount: amountInRials,
					callbackUrl: callbackUrl,
					description: `Credit purchase for ${amount} USD (including fees)`,
					orderId: "1234567890",
				}),
			});
			const zibalData = await zibalResponse.json();
			if (zibalData.result === 100) {
				resRequestPaymentGateway = {
					id: zibalData.trackId.toString(),
					type: "zibal",
					callback: "https://gateway.zibal.ir/start/",
				};
			}
		} catch {
			throw new HTTPException(500, {
				message: "Failed to create payment gateway request",
			});
		}
	}
	if (!resRequestPaymentGateway) {
		throw new HTTPException(500, {
			message: "Failed to create payment gateway request",
		});
	}
	paymentIntentId = resRequestPaymentGateway.id;
	// Store payment intent in database
	await db.insert(tables.paymentIntents).values({
		amount: JSON.stringify(Math.round(feeBreakdown.totalAmount * 100)),
		description: `Credit purchase for ${amount} USD (including fees)`,
		paymentType: "credit_topup",
		paymentMethod: paymentMethod,
		paymentIntentId: paymentIntentId,
		currency: "USD",
		email: user.email,
		userId: user.id,
		storeId: organizationId,
		metadata: {
			organizationId,
			baseAmount: amount.toString(),
			totalFees: feeBreakdown.totalFees.toString(),
			userEmail: user.email,
			userId: user.id,
			promoCode,
			bonusAmount: bonusAmount.toString(),
			finalCreditAmount: finalCreditAmount.toString(),
			paymentType: "credit_topup",
		},
	});
	return c.json({
		callback: resRequestPaymentGateway.callback + resRequestPaymentGateway.id,
		paymentIntentId,
	});
});
