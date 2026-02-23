-- SmileCare AI Dental Platform (Prototype)
-- PostgreSQL 14+ schema with HIPAA-focused controls, encryption hooks, and multi-tenant support.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================================
-- MULTI-TENANCY
-- ============================================================================
CREATE TABLE IF NOT EXISTS tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_code VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(200) NOT NULL,
  region VARCHAR(50) DEFAULT 'us-east-1',
  timezone VARCHAR(50) DEFAULT 'Asia/Kolkata',
  currency_code VARCHAR(10) DEFAULT 'INR',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- USERS & AUTHENTICATION
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  phone VARCHAR(20),
  role VARCHAR(20) NOT NULL CHECK (role IN ('patient', 'provider', 'admin', 'staff')),
  profile_image_url TEXT,
  is_active BOOLEAN DEFAULT true,
  email_verified BOOLEAN DEFAULT false,
  email_verification_token UUID,
  password_reset_token UUID,
  password_reset_expires TIMESTAMP,
  two_factor_enabled BOOLEAN DEFAULT false,
  two_factor_secret VARCHAR(255),
  last_login_at TIMESTAMP,
  last_login_ip VARCHAR(45),
  failed_login_attempts INTEGER DEFAULT 0,
  account_locked_until TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_active ON users(is_active);
CREATE INDEX idx_users_tenant ON users(tenant_id);

CREATE TABLE IF NOT EXISTS patients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date_of_birth DATE NOT NULL,
  gender VARCHAR(20) CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
  ssn_encrypted TEXT,
  address_line1 VARCHAR(255),
  address_line2 VARCHAR(255),
  city VARCHAR(100),
  state VARCHAR(2),
  zip_code VARCHAR(10),
  country VARCHAR(2) DEFAULT 'IN',
  emergency_contact_name VARCHAR(200),
  emergency_contact_phone VARCHAR(20),
  emergency_contact_relationship VARCHAR(50),
  insurance_carrier VARCHAR(200),
  insurance_policy_number VARCHAR(100),
  insurance_group_number VARCHAR(100),
  insurance_subscriber_name VARCHAR(200),
  insurance_subscriber_dob DATE,
  insurance_relationship VARCHAR(50),
  insurance_card_front_url TEXT,
  insurance_card_back_url TEXT,
  medical_history TEXT,
  allergies TEXT,
  current_medications TEXT,
  previous_dental_work TEXT,
  dental_concerns TEXT,
  oral_health_score INTEGER DEFAULT 50 CHECK (oral_health_score >= 0 AND oral_health_score <= 100),
  cavity_risk_score INTEGER DEFAULT 50,
  perio_risk_score INTEGER DEFAULT 50,
  preferred_contact_method VARCHAR(20) DEFAULT 'app' CHECK (preferred_contact_method IN ('email', 'sms', 'phone', 'app')),
  email_notifications BOOLEAN DEFAULT true,
  sms_notifications BOOLEAN DEFAULT true,
  marketing_opt_in BOOLEAN DEFAULT false,
  last_visit_date DATE,
  next_recall_date DATE,
  patient_since DATE DEFAULT CURRENT_DATE,
  referring_source VARCHAR(100),
  lifetime_value DECIMAL(10,2) DEFAULT 0,
  outstanding_balance DECIMAL(10,2) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_patients_user_id ON patients(user_id);
CREATE INDEX idx_patients_last_visit ON patients(last_visit_date);
CREATE INDEX idx_patients_next_recall ON patients(next_recall_date);
CREATE INDEX idx_patients_zip ON patients(zip_code);
CREATE INDEX idx_patients_tenant ON patients(tenant_id);

