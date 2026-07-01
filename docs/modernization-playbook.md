---
type: playbook
status: active
---

# Modernization Playbook

Single lifecycle reference for modernizing any legacy application.

## Pre-Flight Checklist

### Identity & Auth
[POPULATE PER ENGAGEMENT]
- Auth provider integration approach
- Session/token migration strategy

### Secrets
[POPULATE PER ENGAGEMENT]
- Secrets manager integration
- Rotation policy

### External Partner API Contracts (frozen)
[POPULATE PER ENGAGEMENT]
- Partner APIs that cannot change
- Contract validation approach

### Read-Only Source DBs
[POPULATE PER ENGAGEMENT]
- Legacy databases accessed read-only during migration
- Connection pooling strategy

### GP Template Readiness
- [ ] Golden Path templates available for target stack
- [ ] `org/golden-path/requirements.md` populated
- [ ] `org/golden-path/gp-rules.json` has engagement-specific rules

### Network/Security Constraints
[POPULATE PER ENGAGEMENT]

### Partner Coordination
[POPULATE PER ENGAGEMENT]

## Execution Phases

### Phase 0: Platform Setup
**Commands**: `/register-repo`, `/scaffold-repo`, `/init-repo`
**Gate**: All repos loop-ready (`/repo-status` shows READY)
**Watch for**: Template drift, missing GP rules

### Phase 1: Proof Slice
**Commands**: `/generate-spec`, `/approve`, `/multi-repo-loop`
**Gate**: One slice fully executed end-to-end, PR merged
**Watch for**: Mock violations, integration gaps, retry exhaustion

### Phase 2: External-Facing APIs
**Commands**: `/decompose-phase`, `/dispatch-batch`
**Gate**: All public API endpoints migrated with parity tests
**Watch for**: Contract drift, auth edge cases, rate limiting differences

### Phase 3: Core Domain
**Commands**: `/decompose-phase`, `/dispatch-batch`
**Gate**: Business logic migrated with full test coverage
**Watch for**: State machine differences, business rule gaps, data transformation issues

### Phase 4: Background Workers
**Commands**: `/decompose-phase`, `/dispatch-batch`
**Gate**: All async processors migrated, queue parity verified
**Watch for**: Idempotency gaps, retry semantics, dead letter handling

### Phase 5: Full UI
**Commands**: `/decompose-phase`, `/dispatch-batch`
**Gate**: UI feature parity, visual regression within tolerance
**Watch for**: Component library differences, state management migration

### Phase 6: Data Migration & Cutover
**Commands**: Custom scripts + `/dispatch-batch`
**Gate**: Data migrated, dual-write verified, cutover rehearsed
**Watch for**: Data integrity, timezone handling, encoding differences

### Phase 7: Decommission
**Commands**: `/promote-repo archived`, `/finalize-spec`
**Gate**: Legacy system traffic at zero, monitoring confirms no calls
**Watch for**: Hidden integrations, scheduled jobs, partner dependencies

## Running Gaps

| # | Gap | Owner | Blocker | Status |
|---|-----|-------|---------|--------|
| 1 | [POPULATE PER ENGAGEMENT] | | | |

## Lessons Learned

### [App Name] — [Date]
[POPULATE PER ENGAGEMENT]
- What worked:
- What didn't:
- Process changes:
