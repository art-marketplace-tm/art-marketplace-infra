# Architecture

## Goals

1. **High quality, well-structured code** that can evolve without rewrites.
2. **Multi-platform frontend** — a single Flutter codebase for iOS, Android, and web.
3. **Three languages** from day one: Armenian, English, Russian.
4. **Future-proof domain model** — single-vendor today, multi-vendor tomorrow with a migration rather than a rewrite.
5. **Pragmatic MVP scope** — no payments yet; the buyer submits a request and the admin confirms offline.

## Stack overview

| Layer | Technology | Why |
|-------|-----------|-----|
| Backend | FastAPI + async SQLAlchemy | Fast, async, great type-safety, large ecosystem for image processing |
| DB | PostgreSQL 16 | Stable; JSONB is a perfect fit for i18n text |
| Cache / Broker | Redis 7 | One process for Celery broker + backend cache |
| Jobs | Celery + Beat | Image processing, email notifications, future periodic tasks |
| Storage | MinIO (dev) → Cloudflare R2 (prod) | S3-compatible; R2 has zero egress cost, ideal for an image-heavy site |
| Auth | JWT (access + refresh) | Stateless, no server-side session store |
| Images | Pillow | Thumbnails, WebP/AVIF, watermarking |
| Frontend | Flutter (bloc + GetIt + GoRouter) | One codebase, all platforms |

## Clean Architecture — backend layout

```
backend/app/
├── domain/               # Pure business types, independent of DB/HTTP
│   ├── entities/         # Dataclasses / value objects
│   ├── repositories/     # Abstract interfaces (Protocol)
│   └── use_cases/        # Application services
├── infrastructure/       # Technical implementations
│   ├── database/
│   │   ├── base.py       # DeclarativeBase, mixins
│   │   ├── session.py    # Async engine + session factory
│   │   └── models/       # ORM models (one file per aggregate)
│   ├── auth/             # Password hashing, JWT helpers, FastAPI deps
│   ├── storage/          # S3/MinIO client, signed URLs
│   ├── email/            # SMTP sender (async)
│   ├── image/            # Pillow processing, watermark
│   └── cache/            # Redis helpers
├── interfaces/           # Transport boundary
│   ├── api/v1/           # Public REST — buyer-facing
│   │   ├── schemas/      # Pydantic request/response models
│   │   ├── auth.py
│   │   └── router.py     # Aggregates feature routers
│   └── admin/            # Admin REST (JWT role=admin|owner)
├── workers/              # Celery app + tasks
├── config.py             # Pydantic Settings (env vars)
└── main.py               # FastAPI factory + lifespan + routing
```

### Dependency direction

`interfaces` → `domain` → `infrastructure` (via abstract repos).
`infrastructure` provides concrete implementations; `domain` never imports from `infrastructure`.

## Domain model

| Entity | Purpose |
|--------|---------|
| `User` | Admin, owner, and registered buyer accounts (single table, role-discriminated) |
| `Category` | Hierarchical product taxonomy with i18n name/description |
| `Product` | Artwork with i18n name/description, price in AMD, dimensions, status, category, seller |
| `ProductImage` | Multiple images per product — original + thumb / medium / large derivatives |
| `Inquiry` | Buyer order/contact request, tied to a product or general |
| `Favorite` | Wishlist entry (user ↔ product) |
| `ProductView` | Analytics: page views per product |
| `Setting` | Key-value runtime config editable from admin |

### i18n strategy

All user-visible text columns are `JSONB` shaped like `{ "hy": "…", "en": "…", "ru": "…" }`. Rationale:

- One row per entity — no JOINs for translations.
- PostgreSQL JSONB supports GIN indexes and efficient partial-update operators.
- Trivial to add a language: new key, no schema change.
- Trade-off: translations can't be queried for completeness as easily; we compensate with validation at the API boundary.

### Multi-vendor migration path

`products.seller_id` is nullable. For MVP, we leave it null (single vendor = the site owner). When we switch to multi-vendor, a migration adds a `stores` table and backfills `seller_id` to the owner's user id. No breaking API changes for buyers.

## Image pipeline

```
admin uploads
    │
    ▼
POST /admin/products/{id}/images  ──────────►  MinIO/R2 (original, private)
                                                      │
                                                      ▼
                                            Celery task (process_image)
                                                      │
                                                      ▼
                                    ┌──────────┬──────────┬──────────┐
                                    ▼          ▼          ▼          ▼
                                 thumb      medium      large     (webp variants)
                              320 px wide  800 px wide  1920 px   (ALL watermarked)
                                    │
                                    ▼
                              Public CDN URL (Cloudflare R2 public bucket)
```

- Originals are **private** (no public URL).
- All public variants carry the brand watermark so screenshots / right-click saves don't yield clean copies.
- `ProductImage.is_processed` flips to `true` once all variants exist.

## Authentication

- **Access token** — short-lived (30 min default), bearer token in `Authorization` header.
- **Refresh token** — long-lived (30 days), opaque to the client. Client posts it to `/auth/refresh` to get a new access token.
- Passwords are bcrypt-hashed via `passlib`.
- `get_current_user` FastAPI dep resolves the token to a `User` row.
- `get_optional_user` returns `None` instead of 401 — use for endpoints that can be called by guests or logged-in users.
- `require_role(*roles)` builds a dependency that enforces specific roles. `require_admin` is the shortcut for `(OWNER, ADMIN)`.

## Inquiry flow

1. Buyer (guest or logged in) submits the form — client POST `/api/v1/inquiries`.
2. Backend validates, rate-limits (5/min per IP), writes to `inquiries` with status `new`.
3. Celery task `send_inquiry_notification` emails the admin.
4. Admin dashboard lists inquiries by status; admin updates status and notes as they progress the sale.
5. Statistics (counts by status, conversion, by-product ranking) come from the same table.

## Deployment plan (future)

- **Dev:** `docker compose up`, everything local.
- **Staging / prod:** VPS (Hetzner / DigitalOcean), same `docker-compose.prod.yml`, Nginx + Let's Encrypt in front. Swap MinIO for Cloudflare R2 by pointing `S3_ENDPOINT_URL` and bucket envs — no code change.

## Open decisions

- Brand name & domain.
- Exact product taxonomy (categories for gilded textures).
- Whether to watermark the thumbnail or only medium/large.
- Newsletter provider (later).