CREATE TABLE IF NOT EXISTS providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  npi_number VARCHAR(10) UNIQUE,
  license_number VARCHAR(50),
  license_state VARCHAR(2),
  license_expiration DATE,
  dea_number VARCHAR(20),
  credentials VARCHAR(20),
  specialty VARCHAR(100),
  subspecialties TEXT[],
  education JSONB,
  certifications JSONB,
  bio TEXT,
  years_experience INTEGER,
  languages_spoken TEXT[],
  accepting_new_patients BOOLEAN DEFAULT true,
  teledentistry_enabled BOOLEAN DEFAULT false,
  schedule_buffer_minutes INTEGER DEFAULT 10,
  default_appointment_duration INTEGER DEFAULT 60,
  working_hours JSONB,
  blocked_dates JSONB,
  average_rating DECIMAL(3,2) DEFAULT 0.00,
  total_reviews INTEGER DEFAULT 0,
  total_patients_treated INTEGER DEFAULT 0,
  procedures_performed INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  hire_date DATE,
  termination_date DATE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_providers_user_id ON providers(user_id);
CREATE INDEX idx_providers_npi ON providers(npi_number);
CREATE INDEX idx_providers_specialty ON providers(specialty);
CREATE INDEX idx_providers_active ON providers(is_active, accepting_new_patients);
CREATE INDEX idx_providers_tenant ON providers(tenant_id);

CREATE TABLE IF NOT EXISTS practice_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  location_name VARCHAR(200) NOT NULL,
  location_code VARCHAR(20) UNIQUE,
  address_line1 VARCHAR(255) NOT NULL,
  address_line2 VARCHAR(255),
  city VARCHAR(100) NOT NULL,
  state VARCHAR(2) NOT NULL,
  zip_code VARCHAR(10) NOT NULL,
  country VARCHAR(2) DEFAULT 'IN',
  phone VARCHAR(20),
  email VARCHAR(255),
  timezone VARCHAR(50) DEFAULT 'Asia/Kolkata',
  is_main_location BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  accepts_new_patients BOOLEAN DEFAULT true,
  operating_hours JSONB,
  services_offered TEXT[],
  specialties TEXT[],
  parking_info TEXT,
  insurance_accepted TEXT[],
  amenities TEXT[],
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_locations_code ON practice_locations(location_code);
CREATE INDEX idx_locations_active ON practice_locations(is_active);

CREATE TABLE IF NOT EXISTS appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  provider_id UUID REFERENCES providers(id) ON DELETE SET NULL,
  practice_location_id UUID REFERENCES practice_locations(id) ON DELETE SET NULL,
  appointment_date TIMESTAMP NOT NULL,
  duration_minutes INTEGER DEFAULT 60 CHECK (duration_minutes > 0),
  appointment_type VARCHAR(50) NOT NULL CHECK (appointment_type IN ('cleaning', 'exam', 'consultation', 'procedure', 'emergency', 'followup', 'new_patient', 'hygiene', 'orthodontic', 'cosmetic', 'surgical')),
  status VARCHAR(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'confirmed', 'checked_in', 'in_progress', 'completed', 'cancelled', 'no_show', 'rescheduled')),
  previous_status VARCHAR(20),
  chief_complaint TEXT,
  symptoms TEXT[],
  provider_notes TEXT,
  patient_notes TEXT,
  internal_notes TEXT,
  treatment_performed JSONB,
  procedures_completed TEXT[],
  diagnosis_codes TEXT[],
  ai_risk_score INTEGER DEFAULT 0 CHECK (ai_risk_score >= 0 AND ai_risk_score <= 100),
  risk_level VARCHAR(20) CHECK (risk_level IN ('low', 'medium', 'high')),
  risk_factors JSONB,
  recommended_interventions TEXT[],
  confirmation_sent_at TIMESTAMP,
  reminder_sent_at TIMESTAMP,
  reminder_count INTEGER DEFAULT 0,
  confirmed_at TIMESTAMP,
  checked_in_at TIMESTAMP,
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  cancelled_at TIMESTAMP,
  cancellation_reason VARCHAR(255),
  no_show_fee_charged DECIMAL(10,2) DEFAULT 0,
  estimated_cost DECIMAL(10,2),
  actual_cost DECIMAL(10,2),
  insurance_estimate DECIMAL(10,2),
  patient_estimate DECIMAL(10,2),
  copay_collected DECIMAL(10,2) DEFAULT 0,
  wait_time_minutes INTEGER,
  appointment_rating INTEGER CHECK (appointment_rating >= 1 AND appointment_rating <= 5),
  patient_feedback TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_provider ON appointments(provider_id);
