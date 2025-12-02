ALTER TABLE "user_organization" RENAME TO "member";--> statement-breakpoint
ALTER INDEX "user_organization_user_id_idx" RENAME TO "member_user_id_idx";--> statement-breakpoint
ALTER INDEX "user_organization_organization_id_idx" RENAME TO "member_organization_id_idx";--> statement-breakpoint
ALTER TABLE "chat" ALTER COLUMN "model" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "message" ALTER COLUMN "sequence" DROP NOT NULL;