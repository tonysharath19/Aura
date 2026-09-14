-- AURA WELLNESS APP — SUPABASE MASTER SCHEMA
-- Generated from the supplied AURA schema export and the final FK/check queries.
-- Run in a NEW Supabase project's SQL Editor.
-- Supabase-managed auth/storage/realtime/vault objects are NOT recreated.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
CREATE SCHEMA IF NOT EXISTS public;
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- 1. APPLICATION TABLES
CREATE TABLE IF NOT EXISTS public."aura_recommendations" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "user_id" uuid NOT NULL,
    "health_plan_id" uuid,
    "recommendation_type" text NOT NULL,
    "model_version" text,
    "input_snapshot" jsonb NOT NULL DEFAULT '{}'::jsonb,
    "output_snapshot" jsonb NOT NULL DEFAULT '{}'::jsonb,
    "created_at" timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."aura_transactions" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "user_id" uuid NOT NULL,
    "transaction_date" date NOT NULL DEFAULT CURRENT_DATE,
    "source" text NOT NULL,
    "source_id" uuid,
    "points" integer NOT NULL,
    "description" text,
    "created_at" timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."profiles" (
    "id" uuid NOT NULL,
    "full_name" text NOT NULL,
    "role" text NOT NULL DEFAULT 'user'::text,
    "date_of_birth" date,
    "gender" text,
    "height" numeric,
    "weight" numeric,
    "created_at" timestamptz DEFAULT now(),
    "phone" text,
    "email" text,
    "onboarding_complete" boolean NOT NULL DEFAULT false,
    "updated_at" timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."user_badges" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "user_id" uuid NOT NULL,
    "badge_key" text NOT NULL,
    "unlocked_at" timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."user_streaks" (
    "user_id" uuid NOT NULL,
    "workout_current" integer NOT NULL DEFAULT 0,
    "workout_best" integer NOT NULL DEFAULT 0,
    "diet_current" integer NOT NULL DEFAULT 0,
    "diet_best" integer NOT NULL DEFAULT 0,
    "water_current" integer NOT NULL DEFAULT 0,
    "water_best" integer NOT NULL DEFAULT 0,
    "sleep_current" integer NOT NULL DEFAULT 0,
    "sleep_best" integer NOT NULL DEFAULT 0,
    "overall_current" integer NOT NULL DEFAULT 0,
    "overall_best" integer NOT NULL DEFAULT 0,
    "updated_at" timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."body_metrics" (
    "user_id" uuid NOT NULL,
    "height_cm" numeric,
    "weight_kg" numeric,
    "bmi" numeric,
    "bmr" numeric,
    "daily_calories" integer,
    "daily_water_ml" integer,
    "target_weight" numeric,
    "created_at" timestamptz DEFAULT now(),
    "updated_at" timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."exercise_logs" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "user_id" uuid NOT NULL,
    "exercise_name" text NOT NULL,
    "category" text,
    "duration_minutes" integer,
    "calories_burned" integer,
    "distance_km" numeric,
    "steps" integer,
    "avg_heart_rate" integer,
    "notes" text,
    "logged_at" timestamptz DEFAULT now(),
    "created_at" timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."lifestyle_profile" (
    "user_id" uuid NOT NULL,
    "activity_level" text,
    "sleep_hours" numeric,
    "sleep_quality" text,
    "water_intake_ml" integer DEFAULT 0,
    "smoking" text,
    "alcohol" text,
    "medications" text,
    "created_at" timestamptz DEFAULT now(),
    "updated_at" timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."nutrition_logs" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "user_id" uuid NOT NULL,
    "meal_type" text,
    "meal_name" text,
    "calories" integer,
    "protein" numeric,
    "carbs" numeric,
    "fats" numeric,
    "fiber" numeric,
    "sugar" numeric,
    "notes" text,
    "logged_at" timestamptz DEFAULT now(),
    "created_at" timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."sleep_logs" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "user_id" uuid NOT NULL,
    "bedtime" timestamptz,
    "wake_time" timestamptz,
    "hours" numeric,
    "quality" text,
    "notes" text,
    "created_at" timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."user_conditions" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "user_id" uuid NOT NULL,
    "condition_name" text NOT NULL,
    "created_at" timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."user_goals" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "user_id" uuid NOT NULL,
    "goal_name" text NOT NULL,
    "is_primary" boolean DEFAULT false,
    "target_date" date,
    "created_at" timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."user_medications" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "user_id" uuid NOT NULL,
    "medication_name" text NOT NULL,
    "dosage" text,
    "frequency" text,
    "reminder_enabled" boolean DEFAULT false,
    "created_at" timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."user_preferences" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "user_id" uuid NOT NULL,
    "category" text NOT NULL,
    "value" text NOT NULL,
    "created_at" timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."user_units" (
    "user_id" uuid NOT NULL,
    "height_unit" text NOT NULL DEFAULT 'cm'::text,
    "weight_unit" text NOT NULL DEFAULT 'kg'::text,
    "water_unit" text NOT NULL DEFAULT 'ml'::text,
    "created_at" timestamptz DEFAULT now(),
    "updated_at" timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."water_logs" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "user_id" uuid NOT NULL,
    "amount_ml" integer NOT NULL,
    "logged_at" timestamptz DEFAULT now(),
    "created_at" timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."weight_logs" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "user_id" uuid NOT NULL,
    "weight_kg" numeric NOT NULL,
    "notes" text,
    "logged_at" timestamptz DEFAULT now(),
    "created_at" timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."health_plans" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "user_id" uuid NOT NULL,
    "plan_version" integer NOT NULL DEFAULT 1,
    "goal_date" date,
    "profile_snapshot" jsonb NOT NULL DEFAULT '{}'::jsonb,
    "profile_hash" text,
    "status" text NOT NULL DEFAULT 'active'::text,
    "generated_at" timestamptz NOT NULL DEFAULT now(),
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    "goal_id" uuid
);

CREATE TABLE IF NOT EXISTS public."ai_recommendation_logs" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "user_id" uuid NOT NULL,
    "health_plan_id" uuid,
    "recommendation_type" text NOT NULL,
    "model_version" text,
    "input_snapshot" jsonb NOT NULL DEFAULT '{}'::jsonb,
    "output_snapshot" jsonb NOT NULL DEFAULT '{}'::jsonb,
    "created_at" timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."diet_plans" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "user_id" uuid NOT NULL,
    "health_plan_id" uuid NOT NULL,
    "start_date" date NOT NULL,
    "goal_date" date,
    "status" text NOT NULL DEFAULT 'active'::text,
    "created_at" timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."workout_plans" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "user_id" uuid NOT NULL,
    "health_plan_id" uuid NOT NULL,
    "start_date" date NOT NULL,
    "goal_date" date,
    "status" text NOT NULL DEFAULT 'active'::text,
    "created_at" timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."diet_days" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "diet_plan_id" uuid NOT NULL,
    "user_id" uuid NOT NULL,
    "diet_date" date NOT NULL,
    "month_number" integer NOT NULL,
    "week_number" integer NOT NULL,
    "day_number" integer NOT NULL,
    "breakfast" jsonb,
    "mid_morning" jsonb,
    "lunch" jsonb,
    "evening" jsonb,
    "dinner" jsonb,
    "notes" text,
    "completed" boolean NOT NULL DEFAULT false,
    "completed_at" timestamptz,
    "aura_points" integer NOT NULL DEFAULT 0,
    "created_at" timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public."workout_days" (
    "id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "workout_plan_id" uuid NOT NULL,
    "user_id" uuid NOT NULL,
    "workout_date" date NOT NULL,
    "month_number" integer NOT NULL,
    "week_number" integer NOT NULL,
    "day_number" integer NOT NULL,
    "title" text NOT NULL,
    "description" text,
    "workout_type" text,
    "difficulty" text,
    "duration_minutes" integer,
    "exercises" jsonb NOT NULL DEFAULT '[]'::jsonb,
    "completed" boolean NOT NULL DEFAULT false,
    "completed_at" timestamptz,
    "aura_points" integer NOT NULL DEFAULT 0,
    "created_at" timestamptz NOT NULL DEFAULT now()
);

-- 2. PRIMARY / UNIQUE / FOREIGN KEY CONSTRAINTS
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='aura_recommendations_pkey' AND conrelid='public.aura_recommendations'::regclass) THEN ALTER TABLE public."aura_recommendations" ADD CONSTRAINT "aura_recommendations_pkey" PRIMARY KEY ("id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='aura_transactions_pkey' AND conrelid='public.aura_transactions'::regclass) THEN ALTER TABLE public."aura_transactions" ADD CONSTRAINT "aura_transactions_pkey" PRIMARY KEY ("id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='aura_transactions_user_id_fkey' AND conrelid='public.aura_transactions'::regclass) THEN ALTER TABLE public."aura_transactions" ADD CONSTRAINT "aura_transactions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='profiles_email_unique' AND conrelid='public.profiles'::regclass) THEN ALTER TABLE public."profiles" ADD CONSTRAINT "profiles_email_unique" UNIQUE ("email"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='profiles_id_fkey' AND conrelid='public.profiles'::regclass) THEN ALTER TABLE public."profiles" ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='profiles_pkey' AND conrelid='public.profiles'::regclass) THEN ALTER TABLE public."profiles" ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_badges_pkey' AND conrelid='public.user_badges'::regclass) THEN ALTER TABLE public."user_badges" ADD CONSTRAINT "user_badges_pkey" PRIMARY KEY ("id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_badges_user_id_badge_key_key' AND conrelid='public.user_badges'::regclass) THEN ALTER TABLE public."user_badges" ADD CONSTRAINT "user_badges_user_id_badge_key_key" UNIQUE ("user_id", "badge_key"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_badges_user_id_fkey' AND conrelid='public.user_badges'::regclass) THEN ALTER TABLE public."user_badges" ADD CONSTRAINT "user_badges_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_streaks_pkey' AND conrelid='public.user_streaks'::regclass) THEN ALTER TABLE public."user_streaks" ADD CONSTRAINT "user_streaks_pkey" PRIMARY KEY ("user_id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_streaks_user_id_fkey' AND conrelid='public.user_streaks'::regclass) THEN ALTER TABLE public."user_streaks" ADD CONSTRAINT "user_streaks_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='body_metrics_pkey' AND conrelid='public.body_metrics'::regclass) THEN ALTER TABLE public."body_metrics" ADD CONSTRAINT "body_metrics_pkey" PRIMARY KEY ("user_id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='body_metrics_user_id_fkey' AND conrelid='public.body_metrics'::regclass) THEN ALTER TABLE public."body_metrics" ADD CONSTRAINT "body_metrics_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='exercise_logs_pkey' AND conrelid='public.exercise_logs'::regclass) THEN ALTER TABLE public."exercise_logs" ADD CONSTRAINT "exercise_logs_pkey" PRIMARY KEY ("id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='exercise_logs_user_id_fkey' AND conrelid='public.exercise_logs'::regclass) THEN ALTER TABLE public."exercise_logs" ADD CONSTRAINT "exercise_logs_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='lifestyle_profile_pkey' AND conrelid='public.lifestyle_profile'::regclass) THEN ALTER TABLE public."lifestyle_profile" ADD CONSTRAINT "lifestyle_profile_pkey" PRIMARY KEY ("user_id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='lifestyle_profile_user_id_fkey' AND conrelid='public.lifestyle_profile'::regclass) THEN ALTER TABLE public."lifestyle_profile" ADD CONSTRAINT "lifestyle_profile_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='nutrition_logs_pkey' AND conrelid='public.nutrition_logs'::regclass) THEN ALTER TABLE public."nutrition_logs" ADD CONSTRAINT "nutrition_logs_pkey" PRIMARY KEY ("id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='nutrition_logs_user_id_fkey' AND conrelid='public.nutrition_logs'::regclass) THEN ALTER TABLE public."nutrition_logs" ADD CONSTRAINT "nutrition_logs_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='sleep_logs_pkey' AND conrelid='public.sleep_logs'::regclass) THEN ALTER TABLE public."sleep_logs" ADD CONSTRAINT "sleep_logs_pkey" PRIMARY KEY ("id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='sleep_logs_user_id_fkey' AND conrelid='public.sleep_logs'::regclass) THEN ALTER TABLE public."sleep_logs" ADD CONSTRAINT "sleep_logs_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_conditions_pkey' AND conrelid='public.user_conditions'::regclass) THEN ALTER TABLE public."user_conditions" ADD CONSTRAINT "user_conditions_pkey" PRIMARY KEY ("id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_conditions_user_id_condition_name_key' AND conrelid='public.user_conditions'::regclass) THEN ALTER TABLE public."user_conditions" ADD CONSTRAINT "user_conditions_user_id_condition_name_key" UNIQUE ("user_id", "condition_name"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_conditions_user_id_fkey' AND conrelid='public.user_conditions'::regclass) THEN ALTER TABLE public."user_conditions" ADD CONSTRAINT "user_conditions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_goals_pkey' AND conrelid='public.user_goals'::regclass) THEN ALTER TABLE public."user_goals" ADD CONSTRAINT "user_goals_pkey" PRIMARY KEY ("id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_goals_user_id_fkey' AND conrelid='public.user_goals'::regclass) THEN ALTER TABLE public."user_goals" ADD CONSTRAINT "user_goals_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_goals_user_id_goal_name_key' AND conrelid='public.user_goals'::regclass) THEN ALTER TABLE public."user_goals" ADD CONSTRAINT "user_goals_user_id_goal_name_key" UNIQUE ("user_id", "goal_name"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_medications_pkey' AND conrelid='public.user_medications'::regclass) THEN ALTER TABLE public."user_medications" ADD CONSTRAINT "user_medications_pkey" PRIMARY KEY ("id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_medications_user_id_fkey' AND conrelid='public.user_medications'::regclass) THEN ALTER TABLE public."user_medications" ADD CONSTRAINT "user_medications_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_preferences_pkey' AND conrelid='public.user_preferences'::regclass) THEN ALTER TABLE public."user_preferences" ADD CONSTRAINT "user_preferences_pkey" PRIMARY KEY ("id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_preferences_user_id_category_value_key' AND conrelid='public.user_preferences'::regclass) THEN ALTER TABLE public."user_preferences" ADD CONSTRAINT "user_preferences_user_id_category_value_key" UNIQUE ("user_id", "category", "value"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_preferences_user_id_fkey' AND conrelid='public.user_preferences'::regclass) THEN ALTER TABLE public."user_preferences" ADD CONSTRAINT "user_preferences_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_units_pkey' AND conrelid='public.user_units'::regclass) THEN ALTER TABLE public."user_units" ADD CONSTRAINT "user_units_pkey" PRIMARY KEY ("user_id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_units_user_id_fkey' AND conrelid='public.user_units'::regclass) THEN ALTER TABLE public."user_units" ADD CONSTRAINT "user_units_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='water_logs_pkey' AND conrelid='public.water_logs'::regclass) THEN ALTER TABLE public."water_logs" ADD CONSTRAINT "water_logs_pkey" PRIMARY KEY ("id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='water_logs_user_id_fkey' AND conrelid='public.water_logs'::regclass) THEN ALTER TABLE public."water_logs" ADD CONSTRAINT "water_logs_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='weight_logs_pkey' AND conrelid='public.weight_logs'::regclass) THEN ALTER TABLE public."weight_logs" ADD CONSTRAINT "weight_logs_pkey" PRIMARY KEY ("id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='weight_logs_user_id_fkey' AND conrelid='public.weight_logs'::regclass) THEN ALTER TABLE public."weight_logs" ADD CONSTRAINT "weight_logs_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='health_plans_goal_id_fkey' AND conrelid='public.health_plans'::regclass) THEN ALTER TABLE public."health_plans" ADD CONSTRAINT "health_plans_goal_id_fkey" FOREIGN KEY (goal_id) REFERENCES public.user_goals(id) ON DELETE SET NULL; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='health_plans_pkey' AND conrelid='public.health_plans'::regclass) THEN ALTER TABLE public."health_plans" ADD CONSTRAINT "health_plans_pkey" PRIMARY KEY ("id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='health_plans_user_id_fkey' AND conrelid='public.health_plans'::regclass) THEN ALTER TABLE public."health_plans" ADD CONSTRAINT "health_plans_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='ai_recommendation_logs_health_plan_id_fkey' AND conrelid='public.ai_recommendation_logs'::regclass) THEN ALTER TABLE public."ai_recommendation_logs" ADD CONSTRAINT "ai_recommendation_logs_health_plan_id_fkey" FOREIGN KEY (health_plan_id) REFERENCES public.health_plans(id) ON DELETE SET NULL; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='ai_recommendation_logs_pkey' AND conrelid='public.ai_recommendation_logs'::regclass) THEN ALTER TABLE public."ai_recommendation_logs" ADD CONSTRAINT "ai_recommendation_logs_pkey" PRIMARY KEY ("id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='ai_recommendation_logs_user_id_fkey' AND conrelid='public.ai_recommendation_logs'::regclass) THEN ALTER TABLE public."ai_recommendation_logs" ADD CONSTRAINT "ai_recommendation_logs_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='diet_plans_health_plan_id_fkey' AND conrelid='public.diet_plans'::regclass) THEN ALTER TABLE public."diet_plans" ADD CONSTRAINT "diet_plans_health_plan_id_fkey" FOREIGN KEY (health_plan_id) REFERENCES public.health_plans(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='diet_plans_pkey' AND conrelid='public.diet_plans'::regclass) THEN ALTER TABLE public."diet_plans" ADD CONSTRAINT "diet_plans_pkey" PRIMARY KEY ("id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='diet_plans_user_id_fkey' AND conrelid='public.diet_plans'::regclass) THEN ALTER TABLE public."diet_plans" ADD CONSTRAINT "diet_plans_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='workout_plans_health_plan_id_fkey' AND conrelid='public.workout_plans'::regclass) THEN ALTER TABLE public."workout_plans" ADD CONSTRAINT "workout_plans_health_plan_id_fkey" FOREIGN KEY (health_plan_id) REFERENCES public.health_plans(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='workout_plans_pkey' AND conrelid='public.workout_plans'::regclass) THEN ALTER TABLE public."workout_plans" ADD CONSTRAINT "workout_plans_pkey" PRIMARY KEY ("id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='workout_plans_user_id_fkey' AND conrelid='public.workout_plans'::regclass) THEN ALTER TABLE public."workout_plans" ADD CONSTRAINT "workout_plans_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='diet_days_diet_plan_id_diet_date_key' AND conrelid='public.diet_days'::regclass) THEN ALTER TABLE public."diet_days" ADD CONSTRAINT "diet_days_diet_plan_id_diet_date_key" UNIQUE ("diet_plan_id", "diet_date"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='diet_days_diet_plan_id_fkey' AND conrelid='public.diet_days'::regclass) THEN ALTER TABLE public."diet_days" ADD CONSTRAINT "diet_days_diet_plan_id_fkey" FOREIGN KEY (diet_plan_id) REFERENCES public.diet_plans(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='diet_days_pkey' AND conrelid='public.diet_days'::regclass) THEN ALTER TABLE public."diet_days" ADD CONSTRAINT "diet_days_pkey" PRIMARY KEY ("id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='diet_days_user_id_fkey' AND conrelid='public.diet_days'::regclass) THEN ALTER TABLE public."diet_days" ADD CONSTRAINT "diet_days_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='workout_days_pkey' AND conrelid='public.workout_days'::regclass) THEN ALTER TABLE public."workout_days" ADD CONSTRAINT "workout_days_pkey" PRIMARY KEY ("id"); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='workout_days_user_id_fkey' AND conrelid='public.workout_days'::regclass) THEN ALTER TABLE public."workout_days" ADD CONSTRAINT "workout_days_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='workout_days_workout_plan_id_fkey' AND conrelid='public.workout_days'::regclass) THEN ALTER TABLE public."workout_days" ADD CONSTRAINT "workout_days_workout_plan_id_fkey" FOREIGN KEY (workout_plan_id) REFERENCES public.workout_plans(id) ON DELETE CASCADE; END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='workout_days_workout_plan_id_workout_date_key' AND conrelid='public.workout_days'::regclass) THEN ALTER TABLE public."workout_days" ADD CONSTRAINT "workout_days_workout_plan_id_workout_date_key" UNIQUE ("workout_plan_id", "workout_date"); END IF; END $$;

