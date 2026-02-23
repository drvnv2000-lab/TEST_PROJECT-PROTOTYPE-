# SmileCare AI Dental Platform (Prototype)

This repository now contains a **complete prototype foundation** for an AI-powered, multi-tenant dental practice management platform called **SmileCare AI**, localized for India (Indian names, ₹ currency, tooth logo).

## What's included

- **Front-end prototype UI** (`index.html`)
  - Patient mobile screens summary (registration, login, dashboard, booking, records, treatment plans, profile).
  - Provider dashboard mockup with timeline and risk alerts.
  - AI models/workflows and security/deployment sections.

- **Database schema** (`db/smilecare_schema.sql`)
  - PostgreSQL 14+ schema with core tables for:
    - users/patients/providers
    - appointments/treatment plans/procedures
    - messaging/medical records/claims/insurance
    - AI predictions/marketing/scheduled jobs/audit/settings
  - Relationships, constraints, indexes, and automatic `updated_at` triggers.
  - Multi-tenant support via `tenants` and `tenant_id` foreign keys.

- **RBAC + RLS policy draft** (`docs/rbac_and_security.sql`)
  - Role-aware policies for patient/provider/staff/admin.
  - Tenant isolation and PHI-aware access controls.

- **Platform blueprint** (`docs/platform_blueprint.md`)
  - Integrations, scheduled workflows, deployment, monitoring, and checklist.

## Run locally

```bash
python3 -m http.server 8000
# open http://localhost:8000
```

## Notes

This is a prototype architecture + UI baseline and can be extended into a production implementation by adding:

- API/backend services
- mobile app framework implementation (Flutter/React Native)
- full integration credentials + secret management
- automated test suites and CI/CD pipelines
