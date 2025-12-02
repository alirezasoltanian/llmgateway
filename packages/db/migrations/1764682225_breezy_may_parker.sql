CREATE TABLE "account" (
	"id" text PRIMARY KEY,
	"account_id" text NOT NULL,
	"provider_id" text NOT NULL,
	"user_id" text NOT NULL,
	"access_token" text,
	"refresh_token" text,
	"id_token" text,
	"access_token_expires_at" timestamp,
	"refresh_token_expires_at" timestamp,
	"scope" text,
	"password" text,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "api_key" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"token" text NOT NULL UNIQUE,
	"description" text NOT NULL,
	"status" text DEFAULT 'active',
	"usage_limit" numeric,
	"usage" numeric DEFAULT '0' NOT NULL,
	"project_id" text NOT NULL,
	"created_by" text NOT NULL
);
--> statement-breakpoint
CREATE TABLE "api_key_iam_rule" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"api_key_id" text NOT NULL,
	"rule_type" text NOT NULL,
	"rule_value" json NOT NULL,
	"status" text DEFAULT 'active' NOT NULL
);
--> statement-breakpoint
CREATE TABLE "chat" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"title" text NOT NULL,
	"user_id" text NOT NULL,
	"model" text,
	"status" text DEFAULT 'active'
);
--> statement-breakpoint
CREATE TABLE "installation" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"uuid" text NOT NULL UNIQUE,
	"type" text NOT NULL
);
--> statement-breakpoint
CREATE TABLE "lock" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"key" text NOT NULL UNIQUE
);
--> statement-breakpoint
CREATE TABLE "log" (
	"id" text PRIMARY KEY,
	"request_id" text NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"organization_id" text NOT NULL,
	"project_id" text NOT NULL,
	"api_key_id" text NOT NULL,
	"duration" integer NOT NULL,
	"time_to_first_token" integer,
	"time_to_first_reasoning_token" integer,
	"requested_model" text NOT NULL,
	"requested_provider" text,
	"used_model" text NOT NULL,
	"used_model_mapping" text,
	"used_provider" text NOT NULL,
	"response_size" integer NOT NULL,
	"content" text,
	"reasoning_content" text,
	"tools" json,
	"tool_choice" json,
	"tool_results" json,
	"finish_reason" text,
	"unified_finish_reason" text,
	"prompt_tokens" numeric,
	"completion_tokens" numeric,
	"total_tokens" numeric,
	"reasoning_tokens" numeric,
	"cached_tokens" numeric,
	"messages" json,
	"temperature" real,
	"max_tokens" integer,
	"top_p" real,
	"frequency_penalty" real,
	"presence_penalty" real,
	"reasoning_effort" text,
	"effort" text,
	"response_format" json,
	"has_error" boolean DEFAULT false,
	"error_details" json,
	"cost" real,
	"input_cost" real,
	"output_cost" real,
	"cached_input_cost" real,
	"request_cost" real,
	"estimated_cost" boolean DEFAULT false,
	"discount" real,
	"pricing_tier" text,
	"canceled" boolean DEFAULT false,
	"streamed" boolean DEFAULT false,
	"cached" boolean DEFAULT false,
	"mode" text NOT NULL,
	"used_mode" text NOT NULL,
	"source" text,
	"custom_headers" json,
	"routing_metadata" json,
	"processed_at" timestamp,
	"raw_request" jsonb,
	"raw_response" jsonb,
	"upstream_request" jsonb,
	"upstream_response" jsonb,
	"trace_id" text,
	"data_retention_cleaned_up" boolean DEFAULT false,
	"data_storage_cost" numeric DEFAULT '0' NOT NULL,
	"params" json
);
--> statement-breakpoint
CREATE TABLE "message" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"chat_id" text NOT NULL,
	"role" text NOT NULL,
	"content" text,
	"images" text,
	"reasoning" text,
	"tools" text,
	"sequence" integer
);
--> statement-breakpoint
CREATE TABLE "model" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"name" text,
	"family" text NOT NULL,
	"free" boolean,
	"output" json,
	"status" text DEFAULT 'active' NOT NULL,
	"logs_count" integer DEFAULT 0 NOT NULL,
	"errors_count" integer DEFAULT 0 NOT NULL,
	"client_errors_count" integer DEFAULT 0 NOT NULL,
	"gateway_errors_count" integer DEFAULT 0 NOT NULL,
	"upstream_errors_count" integer DEFAULT 0 NOT NULL,
	"cached_count" integer DEFAULT 0 NOT NULL,
	"avg_time_to_first_token" real,
	"avg_time_to_first_reasoning_token" real,
	"stats_updated_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "model_history" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"model_id" text NOT NULL,
	"minute_timestamp" timestamp NOT NULL,
	"logs_count" integer DEFAULT 0 NOT NULL,
	"errors_count" integer DEFAULT 0 NOT NULL,
	"client_errors_count" integer DEFAULT 0 NOT NULL,
	"gateway_errors_count" integer DEFAULT 0 NOT NULL,
	"upstream_errors_count" integer DEFAULT 0 NOT NULL,
	"cached_count" integer DEFAULT 0 NOT NULL,
	"total_input_tokens" integer DEFAULT 0 NOT NULL,
	"total_output_tokens" integer DEFAULT 0 NOT NULL,
	"total_tokens" integer DEFAULT 0 NOT NULL,
	"total_reasoning_tokens" integer DEFAULT 0 NOT NULL,
	"total_cached_tokens" integer DEFAULT 0 NOT NULL,
	"total_duration" integer DEFAULT 0 NOT NULL,
	"total_time_to_first_token" integer DEFAULT 0 NOT NULL,
	"total_time_to_first_reasoning_token" integer DEFAULT 0 NOT NULL,
	CONSTRAINT "model_history_model_id_minute_timestamp_unique" UNIQUE("model_id","minute_timestamp")
);
--> statement-breakpoint
CREATE TABLE "model_provider_mapping" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"model_id" text NOT NULL,
	"provider_id" text NOT NULL,
	"model_name" text NOT NULL,
	"input_price" numeric,
	"output_price" numeric,
	"cached_input_price" numeric,
	"image_input_price" numeric,
	"request_price" numeric,
	"context_size" integer,
	"max_output" integer,
	"streaming" boolean DEFAULT false NOT NULL,
	"vision" boolean,
	"reasoning" boolean,
	"reasoning_output" text,
	"tools" boolean,
	"supported_parameters" json,
	"test" text,
	"deprecated_at" timestamp,
	"deactivated_at" timestamp,
	"status" text DEFAULT 'active' NOT NULL,
	"logs_count" integer DEFAULT 0 NOT NULL,
	"errors_count" integer DEFAULT 0 NOT NULL,
	"client_errors_count" integer DEFAULT 0 NOT NULL,
	"gateway_errors_count" integer DEFAULT 0 NOT NULL,
	"upstream_errors_count" integer DEFAULT 0 NOT NULL,
	"cached_count" integer DEFAULT 0 NOT NULL,
	"avg_time_to_first_token" real,
	"avg_time_to_first_reasoning_token" real,
	"stats_updated_at" timestamp,
	CONSTRAINT "model_provider_mapping_model_id_provider_id_unique" UNIQUE("model_id","provider_id")
);
--> statement-breakpoint
CREATE TABLE "model_provider_mapping_history" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"model_id" text NOT NULL,
	"provider_id" text NOT NULL,
	"model_provider_mapping_id" text NOT NULL,
	"minute_timestamp" timestamp NOT NULL,
	"logs_count" integer DEFAULT 0 NOT NULL,
	"errors_count" integer DEFAULT 0 NOT NULL,
	"client_errors_count" integer DEFAULT 0 NOT NULL,
	"gateway_errors_count" integer DEFAULT 0 NOT NULL,
	"upstream_errors_count" integer DEFAULT 0 NOT NULL,
	"cached_count" integer DEFAULT 0 NOT NULL,
	"total_input_tokens" integer DEFAULT 0 NOT NULL,
	"total_output_tokens" integer DEFAULT 0 NOT NULL,
	"total_tokens" integer DEFAULT 0 NOT NULL,
	"total_reasoning_tokens" integer DEFAULT 0 NOT NULL,
	"total_cached_tokens" integer DEFAULT 0 NOT NULL,
	"total_duration" integer DEFAULT 0 NOT NULL,
	"total_time_to_first_token" integer DEFAULT 0 NOT NULL,
	"total_time_to_first_reasoning_token" integer DEFAULT 0 NOT NULL,
	CONSTRAINT "model_provider_mapping_history_model_provider_mapping_id_minute_timestamp_unique" UNIQUE("model_provider_mapping_id","minute_timestamp")
);
--> statement-breakpoint
CREATE TABLE "organization" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"name" text NOT NULL,
	"billing_email" text NOT NULL,
	"billing_company" text,
	"billing_address" text,
	"billing_tax_id" text,
	"billing_notes" text,
	"stripe_customer_id" text UNIQUE,
	"stripe_subscription_id" text UNIQUE,
	"credits" numeric DEFAULT '0' NOT NULL,
	"auto_top_up_enabled" boolean DEFAULT false NOT NULL,
	"auto_top_up_threshold" numeric DEFAULT '10',
	"auto_top_up_amount" numeric DEFAULT '10',
	"plan" text DEFAULT 'free' NOT NULL,
	"plan_expires_at" timestamp,
	"subscription_cancelled" boolean DEFAULT false NOT NULL,
	"trial_start_date" timestamp,
	"trial_end_date" timestamp,
	"is_trial_active" boolean DEFAULT false NOT NULL,
	"retention_level" text DEFAULT 'none' NOT NULL,
	"status" text DEFAULT 'active',
	"referral_earnings" numeric DEFAULT '0' NOT NULL
);
--> statement-breakpoint
CREATE TABLE "organization_action" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"organization_id" text NOT NULL,
	"type" text NOT NULL,
	"amount" numeric NOT NULL,
	"description" text
);
--> statement-breakpoint
CREATE TABLE "passkey" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"name" text,
	"public_key" text NOT NULL,
	"user_id" text NOT NULL,
	"credential_id" text NOT NULL,
	"counter" integer NOT NULL,
	"device_type" text,
	"backed_up" boolean,
	"transports" text
);
--> statement-breakpoint
CREATE TABLE "payment_method" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"stripe_payment_method_id" text NOT NULL,
	"organization_id" text NOT NULL,
	"type" text NOT NULL,
	"is_default" boolean DEFAULT false NOT NULL
);
--> statement-breakpoint
CREATE TABLE "project" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"name" text NOT NULL,
	"organization_id" text NOT NULL,
	"caching_enabled" boolean DEFAULT false NOT NULL,
	"cache_duration_seconds" integer DEFAULT 60 NOT NULL,
	"mode" text DEFAULT 'hybrid' NOT NULL,
	"status" text DEFAULT 'active'
);
--> statement-breakpoint
CREATE TABLE "provider" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"name" text NOT NULL,
	"description" text NOT NULL,
	"streaming" boolean,
	"cancellation" boolean,
	"color" text,
	"website" text,
	"announcement" text,
	"status" text DEFAULT 'active' NOT NULL,
	"logs_count" integer DEFAULT 0 NOT NULL,
	"errors_count" integer DEFAULT 0 NOT NULL,
	"client_errors_count" integer DEFAULT 0 NOT NULL,
	"gateway_errors_count" integer DEFAULT 0 NOT NULL,
	"upstream_errors_count" integer DEFAULT 0 NOT NULL,
	"cached_count" integer DEFAULT 0 NOT NULL,
	"avg_time_to_first_token" real,
	"avg_time_to_first_reasoning_token" real,
	"stats_updated_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "provider_key" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"token" text NOT NULL,
	"provider" text NOT NULL,
	"name" text,
	"base_url" text,
	"options" jsonb,
	"status" text DEFAULT 'active',
	"organization_id" text NOT NULL,
	CONSTRAINT "provider_key_organization_id_name_unique" UNIQUE("organization_id","name")
);
--> statement-breakpoint
CREATE TABLE "referral" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"referrer_organization_id" text NOT NULL,
	"referred_organization_id" text NOT NULL UNIQUE
);
--> statement-breakpoint
CREATE TABLE "session" (
	"id" text PRIMARY KEY,
	"expires_at" timestamp DEFAULT now() NOT NULL,
	"token" text NOT NULL UNIQUE,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"ip_address" text,
	"user_agent" text,
	"user_id" text NOT NULL
);
--> statement-breakpoint
CREATE TABLE "transaction" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"organization_id" text NOT NULL,
	"type" text NOT NULL,
	"amount" numeric,
	"credit_amount" numeric,
	"currency" text DEFAULT 'USD' NOT NULL,
	"status" text DEFAULT 'completed' NOT NULL,
	"stripe_payment_intent_id" text,
	"stripe_invoice_id" text,
	"description" text
);
--> statement-breakpoint
CREATE TABLE "user" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"name" text,
	"email" text NOT NULL UNIQUE,
	"email_verified" boolean DEFAULT false NOT NULL,
	"image" text,
	"onboarding_completed" boolean DEFAULT false NOT NULL
);
--> statement-breakpoint
CREATE TABLE "member" (
	"id" text PRIMARY KEY,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"user_id" text NOT NULL,
	"organization_id" text NOT NULL,
	"role" text DEFAULT 'owner' NOT NULL
);
--> statement-breakpoint
CREATE TABLE "verification" (
	"id" text PRIMARY KEY,
	"identifier" text NOT NULL,
	"value" text NOT NULL,
	"expires_at" timestamp DEFAULT now() NOT NULL,
	"created_at" timestamp,
	"updated_at" timestamp
);
--> statement-breakpoint
CREATE INDEX "account_user_id_idx" ON "account" ("user_id");--> statement-breakpoint
CREATE INDEX "api_key_project_id_idx" ON "api_key" ("project_id");--> statement-breakpoint
CREATE INDEX "api_key_created_by_idx" ON "api_key" ("created_by");--> statement-breakpoint
CREATE INDEX "api_key_iam_rule_api_key_id_idx" ON "api_key_iam_rule" ("api_key_id");--> statement-breakpoint
CREATE INDEX "api_key_iam_rule_rule_type_idx" ON "api_key_iam_rule" ("rule_type");--> statement-breakpoint
CREATE INDEX "api_key_iam_rule_api_key_id_status_idx" ON "api_key_iam_rule" ("api_key_id","status");--> statement-breakpoint
CREATE INDEX "chat_user_id_idx" ON "chat" ("user_id");--> statement-breakpoint
CREATE INDEX "log_project_id_created_at_idx" ON "log" ("project_id","created_at");--> statement-breakpoint
CREATE INDEX "log_created_at_used_model_used_provider_idx" ON "log" ("created_at","used_model","used_provider");--> statement-breakpoint
CREATE INDEX "log_data_retention_pending_idx" ON "log" ("project_id","created_at") WHERE data_retention_cleaned_up = false;--> statement-breakpoint
CREATE INDEX "log_project_id_used_model_idx" ON "log" ("project_id","used_model");--> statement-breakpoint
CREATE INDEX "message_chat_id_idx" ON "message" ("chat_id");--> statement-breakpoint
CREATE INDEX "model_status_idx" ON "model" ("status");--> statement-breakpoint
CREATE INDEX "model_history_minute_timestamp_idx" ON "model_history" ("minute_timestamp");--> statement-breakpoint
CREATE INDEX "model_provider_mapping_status_idx" ON "model_provider_mapping" ("status");--> statement-breakpoint
CREATE INDEX "model_provider_mapping_history_minute_timestamp_idx" ON "model_provider_mapping_history" ("minute_timestamp");--> statement-breakpoint
CREATE INDEX "model_provider_mapping_history_minute_timestamp_provider_id_idx" ON "model_provider_mapping_history" ("minute_timestamp","provider_id");--> statement-breakpoint
CREATE INDEX "model_provider_mapping_history_minute_timestamp_model_id_idx" ON "model_provider_mapping_history" ("minute_timestamp","model_id");--> statement-breakpoint
CREATE INDEX "organization_action_organization_id_idx" ON "organization_action" ("organization_id");--> statement-breakpoint
CREATE INDEX "passkey_user_id_idx" ON "passkey" ("user_id");--> statement-breakpoint
CREATE INDEX "payment_method_organization_id_idx" ON "payment_method" ("organization_id");--> statement-breakpoint
CREATE INDEX "project_organization_id_idx" ON "project" ("organization_id");--> statement-breakpoint
CREATE INDEX "provider_status_idx" ON "provider" ("status");--> statement-breakpoint
CREATE INDEX "provider_key_organization_id_idx" ON "provider_key" ("organization_id");--> statement-breakpoint
CREATE INDEX "referral_referrer_organization_id_idx" ON "referral" ("referrer_organization_id");--> statement-breakpoint
CREATE INDEX "referral_referred_organization_id_idx" ON "referral" ("referred_organization_id");--> statement-breakpoint
CREATE INDEX "session_user_id_idx" ON "session" ("user_id");--> statement-breakpoint
CREATE INDEX "transaction_organization_id_idx" ON "transaction" ("organization_id");--> statement-breakpoint
CREATE INDEX "member_user_id_idx" ON "member" ("user_id");--> statement-breakpoint
CREATE INDEX "member_organization_id_idx" ON "member" ("organization_id");--> statement-breakpoint
ALTER TABLE "account" ADD CONSTRAINT "account_user_id_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "api_key" ADD CONSTRAINT "api_key_project_id_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "project"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "api_key" ADD CONSTRAINT "api_key_created_by_user_id_fkey" FOREIGN KEY ("created_by") REFERENCES "user"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "api_key_iam_rule" ADD CONSTRAINT "api_key_iam_rule_api_key_id_api_key_id_fkey" FOREIGN KEY ("api_key_id") REFERENCES "api_key"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "chat" ADD CONSTRAINT "chat_user_id_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "message" ADD CONSTRAINT "message_chat_id_chat_id_fkey" FOREIGN KEY ("chat_id") REFERENCES "chat"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "model_provider_mapping" ADD CONSTRAINT "model_provider_mapping_model_id_model_id_fkey" FOREIGN KEY ("model_id") REFERENCES "model"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "model_provider_mapping" ADD CONSTRAINT "model_provider_mapping_provider_id_provider_id_fkey" FOREIGN KEY ("provider_id") REFERENCES "provider"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "organization_action" ADD CONSTRAINT "organization_action_organization_id_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organization"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "passkey" ADD CONSTRAINT "passkey_user_id_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "payment_method" ADD CONSTRAINT "payment_method_organization_id_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organization"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "project" ADD CONSTRAINT "project_organization_id_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organization"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "provider_key" ADD CONSTRAINT "provider_key_organization_id_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organization"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "referral" ADD CONSTRAINT "referral_referrer_organization_id_organization_id_fkey" FOREIGN KEY ("referrer_organization_id") REFERENCES "organization"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "referral" ADD CONSTRAINT "referral_referred_organization_id_organization_id_fkey" FOREIGN KEY ("referred_organization_id") REFERENCES "organization"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "session" ADD CONSTRAINT "session_user_id_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "transaction" ADD CONSTRAINT "transaction_organization_id_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organization"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "member" ADD CONSTRAINT "member_user_id_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE CASCADE;--> statement-breakpoint
ALTER TABLE "member" ADD CONSTRAINT "member_organization_id_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organization"("id") ON DELETE CASCADE;