-- 3. CHECK CONSTRAINTS
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='profiles_gender_check' AND conrelid='public.profiles'::regclass) THEN ALTER TABLE public."profiles" ADD CONSTRAINT "profiles_gender_check" CHECK (gender = ANY (ARRAY['male'::text, 'female'::text, 'other'::text])); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='profiles_height_check' AND conrelid='public.profiles'::regclass) THEN ALTER TABLE public."profiles" ADD CONSTRAINT "profiles_height_check" CHECK (height > 0::numeric); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='profiles_role_check' AND conrelid='public.profiles'::regclass) THEN ALTER TABLE public."profiles" ADD CONSTRAINT "profiles_role_check" CHECK (role = ANY (ARRAY['user'::text, 'admin'::text])); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='profiles_weight_check' AND conrelid='public.profiles'::regclass) THEN ALTER TABLE public."profiles" ADD CONSTRAINT "profiles_weight_check" CHECK (weight > 0::numeric); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='body_metrics_height_cm_check' AND conrelid='public.body_metrics'::regclass) THEN ALTER TABLE public."body_metrics" ADD CONSTRAINT "body_metrics_height_cm_check" CHECK (height_cm > 0::numeric); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='body_metrics_weight_kg_check' AND conrelid='public.body_metrics'::regclass) THEN ALTER TABLE public."body_metrics" ADD CONSTRAINT "body_metrics_weight_kg_check" CHECK (weight_kg > 0::numeric); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='exercise_logs_duration_minutes_check' AND conrelid='public.exercise_logs'::regclass) THEN ALTER TABLE public."exercise_logs" ADD CONSTRAINT "exercise_logs_duration_minutes_check" CHECK (duration_minutes > 0); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='lifestyle_profile_activity_level_check' AND conrelid='public.lifestyle_profile'::regclass) THEN ALTER TABLE public."lifestyle_profile" ADD CONSTRAINT "lifestyle_profile_activity_level_check" CHECK (activity_level = ANY (ARRAY['sedentary'::text, 'light'::text, 'moderate'::text, 'active'::text, 'athlete'::text])); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='lifestyle_profile_alcohol_check' AND conrelid='public.lifestyle_profile'::regclass) THEN ALTER TABLE public."lifestyle_profile" ADD CONSTRAINT "lifestyle_profile_alcohol_check" CHECK (alcohol = ANY (ARRAY['never'::text, 'socially'::text, 'weekly'::text, 'frequently'::text])); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='lifestyle_profile_sleep_hours_check' AND conrelid='public.lifestyle_profile'::regclass) THEN ALTER TABLE public."lifestyle_profile" ADD CONSTRAINT "lifestyle_profile_sleep_hours_check" CHECK (sleep_hours >= 0::numeric); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='lifestyle_profile_sleep_quality_check' AND conrelid='public.lifestyle_profile'::regclass) THEN ALTER TABLE public."lifestyle_profile" ADD CONSTRAINT "lifestyle_profile_sleep_quality_check" CHECK (sleep_quality = ANY (ARRAY['poor'::text, 'average'::text, 'good'::text, 'excellent'::text])); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='lifestyle_profile_smoking_check' AND conrelid='public.lifestyle_profile'::regclass) THEN ALTER TABLE public."lifestyle_profile" ADD CONSTRAINT "lifestyle_profile_smoking_check" CHECK (smoking = ANY (ARRAY['never'::text, 'occasionally'::text, 'regularly'::text])); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='nutrition_logs_meal_type_check' AND conrelid='public.nutrition_logs'::regclass) THEN ALTER TABLE public."nutrition_logs" ADD CONSTRAINT "nutrition_logs_meal_type_check" CHECK (meal_type = ANY (ARRAY['breakfast'::text, 'lunch'::text, 'dinner'::text, 'snack'::text])); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='sleep_logs_hours_check' AND conrelid='public.sleep_logs'::regclass) THEN ALTER TABLE public."sleep_logs" ADD CONSTRAINT "sleep_logs_hours_check" CHECK (hours >= 0::numeric); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='sleep_logs_quality_check' AND conrelid='public.sleep_logs'::regclass) THEN ALTER TABLE public."sleep_logs" ADD CONSTRAINT "sleep_logs_quality_check" CHECK (quality = ANY (ARRAY['poor'::text, 'average'::text, 'good'::text, 'excellent'::text])); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_preferences_category_check' AND conrelid='public.user_preferences'::regclass) THEN ALTER TABLE public."user_preferences" ADD CONSTRAINT "user_preferences_category_check" CHECK (category = ANY (ARRAY['diet'::text, 'intolerance'::text, 'cuisine'::text, 'avoid'::text, 'supplement'::text, 'other'::text])); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_units_height_unit_check' AND conrelid='public.user_units'::regclass) THEN ALTER TABLE public."user_units" ADD CONSTRAINT "user_units_height_unit_check" CHECK (height_unit = ANY (ARRAY['cm'::text, 'ft'::text])); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_units_water_unit_check' AND conrelid='public.user_units'::regclass) THEN ALTER TABLE public."user_units" ADD CONSTRAINT "user_units_water_unit_check" CHECK (water_unit = ANY (ARRAY['ml'::text, 'oz'::text])); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='user_units_weight_unit_check' AND conrelid='public.user_units'::regclass) THEN ALTER TABLE public."user_units" ADD CONSTRAINT "user_units_weight_unit_check" CHECK (weight_unit = ANY (ARRAY['kg'::text, 'lb'::text])); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='water_logs_amount_ml_check' AND conrelid='public.water_logs'::regclass) THEN ALTER TABLE public."water_logs" ADD CONSTRAINT "water_logs_amount_ml_check" CHECK (amount_ml > 0); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='weight_logs_weight_kg_check' AND conrelid='public.weight_logs'::regclass) THEN ALTER TABLE public."weight_logs" ADD CONSTRAINT "weight_logs_weight_kg_check" CHECK (weight_kg > 0::numeric); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='health_plans_status_check' AND conrelid='public.health_plans'::regclass) THEN ALTER TABLE public."health_plans" ADD CONSTRAINT "health_plans_status_check" CHECK (status = ANY (ARRAY['active'::text, 'superseded'::text, 'completed'::text])); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='diet_plans_status_check' AND conrelid='public.diet_plans'::regclass) THEN ALTER TABLE public."diet_plans" ADD CONSTRAINT "diet_plans_status_check" CHECK (status = ANY (ARRAY['active'::text, 'superseded'::text, 'completed'::text])); END IF; END $$;
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='workout_plans_status_check' AND conrelid='public.workout_plans'::regclass) THEN ALTER TABLE public."workout_plans" ADD CONSTRAINT "workout_plans_status_check" CHECK (status = ANY (ARRAY['active'::text, 'superseded'::text, 'completed'::text])); END IF; END $$;