CREATE INDEX idx_appointments_date ON appointments(appointment_date);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_appointments_type ON appointments(appointment_type);
CREATE INDEX idx_appointments_provider_date ON appointments(provider_id, appointment_date);
CREATE INDEX idx_appointments_patient_date ON appointments(patient_id, appointment_date);
CREATE INDEX idx_appointments_status_date ON appointments(status, appointment_date);

CREATE TABLE IF NOT EXISTS treatment_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  created_by_provider_id UUID REFERENCES providers(id) ON DELETE SET NULL,
  approved_by_provider_id UUID REFERENCES providers(id) ON DELETE SET NULL,
  plan_number VARCHAR(50) UNIQUE,
  plan_name VARCHAR(200) NOT NULL,
  plan_type VARCHAR(20) NOT NULL CHECK (plan_type IN ('essential', 'recommended', 'comprehensive', 'custom')),
  priority_level VARCHAR(20) DEFAULT 'routine' CHECK (priority_level IN ('urgent', 'high', 'routine', 'elective')),
  description TEXT,
  diagnosis_summary TEXT,
  diagnosis_codes JSONB,
  treatment_goals TEXT,
  expected_outcomes TEXT,
  total_cost DECIMAL(10,2) NOT NULL CHECK (total_cost >= 0),
  insurance_coverage_estimate DECIMAL(10,2) DEFAULT 0,
  patient_responsibility DECIMAL(10,2) NOT NULL CHECK (patient_responsibility >= 0),
  discount_applied DECIMAL(10,2) DEFAULT 0,
  payment_plan_available BOOLEAN DEFAULT true,
  payment_plan_terms JSONB,
  status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'pending_approval', 'presented', 'accepted', 'declined', 'in_progress', 'on_hold', 'completed', 'cancelled', 'expired')),
  expected_duration_months INTEGER,
  expected_visits INTEGER,
  completed_visits INTEGER DEFAULT 0,
  acceptance_signature TEXT,
  accepted_at TIMESTAMP,
  declined_at TIMESTAMP,
  decline_reason TEXT,
  completed_at TIMESTAMP,
  completion_percentage INTEGER DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_treatment_plans_patient ON treatment_plans(patient_id);
CREATE INDEX idx_treatment_plans_status ON treatment_plans(status);
CREATE INDEX idx_treatment_plans_provider ON treatment_plans(created_by_provider_id);
CREATE INDEX idx_treatment_plans_patient_status ON treatment_plans(patient_id, status);

