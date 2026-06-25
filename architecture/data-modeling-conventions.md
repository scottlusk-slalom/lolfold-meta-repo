# Data Modeling Conventions

Canonical type-mapping and safe-default rules for translating any source data model to the project ORM schema.

## Consumers
- `context-curator` agent (stages this doc for data-layer specs)
- `spec-writer` agent (applies type mapping in ACs)
- AOS Loop coder (via `datastore-schema-modeling` playbook)

## Identifier Convention

| Layer | Style | Example |
|-------|-------|---------|
| ORM model | PascalCase | `UserProfile` |
| ORM fields | camelCase | `firstName` |
| Physical DB | snake_case | `first_name` |

Use explicit mapping annotations between ORM and physical names.

## Type Mapping Table (authoritative)

| Source Type | ORM Type | Annotation | Notes |
|-------------|----------|------------|-------|
| int (PK) | Int | `@id @default(autoincrement())` | |
| int (FK) | Int | `@relation(...)` | Real constraint |
| bit / boolean | Boolean | | |
| date | DateTime | `@db.Date` | Date only |
| datetime | DateTime | | Full timestamp |
| currency / decimal | Decimal | `(18,2)` | |
| json / jsonb | Json | `@db.Jsonb` | |
| string (length n) | String | `@db.VarChar(n)` | Only when source specifies length |
| string (unbounded) | String | `@db.Text` | **The String Rule** |
| URL-annotated | String | `@db.Text` | URLs are unbounded |

## The String Rule

> For any column without an explicit source-specified length constraint, use `@db.Text`.
> Never default to `@db.VarChar(255)`.

This is the core invariant of data modeling in this harness. `VarChar(255)` is only acceptable when the source system explicitly declares a 255-character limit.

## Nullability Rules

- Every non-PK field is nullable UNLESS the source explicitly states `NOT NULL`
- When in doubt, make it nullable (safer for migration)

## Foreign Keys

- Every FK gets a real ORM `@relation` with a database-level constraint
- Unnamed FK targets (e.g., "links to some other table") → scalar Int with NO FK
- Never create phantom relations without source evidence

## Safe-Default Policy

When a data modeling question has no clear answer from the source:

1. Apply the conservative default (nullable, Text, etc.)
2. Record in `context/decisions.md` as:
   ```markdown
   ### RESOLVED (default — overridable)
   Applied <default> because <reason>. Override if source clarifies.
   ```
3. Reserve `### UNRESOLVED` only for genuine business forks (where both options have real consequences)

## Schema Ambiguity Checklist

Before writing a data model spec, verify:

1. [ ] All string columns: bounded or unbounded?
2. [ ] All nullable/non-null explicitly confirmed?
3. [ ] All FKs: named target entity or dangling reference?
4. [ ] Currency fields: precision confirmed?
5. [ ] Date vs datetime: time component needed?
6. [ ] JSON fields: schema-on-read or validated?
7. [ ] Soft delete (deletedAt) or hard delete?

## Additive-Migration Rule

- NEVER alter, drop, or recreate a shipped model in the same migration
- New entities land in a new migration file
- Schema changes to existing entities get their own migration

---

*Note: `@db.*` annotation names are ORM-specific — adapt to your ORM (Prisma, TypeORM, Drizzle, etc.). The logical mapping rules are universal.*
