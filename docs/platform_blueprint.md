# SmileCare AI (Prototype) – India-ready Blueprint

## Product scope delivered
- Multi-tenant SaaS architecture with HIPAA-focused controls.
- Patient mobile UX flows (registration, booking, records, treatment plans, profile).
- Provider web dashboard, patient chart, diagnostics, and treatment planner modules.
- AI model plan: no-show, treatment acceptance, x-ray analysis integration, lead scoring, denial prediction.
- Automation workflows for reminders, verification, claims, analytics, reactivation, reviews, waitlist, retraining, benefits campaigns, confirmations.
- Integrations: Stripe, Twilio (SMS + Video), SendGrid, DentalXChange, Maps, Calendar, Pearl/Overjet.
- Production security/monitoring/deployment model with staging + production.

## India localization
- Currency displayed in INR (₹).
- Indian names in sample content.
- Address and timezone defaults set for India where UX applies.
- Tooth mark logo for SmileCare AI brand identity.

## API middleware requirements
- JWT access token: 15 minutes.
- Refresh token: 7 days.
- Session timeout: 15-minute inactivity.
- Max 3 concurrent sessions/user.
- Failed login lockout: 5 attempts, 30 minutes.
- API rate limiting: 1000 req/min/user.
- CORS restricted to explicit domains.
- MFA required for provider/admin role.

## Scheduled jobs (recommended default CRON)
- DailyNoShowRiskAssessment: `0 6 * * *`
- InsuranceVerificationBatch: `0 6 * * *`
- ClaimsSubmissionProcessor: event-driven + delayed 24h.
- DailyAnalyticsReport: `0 1 * * *`
- WeeklyReactivationCampaign: `0 9 * * 1`
- ReviewRequestAutomation: event-driven (24h delay).
- WaitingListManager: event-driven on cancellation.
- MonthlyModelRetraining: `0 2 1 * *`
- AnnualBenefitsAlert: `0 10 1 11 *`
- HourlyAppointmentConfirmationTracker: `0 * * * *`

## Monitoring stack
- Error tracking: Sentry.
- APM: New Relic/DataDog.
- Uptime: 99.9% SLA checks.
- Business metrics: bookings/hour, no-show rate, acceptance rate, revenue.

## Launch checklist
- [x] Database schema scaffolded with keys, checks, indexes, triggers.
- [x] Core RLS policy script drafted.
- [x] Patient + provider UI prototype delivered.
- [x] India localization and ₹ pricing in UI.
- [x] Security baseline documented.