CREATE TABLE IF NOT EXISTS procedures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  treatment_plan_id UUID REFERENCES treatment_plans(id) ON DELETE CASCADE,
  appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  provider_id UUID REFERENCES providers(id) ON DELETE SET NULL,
  cdt_code VARCHAR(10) NOT NULL,
  procedure_name VARCHAR(200) NOT NULL,
  procedure_category VARCHAR(100),
  description TEXT,
  tooth_number VARCHAR(10),
  tooth_surface VARCHAR(20),
  quantity INTEGER DEFAULT 1,
  units INTEGER DEFAULT 1,
  cost_per_unit DECIMAL(10,2) NOT NULL,
  total_cost DECIMAL(10,2) NOT NULL CHECK (total_cost >= 0),
  insurance_coverage DECIMAL(10,2) DEFAULT 0,
  patient_cost DECIMAL(10,2) NOT NULL,
  status VARCHAR(20) DEFAULT 'planned' CHECK (status IN ('planned', 'scheduled', 'pre_authorized', 'in_progress', 'completed', 'cancelled', 'on_hold')),
  sequence_order INTEGER DEFAULT 0,
  estimated_duration_minutes INTEGER,
  notes TEXT,
  clinical_notes TEXT,
  before_images JSONB,
  after_images JSONB,
  xray_images JSONB,
  scheduled_date DATE,
  scheduled_time TIME,
  completed_date TIMESTAMP,
  outcome VARCHAR(20) CHECK (outcome IN ('successful', 'partial', 'failed', 'complicated')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_procedures_treatment_plan ON procedures(treatment_plan_id);
CREATE INDEX idx_procedures_appointment ON procedures(appointment_id);
CREATE INDEX idx_procedures_patient ON procedures(patient_id);
CREATE INDEX idx_procedures_status ON procedures(status);
CREATE INDEX idx_procedures_cdt_code ON procedures(cdt_code);
CREATE INDEX idx_procedures_scheduled_date ON procedures(scheduled_date);

CREATE TABLE IF NOT EXISTS insurance_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  verification_number VARCHAR(50) UNIQUE,
  verification_date TIMESTAMP NOT NULL DEFAULT NOW(),
  verified_for_date DATE,
  carrier_name VARCHAR(200) NOT NULL,
  policy_number VARCHAR(100) NOT NULL,
  group_number VARCHAR(100),
  coverage_status VARCHAR(20) DEFAULT 'active' CHECK (coverage_status IN ('active', 'inactive', 'pending', 'terminated', 'suspended')),
  annual_maximum DECIMAL(10,2),
  annual_used DECIMAL(10,2) DEFAULT 0,
  annual_remaining DECIMAL(10,2),
  verification_method VARCHAR(20) DEFAULT 'automated' CHECK (verification_method IN ('automated', 'manual', 'phone', 'online', 'fax')),
  verified_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  raw_response_data JSONB,
  is_verified BOOLEAN DEFAULT true,
  verification_failed BOOLEAN DEFAULT false,
  failure_reason TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_insurance_patient ON insurance_verifications(patient_id);
CREATE INDEX idx_insurance_status ON insurance_verifications(coverage_status);
CREATE INDEX idx_insurance_carrier ON insurance_verifications(carrier_name);
CREATE INDEX idx_insurance_verification_date ON insurance_verifications(verification_date);

CREATE TABLE IF NOT EXISTS claims (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  claim_number VARCHAR(50) UNIQUE NOT NULL,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  provider_id UUID REFERENCES providers(id) ON DELETE SET NULL,
  appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
  insurance_verification_id UUID REFERENCES insurance_verifications(id) ON DELETE SET NULL,
  claim_type VARCHAR(20) DEFAULT 'primary' CHECK (claim_type IN ('primary', 'secondary', 'tertiary')),
  submission_date DATE NOT NULL,
  service_date_from DATE NOT NULL,
  service_date_to DATE NOT NULL,
  total_charge DECIMAL(10,2) NOT NULL,
  total_submitted DECIMAL(10,2) NOT NULL,
  insurance_payment DECIMAL(10,2) DEFAULT 0,
  patient_payment DECIMAL(10,2) DEFAULT 0,
  balance DECIMAL(10,2) NOT NULL,
  status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'ready', 'submitted', 'acknowledged', 'accepted', 'processing', 'adjudicated', 'paid', 'partially_paid', 'denied', 'rejected', 'appealed', 'appeal_approved', 'appeal_denied', 'closed', 'voided')),
  ai_denial_risk_score INTEGER DEFAULT 0 CHECK (ai_denial_risk_score >= 0 AND ai_denial_risk_score <= 100),
  ai_predicted_issues TEXT[],
  ai_recommendations TEXT[],
  notes TEXT,
  billing_notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_claims_number ON claims(claim_number);
CREATE INDEX idx_claims_patient ON claims(patient_id);
CREATE INDEX idx_claims_status ON claims(status);
CREATE INDEX idx_claims_submission_date ON claims(submission_date);
CREATE INDEX idx_claims_service_date ON claims(service_date_from);

CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  conversation_type VARCHAR(20) CHECK (conversation_type IN ('patient_practice', 'patient_provider', 'internal', 'group')),
  subject VARCHAR(500),
  participants JSONB NOT NULL,
  participant_ids UUID[] NOT NULL,
  created_by_id UUID REFERENCES users(id) ON DELETE SET NULL,
  is_archived BOOLEAN DEFAULT false,
  last_message_at TIMESTAMP,
  last_message_preview TEXT,
  unread_count JSONB,
  priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'closed', 'archived')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_conversations_participants ON conversations USING GIN(participant_ids);