-- 4. INDEXES
CREATE INDEX IF NOT EXISTS idx_ai_recommendations_plan ON public.ai_recommendation_logs USING btree (health_plan_id);
CREATE INDEX IF NOT EXISTS idx_ai_recommendations_user ON public.ai_recommendation_logs USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_aura_transactions_source ON public.aura_transactions USING btree (user_id, source);
CREATE INDEX IF NOT EXISTS idx_aura_transactions_user_date ON public.aura_transactions USING btree (user_id, transaction_date);
CREATE INDEX IF NOT EXISTS idx_body_metrics_user ON public.body_metrics USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_diet_days_plan ON public.diet_days USING btree (diet_plan_id);
CREATE INDEX IF NOT EXISTS idx_diet_days_user_date ON public.diet_days USING btree (user_id, diet_date);
CREATE INDEX IF NOT EXISTS idx_diet_plans_health_plan ON public.diet_plans USING btree (health_plan_id);
CREATE INDEX IF NOT EXISTS idx_diet_plans_user ON public.diet_plans USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_exercise_logs_user ON public.exercise_logs USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_health_plans_status ON public.health_plans USING btree (user_id, status);
CREATE INDEX IF NOT EXISTS idx_health_plans_user ON public.health_plans USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_lifestyle_user ON public.lifestyle_profile USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_nutrition_logs_user ON public.nutrition_logs USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles USING btree (email);
CREATE INDEX IF NOT EXISTS idx_sleep_logs_user ON public.sleep_logs USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_user ON public.user_badges USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_conditions_user ON public.user_conditions USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_goals_user ON public.user_goals USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_medications_user ON public.user_medications USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_preferences_category ON public.user_preferences USING btree (category);
CREATE INDEX IF NOT EXISTS idx_preferences_user ON public.user_preferences USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_water_logs_date ON public.water_logs USING btree (logged_at DESC);
CREATE INDEX IF NOT EXISTS idx_water_logs_user ON public.water_logs USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_weight_logs_date ON public.weight_logs USING btree (logged_at DESC);
CREATE INDEX IF NOT EXISTS idx_weight_logs_user ON public.weight_logs USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_workout_days_plan ON public.workout_days USING btree (workout_plan_id);
CREATE INDEX IF NOT EXISTS idx_workout_days_user_date ON public.workout_days USING btree (user_id, workout_date);
CREATE INDEX IF NOT EXISTS idx_workout_plans_health_plan ON public.workout_plans USING btree (health_plan_id);
CREATE INDEX IF NOT EXISTS idx_workout_plans_user ON public.workout_plans USING btree (user_id);

