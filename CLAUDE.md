# CLAUDE.md — AI Assistant Guide for munin-dokku

## Overview

Rack-based static file server deployed on Dokku. Serves Munin monitoring HTML output
from the `www/` directory with SSL enforcement, caching headers, and gzip compression.

---

## Technology Stack

| Layer | Technology |
|---|---|
| Ruby version | 3.4.9 (see `.ruby-version`) |
| Web framework | Rack (via `config.ru`) |
| Production server | iodine (via Procfile) |
| Development server | WEBrick (via `rackup`) |
| Static serving | rackstaticapp (serves `www/`) |
| Container base | `ruby:3.4.9-slim` (Debian) |

---

## Repository Layout

```
munin-dokku/
├── .github/workflows/
│   ├── docker.yml        # CI: build image + HTTP smoke test
│   └── dokku.yaml        # CD: deploy to Dokku on push to master/dokku
├── config.ru             # Rack middleware stack and static app
├── Dockerfile            # Multi-stage Docker build
├── Gemfile               # Ruby gem dependencies
├── Gemfile.lock          # Locked gem versions
├── Procfile              # Dokku process definition (iodine)
├── .ruby-version         # Pinned Ruby version
├── .dockerignore         # Docker build context exclusions
└── www/                  # Static files served (Munin output; not in repo)
```

---

## Application Logic

`config.ru` sets up the Rack middleware stack:

- `Rack::SslEnforcer` — redirects HTTP→HTTPS and sets HSTS header (production only)
- `Rack::ConditionalGet` — enables HTTP 304 Not Modified responses
- `Rack::ETag` — adds ETag headers for client-side caching
- `Rack::ContentLength` — sets Content-Length automatically
- `Rack::Deflater` — gzip compression for responses
- `RackStaticApp::Application` — serves files from the `www/` directory

---

## Development Workflow

### Setup

```bash
bundle install
```

### Run locally

```bash
bundle exec rackup          # WEBrick on port 9292 (development)
```

Verify: `curl -o /dev/null -w "%{http_code}" http://localhost:9292/` should return `200` or `404`.

### Docker

```bash
docker build -t munin-dokku .
docker run -p 9292:9292 munin-dokku bundle exec rackup -o 0.0.0.0
```

The Dockerfile uses a **multi-stage build**:
1. **Builder stage**: installs build tools, installs gems into `vendor/`
2. **Runtime stage**: copies `vendor/` from builder; no build tools in final image

---

## CI/CD Pipelines

### GitHub Actions

**`docker.yml`** — runs on every push and pull request:
- Builds Docker image
- Starts container on port 9292
- Polls until ready (HTTP 200 or 404), then asserts a non-5xx response

**`dokku.yaml`** — runs on pushes to `master` or `dokku`/`dokku**` branches:
- Deploys to Dokku server: `ssh://dokku@c.iphoting.cc:3022/munin`
- Uses `SSH_PRIVATE_KEY` secret
- Force-push enabled; in-progress runs cancelled by concurrency control

---

## Dependency Management

Gem versions are locked in `Gemfile.lock`. To update:

```bash
bundle update
```

Then commit both `Gemfile.lock` and (if changed) `.ruby-version`.

When bumping the Ruby version:
1. Update `.ruby-version`
2. Update `RUBY VERSION` in `Gemfile.lock`
3. Update `FROM ruby:X.Y.Z-slim` in `Dockerfile` (both stages)
4. Remove any platform entries in `Gemfile.lock` that no longer apply

---

## Code Conventions

### Commit Messages

Follow **Conventional Commits** style:

```
<type>: <short description>

Types: feat, fix, chore, ci, docs, refactor
Examples: chore(deps): bump rack to 3.x, ci: add smoke test timeout
```

---

## Deployment

| Target | Trigger | Method |
|---|---|---|
| Dokku (primary) | Push to `master`/`dokku` branch | `dokku.yaml` GitHub Action force-push |

---

## Important Notes

- The `www/` directory is **not in the repository** — it is populated externally with Munin
  HTML output (e.g. via a volume mount or rsync from the Munin host).
- The Dockerfile creates an empty `www/` directory so the container starts without error.
- The `Procfile` runs iodine in production: `web: bundle exec iodine -p ${PORT}`.
  Dokku sets `$PORT` automatically.
- Ruby version must match `.ruby-version` exactly. Use `rbenv` or `rvm` locally.
- The smoke test CI accepts HTTP 200 or 404 (not 5xx) since `www/` is empty in CI.