CREATE INDEX idx_conversations_last_message ON conversations(last_message_at);
CREATE INDEX idx_conversations_status ON conversations(status);

CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES users(id) ON DELETE SET NULL,
  sender_type VARCHAR(20) NOT NULL CHECK (sender_type IN ('patient', 'provider', 'staff', 'admin', 'system', 'bot')),
  recipient_ids UUID[],
  recipient_type VARCHAR(20) NOT NULL CHECK (recipient_type IN ('patient', 'provider', 'staff', 'admin', 'broadcast', 'group')),
  message_content TEXT NOT NULL,
  content_encrypted BOOLEAN DEFAULT true,
  attachments JSONB,
  message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'video', 'audio', 'system', 'template')),
  is_read BOOLEAN DEFAULT false,
  is_delivered BOOLEAN DEFAULT false,
  is_archived BOOLEAN DEFAULT false,
  is_ai_generated BOOLEAN DEFAULT false,
  ai_model_used VARCHAR(100),
  sent_at TIMESTAMP NOT NULL DEFAULT NOW(),
  delivered_at TIMESTAMP,
  read_at TIMESTAMP,
  status VARCHAR(20) DEFAULT 'sent' CHECK (status IN ('draft', 'sending', 'sent', 'delivered', 'read', 'failed', 'deleted')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_sent_at ON messages(sent_at);
CREATE INDEX idx_messages_is_read ON messages(is_read);
CREATE INDEX idx_messages_conv_sent ON messages(conversation_id, sent_at DESC);

CREATE TABLE IF NOT EXISTS medical_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
  provider_id UUID REFERENCES providers(id) ON DELETE SET NULL,
  uploaded_by_id UUID REFERENCES users(id) ON DELETE SET NULL,
  record_number VARCHAR(50) UNIQUE,
  record_type VARCHAR(50) NOT NULL CHECK (record_type IN ('xray', 'photo', 'document', 'scan', 'report', 'chart', 'consent_form', 'lab_result', 'referral', 'prescription', 'treatment_note', 'progress_note', 'imaging', 'model')),
  title VARCHAR(200) NOT NULL,
  description TEXT,
  file_url TEXT NOT NULL,
  file_name VARCHAR(255),
  file_size_bytes BIGINT,
  file_type VARCHAR(50),
  is_encrypted BOOLEAN DEFAULT true,
  ai_analysis_status VARCHAR(20) DEFAULT 'not_applicable' CHECK (ai_analysis_status IN ('pending', 'processing', 'completed', 'failed', 'not_applicable', 'skipped')),
  ai_analysis_result JSONB,
  ai_confidence_score DECIMAL(3,2),
  ai_findings JSONB,
  provider_notes TEXT,
  patient_can_view BOOLEAN DEFAULT true,
  access_log JSONB,
  retention_date DATE,
  is_archived BOOLEAN DEFAULT false,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_medical_records_patient ON medical_records(patient_id);
CREATE INDEX idx_medical_records_type ON medical_records(record_type);
CREATE INDEX idx_medical_records_date ON medical_records(created_at);
CREATE INDEX idx_medical_records_ai_status ON medical_records(ai_analysis_status);
CREATE INDEX idx_medical_records_patient_type ON medical_records(patient_id, record_type, created_at DESC);

CREATE TABLE IF NOT EXISTS ai_predictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  prediction_id VARCHAR(100) UNIQUE,
  prediction_type VARCHAR(50) NOT NULL CHECK (prediction_type IN ('no_show', 'treatment_acceptance', 'cavity_risk', 'perio_risk', 'lead_score', 'churn_risk', 'claim_denial', 'patient_satisfaction', 'revenue_forecast', 'appointment_duration')),
  model_name VARCHAR(100) NOT NULL,
  model_version VARCHAR(20),
  related_entity_type VARCHAR(50) NOT NULL,
  related_entity_id UUID NOT NULL,
  patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
  prediction_score INTEGER NOT NULL CHECK (prediction_score >= 0 AND prediction_score <= 100),
  confidence_level DECIMAL(3,2) CHECK (confidence_level >= 0 AND confidence_level <= 1),
  risk_level VARCHAR(20) CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
  risk_factors JSONB,
  recommended_actions JSONB,
  prediction_date TIMESTAMP NOT NULL DEFAULT NOW(),
  actual_outcome VARCHAR(100),
  is_accurate BOOLEAN,
  was_acted_upon BOOLEAN DEFAULT false,
  model_performance_metrics JSONB,
  is_production BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_ai_predictions_type ON ai_predictions(prediction_type);
CREATE INDEX idx_ai_predictions_entity ON ai_predictions(related_entity_id);
CREATE INDEX idx_ai_predictions_patient ON ai_predictions(patient_id);
CREATE INDEX idx_ai_predictions_date ON ai_predictions(prediction_date);
CREATE INDEX idx_ai_predictions_accuracy ON ai_predictions(is_accurate) WHERE is_accurate IS NOT NULL;

CREATE TABLE IF NOT EXISTS marketing_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  campaign_id VARCHAR(100) UNIQUE,
  campaign_name VARCHAR(200) NOT NULL,
  campaign_type VARCHAR(20) NOT NULL CHECK (campaign_type IN ('email', 'sms', 'push', 'mixed', 'social', 'direct_mail', 'phone')),
  campaign_category VARCHAR(100),
  target_audience JSONB,
  message_content TEXT,
  send_method VARCHAR(20) DEFAULT 'scheduled' CHECK (send_method IN ('immediate', 'scheduled', 'triggered', 'drip', 'recurring')),
  scheduled_send_time TIMESTAMP,
  status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'sending', 'sent', 'paused', 'completed', 'cancelled', 'failed')),
  total_recipients INTEGER DEFAULT 0,
  sent_count INTEGER DEFAULT 0,
  delivered_count INTEGER DEFAULT 0,
  opened_count INTEGER DEFAULT 0,
  clicked_count INTEGER DEFAULT 0,
  converted_count INTEGER DEFAULT 0,
  revenue_generated DECIMAL(10,2),
  created_by_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_campaigns_type ON marketing_campaigns(campaign_type);