-- 5. PUBLIC FUNCTIONS / RPCs
CREATE OR REPLACE FUNCTION public.admin_assert()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  caller_role text;
begin
  select p->>'role'
  into caller_role
  from (
    select to_jsonb(p) as p
    from public.profiles p
    where p.id = auth.uid()
    limit 1
  ) q;

  if caller_role is distinct from 'admin' then
    raise exception 'Admin access required';
  end if;
end;
$function$;

CREATE OR REPLACE FUNCTION public.admin_delete_user(target_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
begin
  perform public.admin_assert();
  if target_user_id = auth.uid() then raise exception 'Administrator account cannot be deleted'; end if;
  delete from auth.users where id = target_user_id;
  if not found then raise exception 'User not found'; end if;
end;
$function$;

CREATE OR REPLACE FUNCTION public.admin_list_users()
 RETURNS TABLE(id uuid, name text, age text, gender text, email text, goal text, goal_date date, progress numeric, aura_total bigint, current_streak bigint, best_streak bigint, workout_days bigint, nutrition_days bigint, workout_score numeric, nutrition_score numeric, hydration_ml numeric, hydration_score numeric, sleep_avg numeric, sleep_score numeric, badges jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
begin
  perform public.admin_assert();

  return query
  with users as (
    select
      au.id,
      coalesce(
        nullif(to_jsonb(p)->>'full_name',''),
        nullif(to_jsonb(p)->>'name',''),
        nullif(to_jsonb(p)->>'display_name',''),
        'Unnamed User'
      ) as name,
      coalesce(
        nullif(to_jsonb(p)->>'age',''),
        nullif(to_jsonb(bm)->>'age',''),
        '—'
      )::text as age,
      coalesce(nullif(to_jsonb(p)->>'gender',''),'—') as gender,
      au.email::text as email,
      coalesce(
        nullif(to_jsonb(g)->>'primary_goal',''),
        nullif(to_jsonb(g)->>'goal',''),
        nullif(to_jsonb(g)->>'goal_name',''),
        '—'
      ) as goal,
      nullif(coalesce(to_jsonb(g)->>'target_date',to_jsonb(g)->>'goal_date'),'')::date as goal_date
    from auth.users au
    left join public.profiles p on p.id = au.id
    left join public.body_metrics bm on bm.user_id = au.id
    left join lateral (
      select ug.*
      from public.user_goals ug
      where ug.user_id = au.id
      order by coalesce(to_jsonb(ug)->>'target_date','9999-12-31') desc
      limit 1
    ) g on true
    where au.id <> auth.uid()
  ),
  workout_stats as (
    select user_id,
           count(*)::bigint total,
           count(*) filter (where completed = true)::bigint completed
    from public.workout_days group by user_id
  ),
  diet_stats as (
    select user_id,
           count(*)::bigint total,
           count(*) filter (where completed = true)::bigint completed
    from public.diet_days group by user_id
  ),
  water_stats as (
    select user_id,
           coalesce(sum(amount_ml),0)::numeric total_ml,
           count(distinct logged_at::date)::bigint active_days
    from public.water_logs group by user_id
  ),
  sleep_stats as (
    select user_id,
           coalesce(avg(hours) filter (where hours is not null),0)::numeric avg_hours,
           count(distinct wake_time::date) filter (where wake_time is not null)::bigint active_days
    from public.sleep_logs group by user_id
  ),
  aura_stats as (
    select user_id,
           count(distinct lower(coalesce(source,'')) || '|' || coalesce(transaction_date::text,''))::bigint unique_rewards
    from public.aura_transactions group by user_id
  ),
  streak_stats as (
    select user_id,
           greatest(coalesce(overall_current,0),coalesce(workout_current,0),coalesce(diet_current,0),coalesce(water_current,0),coalesce(sleep_current,0))::bigint current_streak,
           greatest(coalesce(overall_best,0),coalesce(workout_best,0),coalesce(diet_best,0),coalesce(water_best,0),coalesce(sleep_best,0))::bigint best_streak
    from public.user_streaks
  ),
  badge_stats as (
    select user_id,
           coalesce(jsonb_agg(jsonb_build_object('badge_key',badge_key,'unlocked_at',unlocked_at) order by unlocked_at desc),'[]'::jsonb) badges
    from public.user_badges group by user_id
  )
  select
    u.id,
    u.name,
    u.age,
    u.gender,
    u.email,
    u.goal,
    u.goal_date,
    round((
      coalesce((ws.completed::numeric / nullif(ws.total,0))*100,0) +
      coalesce((ds.completed::numeric / nullif(ds.total,0))*100,0) +
      least(100,coalesce(w.active_days,0)::numeric / 25 * 100) +
      least(100,coalesce(s.active_days,0)::numeric / 25 * 100)
    ) / 4,1) as progress,
    (coalesce(a.unique_rewards,0) * 25)::bigint as aura_total,
    coalesce(st.current_streak,0)::bigint,
    coalesce(st.best_streak,0)::bigint,
    coalesce(ws.completed,0)::bigint as workout_days,
    coalesce(ds.completed,0)::bigint as nutrition_days,
    coalesce((ws.completed::numeric / nullif(ws.total,0))*100,0) as workout_score,
    coalesce((ds.completed::numeric / nullif(ds.total,0))*100,0) as nutrition_score,
    coalesce(w.total_ml,0)::numeric as hydration_ml,
    least(100,coalesce(w.active_days,0)::numeric / 25 * 100) as hydration_score,
    round(coalesce(s.avg_hours,0),1) as sleep_avg,
    least(100,coalesce(s.active_days,0)::numeric / 25 * 100) as sleep_score,
    coalesce(b.badges,'[]'::jsonb) as badges
  from users u
  left join workout_stats ws on ws.user_id=u.id
  left join diet_stats ds on ds.user_id=u.id
  left join water_stats w on w.user_id=u.id
  left join sleep_stats s on s.user_id=u.id
  left join aura_stats a on a.user_id=u.id
  left join streak_stats st on st.user_id=u.id
  left join badge_stats b on b.user_id=u.id
  order by lower(u.name);
end;
$function$;

CREATE OR REPLACE FUNCTION public.admin_update_user(target_user_id uuid, new_name text, new_age numeric, new_gender text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
declare
  col text;
begin
  perform public.admin_assert();

  if target_user_id = auth.uid() then
    raise exception 'Administrator account cannot be edited from this panel';
  end if;

  if new_name is null or length(trim(new_name)) = 0 then
    raise exception 'Name is required';
  end if;

  if to_regclass('public.profiles') is null then
    raise exception 'profiles table not found';
  end if;

  for col in select c.column_name
             from information_schema.columns c
             where c.table_schema='public' and c.table_name='profiles'
               and c.column_name in ('full_name','name','display_name')
             order by case c.column_name when 'full_name' then 1 when 'name' then 2 else 3 end
             limit 1
  loop
    execute format('update public.profiles set %I = $1 where id = $2', col)
    using trim(new_name), target_user_id;
  end loop;

  if exists(select 1 from information_schema.columns where table_schema='public' and table_name='profiles' and column_name='age') then
    execute 'update public.profiles set age = $1 where id = $2' using new_age, target_user_id;
  end if;

  if exists(select 1 from information_schema.columns where table_schema='public' and table_name='profiles' and column_name='gender') then
    execute 'update public.profiles set gender = $1 where id = $2' using nullif(new_gender,''), target_user_id;
  end if;
end;
$function$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
    insert into public.profiles (
        id,
        full_name,
        role,
        email,
        onboarding_complete,
        created_at,
        updated_at
    )
    values (
        new.id,
        coalesce(new.raw_user_meta_data->>'full_name', ''),
        'user',
        (
            select au.email
            from auth.users au
            where au.id = new.id
        ),
        false,
        now(),
        now()
    )
    on conflict (id)
    do update set
        email = excluded.email,
        updated_at = now();

    return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
    new.updated_at = now();
    return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.update_timestamp()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$

BEGIN

NEW.updated_at=NOW();

RETURN NEW;

END;

$function$;

-- 6. APPLICATION TRIGGERS
DROP TRIGGER IF EXISTS "body_metrics_updated_at" ON public."body_metrics";
CREATE TRIGGER "body_metrics_updated_at" BEFORE UPDATE ON public."body_metrics" FOR EACH ROW EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS "trg_health_plans_updated_at" ON public."health_plans";
CREATE TRIGGER "trg_health_plans_updated_at" BEFORE UPDATE ON public."health_plans" FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS "lifestyle_profile_updated_at" ON public."lifestyle_profile";
CREATE TRIGGER "lifestyle_profile_updated_at" BEFORE UPDATE ON public."lifestyle_profile" FOR EACH ROW EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS "profiles_updated_at" ON public."profiles";
CREATE TRIGGER "profiles_updated_at" BEFORE UPDATE ON public."profiles" FOR EACH ROW EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS "trg_user_streaks_updated_at" ON public."user_streaks";
CREATE TRIGGER "trg_user_streaks_updated_at" BEFORE UPDATE ON public."user_streaks" FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS "user_units_updated_at" ON public."user_units";
CREATE TRIGGER "user_units_updated_at" BEFORE UPDATE ON public."user_units" FOR EACH ROW EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 7. ROW LEVEL SECURITY
ALTER TABLE public."ai_recommendation_logs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."aura_recommendations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."aura_transactions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."body_metrics" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."diet_days" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."diet_plans" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."exercise_logs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."health_plans" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."lifestyle_profile" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."nutrition_logs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."profiles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."sleep_logs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."user_badges" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."user_conditions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."user_goals" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."user_medications" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."user_preferences" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."user_streaks" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."user_units" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."water_logs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."weight_logs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."workout_days" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."workout_plans" ENABLE ROW LEVEL SECURITY;

-- 8. RLS POLICIES
DROP POLICY IF EXISTS "Users can create own AI recommendations" ON public."ai_recommendation_logs";
CREATE POLICY "Users can create own AI recommendations" ON public."ai_recommendation_logs" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can view own AI recommendations" ON public."ai_recommendation_logs";
CREATE POLICY "Users can view own AI recommendations" ON public."ai_recommendation_logs" AS PERMISSIVE FOR SELECT TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can insert own Aura recommendations" ON public."aura_recommendations";
CREATE POLICY "Users can insert own Aura recommendations" ON public."aura_recommendations" AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can read own Aura recommendations" ON public."aura_recommendations";
CREATE POLICY "Users can read own Aura recommendations" ON public."aura_recommendations" AS PERMISSIVE FOR SELECT TO authenticated USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can create own aura transactions" ON public."aura_transactions";
CREATE POLICY "Users can create own aura transactions" ON public."aura_transactions" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can view own aura transactions" ON public."aura_transactions";
CREATE POLICY "Users can view own aura transactions" ON public."aura_transactions" AS PERMISSIVE FOR SELECT TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can insert own body metrics" ON public."body_metrics";
CREATE POLICY "Users can insert own body metrics" ON public."body_metrics" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can update own body metrics" ON public."body_metrics";
CREATE POLICY "Users can update own body metrics" ON public."body_metrics" AS PERMISSIVE FOR UPDATE TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can view own body metrics" ON public."body_metrics";
CREATE POLICY "Users can view own body metrics" ON public."body_metrics" AS PERMISSIVE FOR SELECT TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can create own diet days" ON public."diet_days";
CREATE POLICY "Users can create own diet days" ON public."diet_days" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can update own diet days" ON public."diet_days";
CREATE POLICY "Users can update own diet days" ON public."diet_days" AS PERMISSIVE FOR UPDATE TO public USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can view own diet days" ON public."diet_days";
CREATE POLICY "Users can view own diet days" ON public."diet_days" AS PERMISSIVE FOR SELECT TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can create own diet plans" ON public."diet_plans";
CREATE POLICY "Users can create own diet plans" ON public."diet_plans" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can update own diet plans" ON public."diet_plans";
CREATE POLICY "Users can update own diet plans" ON public."diet_plans" AS PERMISSIVE FOR UPDATE TO public USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can view own diet plans" ON public."diet_plans";
CREATE POLICY "Users can view own diet plans" ON public."diet_plans" AS PERMISSIVE FOR SELECT TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users manage own exercise logs" ON public."exercise_logs";
CREATE POLICY "Users manage own exercise logs" ON public."exercise_logs" AS PERMISSIVE FOR ALL TO public USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can create own health plans" ON public."health_plans";
CREATE POLICY "Users can create own health plans" ON public."health_plans" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can update own health plans" ON public."health_plans";
CREATE POLICY "Users can update own health plans" ON public."health_plans" AS PERMISSIVE FOR UPDATE TO public USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can view own health plans" ON public."health_plans";
CREATE POLICY "Users can view own health plans" ON public."health_plans" AS PERMISSIVE FOR SELECT TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can insert own lifestyle" ON public."lifestyle_profile";
CREATE POLICY "Users can insert own lifestyle" ON public."lifestyle_profile" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can update own lifestyle" ON public."lifestyle_profile";
CREATE POLICY "Users can update own lifestyle" ON public."lifestyle_profile" AS PERMISSIVE FOR UPDATE TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can view own lifestyle" ON public."lifestyle_profile";
CREATE POLICY "Users can view own lifestyle" ON public."lifestyle_profile" AS PERMISSIVE FOR SELECT TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users manage own nutrition logs" ON public."nutrition_logs";
CREATE POLICY "Users manage own nutrition logs" ON public."nutrition_logs" AS PERMISSIVE FOR ALL TO public USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can insert own profile" ON public."profiles";
CREATE POLICY "Users can insert own profile" ON public."profiles" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth.uid() = id));

DROP POLICY IF EXISTS "Users can update own profile" ON public."profiles";
CREATE POLICY "Users can update own profile" ON public."profiles" AS PERMISSIVE FOR UPDATE TO public USING ((auth.uid() = id));

DROP POLICY IF EXISTS "Users can view own profile" ON public."profiles";
CREATE POLICY "Users can view own profile" ON public."profiles" AS PERMISSIVE FOR SELECT TO public USING ((auth.uid() = id));

DROP POLICY IF EXISTS "Users manage own sleep logs" ON public."sleep_logs";
CREATE POLICY "Users manage own sleep logs" ON public."sleep_logs" AS PERMISSIVE FOR ALL TO public USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can create own badges" ON public."user_badges";
CREATE POLICY "Users can create own badges" ON public."user_badges" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can view own badges" ON public."user_badges";
CREATE POLICY "Users can view own badges" ON public."user_badges" AS PERMISSIVE FOR SELECT TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can delete own conditions" ON public."user_conditions";
CREATE POLICY "Users can delete own conditions" ON public."user_conditions" AS PERMISSIVE FOR DELETE TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can insert own conditions" ON public."user_conditions";
CREATE POLICY "Users can insert own conditions" ON public."user_conditions" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can update own conditions" ON public."user_conditions";
CREATE POLICY "Users can update own conditions" ON public."user_conditions" AS PERMISSIVE FOR UPDATE TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can view own conditions" ON public."user_conditions";
CREATE POLICY "Users can view own conditions" ON public."user_conditions" AS PERMISSIVE FOR SELECT TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can delete own goals" ON public."user_goals";
CREATE POLICY "Users can delete own goals" ON public."user_goals" AS PERMISSIVE FOR DELETE TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can insert own goals" ON public."user_goals";
CREATE POLICY "Users can insert own goals" ON public."user_goals" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can update own goals" ON public."user_goals";
CREATE POLICY "Users can update own goals" ON public."user_goals" AS PERMISSIVE FOR UPDATE TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can view own goals" ON public."user_goals";
CREATE POLICY "Users can view own goals" ON public."user_goals" AS PERMISSIVE FOR SELECT TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can delete own medications" ON public."user_medications";
CREATE POLICY "Users can delete own medications" ON public."user_medications" AS PERMISSIVE FOR DELETE TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can insert own medications" ON public."user_medications";
CREATE POLICY "Users can insert own medications" ON public."user_medications" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can update own medications" ON public."user_medications";
CREATE POLICY "Users can update own medications" ON public."user_medications" AS PERMISSIVE FOR UPDATE TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can view own medications" ON public."user_medications";
CREATE POLICY "Users can view own medications" ON public."user_medications" AS PERMISSIVE FOR SELECT TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can delete own preferences" ON public."user_preferences";
CREATE POLICY "Users can delete own preferences" ON public."user_preferences" AS PERMISSIVE FOR DELETE TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can insert own preferences" ON public."user_preferences";
CREATE POLICY "Users can insert own preferences" ON public."user_preferences" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can update own preferences" ON public."user_preferences";
CREATE POLICY "Users can update own preferences" ON public."user_preferences" AS PERMISSIVE FOR UPDATE TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can view own preferences" ON public."user_preferences";
CREATE POLICY "Users can view own preferences" ON public."user_preferences" AS PERMISSIVE FOR SELECT TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can create own streaks" ON public."user_streaks";
CREATE POLICY "Users can create own streaks" ON public."user_streaks" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can update own streaks" ON public."user_streaks";
CREATE POLICY "Users can update own streaks" ON public."user_streaks" AS PERMISSIVE FOR UPDATE TO public USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can view own streaks" ON public."user_streaks";
CREATE POLICY "Users can view own streaks" ON public."user_streaks" AS PERMISSIVE FOR SELECT TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can insert own units" ON public."user_units";
CREATE POLICY "Users can insert own units" ON public."user_units" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can update own units" ON public."user_units";
CREATE POLICY "Users can update own units" ON public."user_units" AS PERMISSIVE FOR UPDATE TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can view own units" ON public."user_units";
CREATE POLICY "Users can view own units" ON public."user_units" AS PERMISSIVE FOR SELECT TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users manage own water logs" ON public."water_logs";
CREATE POLICY "Users manage own water logs" ON public."water_logs" AS PERMISSIVE FOR ALL TO public USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users manage own weight logs" ON public."weight_logs";
CREATE POLICY "Users manage own weight logs" ON public."weight_logs" AS PERMISSIVE FOR ALL TO public USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can create own workout days" ON public."workout_days";
CREATE POLICY "Users can create own workout days" ON public."workout_days" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can delete own workout days" ON public."workout_days";
CREATE POLICY "Users can delete own workout days" ON public."workout_days" AS PERMISSIVE FOR DELETE TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can update own workout days" ON public."workout_days";
CREATE POLICY "Users can update own workout days" ON public."workout_days" AS PERMISSIVE FOR UPDATE TO public USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can view own workout days" ON public."workout_days";
CREATE POLICY "Users can view own workout days" ON public."workout_days" AS PERMISSIVE FOR SELECT TO public USING ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can create own workout plans" ON public."workout_plans";
CREATE POLICY "Users can create own workout plans" ON public."workout_plans" AS PERMISSIVE FOR INSERT TO public WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can update own workout plans" ON public."workout_plans";
CREATE POLICY "Users can update own workout plans" ON public."workout_plans" AS PERMISSIVE FOR UPDATE TO public USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));

