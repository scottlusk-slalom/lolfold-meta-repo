---
name: datastore-schema-modeling
applies_when:
  spec_tags_any: [datastore, schema, data-model]
  spec_section: "## Type Mapping"
  files_touched_any: [schema.prisma, "*.entity.ts", "models/*.py"]
skip_when:
  spec_tags_any: [api-only, frontend-only]
requires:
  - database
  - orm-cli   # adapt to your datastore
injects_into: execute
---

# Datastore Schema Modeling

ORM schema translation instructions for data-layer specs.

## Type Mapping Table

| Source Type | ORM Type | Annotation | Notes |
|-------------|----------|------------|-------|
| int (PK) | Int | `@id @default(autoincrement())` | |
| int (FK) | Int | `@relation(...)` | Real constraint |
| bit / boolean | Boolean | | |
| date | DateTime | `@db.Date` | Date only |
| datetime | DateTime | | Full timestamp |
| currency | Decimal | `(18,2)` | |
| json | Json | `@db.Jsonb` | |
| string (length n) | String | `@db.VarChar(n)` | Source specifies length |
| string (unbounded) | String | `@db.Text` | **THE STRING RULE** |
| URL | String | `@db.Text` | URLs are unbounded |

## The String Rule

> For any column without an explicit source-specified length constraint, use `@db.Text`.
> **Never** default to `@db.VarChar(255)`.

### Audit Command
After implementation, verify no violations:
```bash
grep -rn "VarChar" schema.prisma | grep -v "// source-specified"  # adapt to your datastore
```
Every `VarChar(N)` must have a comment citing the source length constraint.

## Identifiers
- ORM models: PascalCase
- ORM fields: camelCase
- Physical columns: snake_case with explicit `@map`

## Nullability
- Every non-PK field nullable UNLESS source states NOT NULL
- When uncertain: nullable (safer for migration)

## Foreign Keys
- Every FK → real `@relation` with database constraint
- Unnamed targets → scalar Int, no FK
- Never create phantom relations

## Additive-Migration Rule
- Never alter/drop/recreate a shipped model in the same migration
- New entities → new migration file
- Schema changes to existing entities → separate migration

## Validation Gate

After schema changes:
1. Start local datastore
2. Validate schema: `npx prisma validate`  # adapt to your datastore
3. Generate migration: `npx prisma migrate dev`  # adapt to your datastore
4. Generate client: `npx prisma generate`  # adapt to your datastore
5. Build: verify no type errors
6. Audit: run `grep` for unbounded VarChars