CREATE INDEX idx_campaigns_status ON marketing_campaigns(status);
CREATE INDEX idx_campaigns_scheduled ON marketing_campaigns(scheduled_send_time);
CREATE INDEX idx_campaigns_created_by ON marketing_campaigns(created_by_id);

CREATE TABLE IF NOT EXISTS campaign_recipients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  campaign_id UUID NOT NULL REFERENCES marketing_campaigns(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  recipient_email VARCHAR(255),
  recipient_phone VARCHAR(20),
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'sending', 'sent', 'delivered', 'opened', 'clicked', 'converted', 'bounced', 'failed', 'unsubscribed', 'complained')),
  sent_at TIMESTAMP,
  delivered_at TIMESTAMP,
  opened_at TIMESTAMP,
  clicked_at TIMESTAMP,
  converted_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_campaign_recipients_campaign ON campaign_recipients(campaign_id);
CREATE INDEX idx_campaign_recipients_patient ON campaign_recipients(patient_id);
CREATE INDEX idx_campaign_recipients_status ON campaign_recipients(status);
CREATE INDEX idx_campaign_recipients_campaign_status ON campaign_recipients(campaign_id, status);

CREATE TABLE IF NOT EXISTS scheduled_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  job_name VARCHAR(200) NOT NULL UNIQUE,
  job_type VARCHAR(50) NOT NULL CHECK (job_type IN ('reminder', 'analytics', 'backup', 'verification', 'report', 'cleanup', 'sync', 'maintenance', 'ai_training', 'notification')),
  schedule_cron VARCHAR(100) NOT NULL,
  timezone VARCHAR(50) DEFAULT 'Asia/Kolkata',
  is_active BOOLEAN DEFAULT true,
  max_retries INTEGER DEFAULT 3,
  last_run_at TIMESTAMP,
  last_run_status VARCHAR(20) CHECK (last_run_status IN ('success', 'failed', 'running', 'timeout', 'cancelled')),
  next_run_at TIMESTAMP,
  total_run_count INTEGER DEFAULT 0,
  success_count INTEGER DEFAULT 0,
  failure_count INTEGER DEFAULT 0,
  alert_on_failure BOOLEAN DEFAULT true,
  created_by_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_scheduled_jobs_name ON scheduled_jobs(job_name);
