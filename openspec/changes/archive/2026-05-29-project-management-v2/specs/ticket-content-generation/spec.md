## ADDED Requirements

### Requirement: Scenario generation is seeded with type-specific BDD pattern hints
When generating the `## Scenarios` section of a ticket body, the skill SHALL include 2–3 seed BDD pattern examples appropriate to the `project_type` declared in config as context for the generation step. The seed patterns guide vocabulary and structure; the generated scenarios are still derived from the ticket topic, not copied from the seeds.

Seed patterns by type:

**mobile:**
- `GIVEN user has denied camera permission / WHEN feature requires camera access / THEN app shows permission rationale dialog and graceful fallback`
- `GIVEN device switches from WiFi to 5G mid-operation / WHEN network transfer is in progress / THEN app resumes without data loss via offline queue`
- `GIVEN app is backgrounded during a long operation / WHEN user returns to foreground / THEN session is restored and operation state is preserved`

**web:**
- `GIVEN API call is in-flight / WHEN component renders / THEN skeleton loader is shown, not blank screen`
- `GIVEN user submits form with invalid input / WHEN validation runs / THEN inline error messages appear and submit button stays disabled`
- `GIVEN user is on mobile viewport (375px) / WHEN page loads / THEN layout adapts to single-column with accessible touch targets`

**api:**
- `GIVEN authenticated user with scope=read:orders / WHEN GET /orders?status=pending / THEN 200 with paginated list and X-Total-Count header`
- `GIVEN request without Authorization header / WHEN POST /payments / THEN 401 Unauthorized with WWW-Authenticate challenge`
- `GIVEN 51st request arrives within a 60-second window (limit = 50/min) / WHEN rate limiter evaluates / THEN 429 Too Many Requests with Retry-After header`

**microservices:**
- `GIVEN orders-svc calls inventory-svc.reserveStock() / WHEN inventory-svc returns 503 three times / THEN circuit breaker trips and order remains in PENDING state`
- `GIVEN payment-svc publishes order.paid event / WHEN notifications-svc is temporarily down / THEN event persists in DLQ and notification is delivered after recovery`
- `GIVEN payment succeeds but order creation fails / WHEN saga compensates / THEN payment is refunded and no order record persists`

**generic:** (no seed patterns — current behaviour unchanged)

#### Scenario: Mobile project ticket scenarios use touch and permission vocabulary
- **WHEN** a ticket is created on a mobile project with `project_type: mobile`
- **THEN** the generated `## Scenarios` section contains at least one scenario using mobile-relevant language (permission, offline, background, or gesture vocabulary)

#### Scenario: API project ticket scenarios use HTTP verb and status code vocabulary
- **WHEN** a ticket is created on an API project with `project_type: api`
- **THEN** the generated `## Scenarios` section contains at least one scenario referencing HTTP methods, status codes, or auth patterns

#### Scenario: Generic project scenarios are unchanged from v1
- **WHEN** a ticket is created on a project with `project_type: generic` or no project_type
- **THEN** scenario generation behaviour is identical to v1 (no seed patterns applied)

#### Scenario: Seed patterns guide vocabulary, not content
- **WHEN** a mobile project ticket is created for "user profile photo upload"
- **THEN** the generated scenarios address the specific topic (photo upload) using mobile vocabulary, not verbatim copies of the seed patterns