DROP POLICY IF EXISTS "Users can view own workout plans" ON public."workout_plans";
CREATE POLICY "Users can view own workout plans" ON public."workout_plans" AS PERMISSIVE FOR SELECT TO public USING ((auth.uid() = user_id));

-- 9. TABLE PRIVILEGES
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."ai_recommendation_logs" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."ai_recommendation_logs" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."ai_recommendation_logs" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."aura_recommendations" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."aura_recommendations" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."aura_recommendations" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."aura_transactions" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."aura_transactions" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."aura_transactions" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."body_metrics" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."body_metrics" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."body_metrics" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."diet_days" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."diet_days" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."diet_days" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."diet_plans" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."diet_plans" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."diet_plans" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."exercise_logs" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."exercise_logs" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."exercise_logs" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."health_plans" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."health_plans" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."health_plans" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."lifestyle_profile" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."lifestyle_profile" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."lifestyle_profile" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."nutrition_logs" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."nutrition_logs" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."nutrition_logs" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."profiles" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."profiles" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."profiles" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."sleep_logs" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."sleep_logs" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."sleep_logs" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_badges" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_badges" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_badges" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_conditions" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_conditions" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_conditions" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_goals" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_goals" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_goals" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_medications" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_medications" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_medications" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_preferences" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_preferences" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_preferences" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_streaks" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_streaks" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_streaks" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_units" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_units" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."user_units" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."water_logs" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."water_logs" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."water_logs" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."weight_logs" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."weight_logs" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."weight_logs" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."workout_days" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."workout_days" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."workout_days" TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."workout_plans" TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."workout_plans" TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE ON TABLE public."workout_plans" TO service_role;

-- 10. RPC PRIVILEGES
REVOKE ALL ON FUNCTION public.admin_assert() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_delete_user(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_list_users() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_update_user(uuid, text, numeric, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_delete_user(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_list_users() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_user(uuid, text, numeric, text) TO authenticated;

COMMIT;