CREATE INDEX idx_scheduled_jobs_active ON scheduled_jobs(is_active);
CREATE INDEX idx_scheduled_jobs_next_run ON scheduled_jobs(next_run_at) WHERE is_active = true;

CREATE TABLE IF NOT EXISTS job_execution_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  job_id UUID NOT NULL REFERENCES scheduled_jobs(id) ON DELETE CASCADE,
  execution_id VARCHAR(100) UNIQUE,
  job_name VARCHAR(200),
  started_at TIMESTAMP NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMP,
  duration_seconds INTEGER,
  status VARCHAR(20) NOT NULL CHECK (status IN ('running', 'success', 'failed', 'timeout', 'cancelled')),
  output TEXT,
  error_message TEXT,
  records_processed INTEGER,
  retry_attempt INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_job_logs_job_id ON job_execution_logs(job_id);
CREATE INDEX idx_job_logs_status ON job_execution_logs(status);
CREATE INDEX idx_job_logs_started_at ON job_execution_logs(started_at);

CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  log_id VARCHAR(100) UNIQUE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  user_email VARCHAR(255),
  user_name VARCHAR(200),
  user_role VARCHAR(20),
  action VARCHAR(100) NOT NULL,
  action_type VARCHAR(50) CHECK (action_type IN ('create', 'read', 'update', 'delete', 'login', 'logout', 'access', 'export', 'print', 'share', 'approve', 'reject')),
  entity_type VARCHAR(100) NOT NULL,
  entity_id UUID,
  old_values JSONB,
  new_values JSONB,
  changed_fields TEXT[],
  is_phi_access BOOLEAN DEFAULT false,
  phi_fields_accessed TEXT[],
  ip_address VARCHAR(45),
  user_agent TEXT,
  session_id VARCHAR(255),
  request_id VARCHAR(100),
  api_endpoint VARCHAR(255),
  response_status INTEGER,
  severity VARCHAR(20) DEFAULT 'info' CHECK (severity IN ('debug', 'info', 'warning', 'error', 'critical')),
  retention_years INTEGER DEFAULT 7,
  timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp);
CREATE INDEX idx_audit_logs_phi ON audit_logs(is_phi_access) WHERE is_phi_access = true;
CREATE INDEX idx_audit_logs_user_timestamp ON audit_logs(user_id, timestamp);
CREATE INDEX idx_audit_logs_entity_timestamp ON audit_logs(entity_type, entity_id, timestamp);

CREATE TABLE IF NOT EXISTS system_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  setting_key VARCHAR(255) UNIQUE NOT NULL,
  setting_category VARCHAR(100),
  setting_name VARCHAR(200),
  setting_value TEXT,
  value_type VARCHAR(20) CHECK (value_type IN ('string', 'number', 'boolean', 'json', 'array')),
  value_json JSONB,
  default_value TEXT,
  description TEXT,
  is_sensitive BOOLEAN DEFAULT false,
  is_encrypted BOOLEAN DEFAULT false,
  is_editable BOOLEAN DEFAULT true,
  updated_by_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_settings_key ON system_settings(setting_key);
CREATE INDEX idx_settings_category ON system_settings(setting_category);

-- ============================================================================
-- Triggers
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

DO $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename IN (
      'tenants','users','patients','providers','appointments','treatment_plans','procedures','insurance_verifications','claims','conversations','messages','medical_records','ai_predictions','marketing_campaigns','campaign_recipients','scheduled_jobs','system_settings','practice_locations'
    )
    LOOP
      EXECUTE format('DROP TRIGGER IF EXISTS trg_update_%I_updated_at ON %I;', rec.tablename, rec.tablename);
      EXECUTE format('CREATE TRIGGER trg_update_%I_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();', rec.tablename, rec.tablename);
    END LOOP;
END $$;
