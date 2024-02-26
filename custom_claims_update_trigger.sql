-- The following snippet allows you to automatically update a customer claim in supabase after instert/updates to a table.
-- This is useful if you want to add roles or company mappings as claims, and want to reduce the overhead burden

-- The below example relates to a "company_users" mapping table which relates to a company table and auth.users, defined as such:
CREATE TABLE "public"."company_users" (
  user_id UUID NOT NULL,
  company_id UUID NOT NULL,
  CONSTRAINT "company_users_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "public"."company"("id"),
  CONSTRAINT "company_users_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id")
);


-- TRIGGER DEFINITION
CREATE OR REPLACE FUNCTION "public"."trigger_update_company_id_claim"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    UPDATE auth.users
    SET raw_app_meta_data = 
      raw_app_meta_data || 
        json_build_object('https://<my-claim-namespace>/company_id', new.company_id)::jsonb
    WHERE id = new.user_id;
    RETURN new;
END
$$;
ALTER FUNCTION "public"."trigger_update_company_id_claim"() OWNER TO "postgres";

-- TRIGGER USAGE
CREATE OR REPLACE TRIGGER "set_company_id_user_claims"
AFTER INSERT OR UPDATE ON "public"."company_users"
FOR EACH ROW EXECUTE FUNCTION "public"."trigger_update_company_id_claim"();

-- NOTE you will have to trim top level strings in order to coerce back to a UUID
--TRIM('"' FROM get_my_claim('https://www.nextlevelsalvage.com/company_id')::text)::UUID
