-- SmileCare AI RBAC + RLS prototype policies

-- Expected JWT claims:
-- app.user_id, app.role, app.tenant_id, app.patient_id, app.provider_id

CREATE OR REPLACE FUNCTION app_current_role() RETURNS TEXT AS $$
BEGIN
  RETURN current_setting('app.role', true);
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION app_current_user_id() RETURNS UUID AS $$
BEGIN
  RETURN NULLIF(current_setting('app.user_id', true), '')::UUID;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION app_current_tenant_id() RETURNS UUID AS $$
BEGIN
  RETURN NULLIF(current_setting('app.tenant_id', true), '')::UUID;
END;
$$ LANGUAGE plpgsql STABLE;

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE treatment_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE procedures ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE insurance_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY users_tenant_isolation ON users
  USING (tenant_id = app_current_tenant_id());

CREATE POLICY users_self_or_admin ON users
  FOR SELECT USING (
    id = app_current_user_id() OR app_current_role() = 'admin'
  );

CREATE POLICY patients_self_provider_staff_admin ON patients
  USING (
    tenant_id = app_current_tenant_id() AND (
      user_id = app_current_user_id() OR
      app_current_role() IN ('provider', 'staff', 'admin')
    )
  );

CREATE POLICY appointments_access ON appointments
  USING (
    tenant_id = app_current_tenant_id() AND (
      app_current_role() = 'admin' OR
      app_current_role() = 'staff' OR
      (app_current_role() = 'provider' AND provider_id = NULLIF(current_setting('app.provider_id', true), '')::UUID) OR
      (app_current_role() = 'patient' AND patient_id = NULLIF(current_setting('app.patient_id', true), '')::UUID)
    )
  );

CREATE POLICY treatment_plans_access ON treatment_plans
  USING (
    tenant_id = app_current_tenant_id() AND (
      app_current_role() IN ('admin', 'staff', 'provider') OR
      (app_current_role() = 'patient' AND patient_id = NULLIF(current_setting('app.patient_id', true), '')::UUID)
    )
  );

CREATE POLICY procedures_access ON procedures
  USING (
    tenant_id = app_current_tenant_id() AND (
      app_current_role() IN ('admin', 'staff', 'provider') OR
      (app_current_role() = 'patient' AND patient_id = NULLIF(current_setting('app.patient_id', true), '')::UUID)
    )
  );

CREATE POLICY medical_records_patient_view ON medical_records
  FOR SELECT USING (
    tenant_id = app_current_tenant_id() AND (
      app_current_role() IN ('admin', 'provider') OR
      (app_current_role() = 'staff' AND file_url IS NULL) OR
      (app_current_role() = 'patient'
        AND patient_id = NULLIF(current_setting('app.patient_id', true), '')::UUID
        AND patient_can_view = true)
    )
  );

CREATE POLICY medical_records_write ON medical_records
  FOR INSERT WITH CHECK (
    tenant_id = app_current_tenant_id() AND app_current_role() IN ('admin', 'provider', 'staff', 'patient')
  );

CREATE POLICY claims_access ON claims
  USING (
    tenant_id = app_current_tenant_id() AND (
      app_current_role() IN ('admin', 'staff', 'provider') OR
      (app_current_role() = 'patient' AND patient_id = NULLIF(current_setting('app.patient_id', true), '')::UUID)
    )
  );

CREATE POLICY messages_access ON messages
  USING (
    tenant_id = app_current_tenant_id() AND (
      app_current_role() = 'admin' OR
      sender_id = app_current_user_id() OR
      recipient_ids @> ARRAY[app_current_user_id()]::UUID[]
    )
  );

CREATE POLICY conversations_access ON conversations
  USING (
    tenant_id = app_current_tenant_id() AND (
      app_current_role() = 'admin' OR
      participant_ids @> ARRAY[app_current_user_id()]::UUID[]
    )
  );

CREATE POLICY audit_logs_admin_only ON audit_logs
  USING (tenant_id = app_current_tenant_id() AND app_current_role() = 'admin');
