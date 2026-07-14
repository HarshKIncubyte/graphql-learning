# Day 5 — Dockerizing Rails Application
> Branch: [day5](https://github.com/HarshKIncubyte/graphql-learning/tree/day5)

## Overview
Containerized the Rails API application using Docker and Docker Compose.
Built a multi-stage Dockerfile, configured Docker Compose for Rails and
PostgreSQL, and created a production-ready setup.

---

## Dockerfile

### What is a Dockerfile
A Dockerfile is a blueprint for building a Docker image. Each instruction
creates a layer. Layers are cached — unchanged layers are reused on
subsequent builds making rebuilds fast.

### Multi-stage Build
```dockerfile
# Stage 1 — build
FROM ruby:3.3.6-slim AS build
RUN apt-get update -qq && apt-get install -y \
  build-essential libpq-dev nodejs curl git
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3
COPY . .

# Stage 2 — runtime
FROM ruby:3.3.6-slim AS runtime
RUN apt-get update -qq && apt-get install -y libpq-dev
WORKDIR /app
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app
EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

### Why multi-stage
Build stage needs compilers and build tools to install gems.
Runtime stage only needs what the app needs to run.
Compilers are not copied to runtime — image is smaller.

| Build | Size |
|-------|------|
| Single-stage | 1.26GB |
| Multi-stage | 603MB |

### Key Dockerfile instructions

- `FROM` — base image to start from
- `RUN` — execute a shell command during build
- `WORKDIR` — set working directory inside container
- `COPY` — copy files from local machine into container
- `EXPOSE` — document which port the app listens on
- `CMD` — default command to run when container starts

### Gemfile caching trick
```dockerfile
COPY Gemfile Gemfile.lock ./   # copy Gemfile first
RUN bundle install              # install gems
COPY . .                        # copy code after
```
Gems only reinstall when Gemfile changes.
Code changes do not invalidate gem cache.

---

## Docker Compose

### What is Docker Compose
Docker Compose orchestrates multiple containers together.
One command starts all services, creates a shared network,
and manages volumes.

### docker-compose.yml
```yaml
services:
  db:
    image: postgres:14.23-alpine
    environment:
      POSTGRES_USER: harsh
      POSTGRES_PASSWORD: 123456
      POSTGRES_DB: graphql_learning_development
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U harsh -d graphql_learning_development"]
      interval: 5s
      timeout: 5s
      retries: 5

  web:
    build: .
    command: bash -c "bundle exec rails db:prepare && bundle exec rails s -b 0.0.0.0"
    volumes:
      - .:/app
    ports:
      - "3000:3000"
    depends_on:
      db:
        condition: service_healthy

volumes:
  postgres_data:
```

### Health checks
`depends_on` alone only waits for container to start — not for the service
inside to be ready. Health checks solve this.

```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U harsh -d graphql_learning_development"]
  interval: 5s
  timeout: 5s
  retries: 5
```

Rails waits until PostgreSQL passes the health check before starting.

### Networking
Docker Compose creates a private network for all services.
Services talk to each other by service name — not localhost.

```yaml
# Wrong — localhost inside container means the container itself
host: localhost

# Correct — db is the service name
host: db
```

### Volumes
Named volumes persist data outside containers.
Data survives container removal and restarts.
postgres_data → database files persist

---

## Environment Variables

### .env file
Secrets stored in `.env` — gitignored, never committed.
DATABASE_URL=postgres://harsh:123456@db/graphql_learning_development
RAILS_ENV=development

### docker-compose.yml
```yaml
env_file:
  - .env
```

---

## Production Setup

### docker-compose.prod.yml
```yaml
services:
  web:
    image: myapp-production
    command: bundle exec puma -C config/puma.rb
    environment:
      RAILS_ENV: production
      RAILS_LOG_TO_STDOUT: "true"
      RAILS_SERVE_STATIC_FILES: "true"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/up"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 40s
    restart: unless-stopped
```

### Differences from development

| | Development | Production |
|---|---|---|
| Code | Mounted as volume | Baked into image |
| Command | rails server | puma |
| Migrations | Auto on startup | Run separately |
| Logs | File | STDOUT |
| Restart | Manual | unless-stopped |

---

## Common Commands

```bash
# Start full stack
docker compose up

# Start in background
docker compose up -d

# Rebuild after Gemfile change
docker compose up --build

# Rails console
docker compose exec web bundle exec rails console

# Run migrations
docker compose exec web rails db:migrate

# View logs
docker compose logs -f web

# Stop containers
docker compose down

# Stop and remove volumes
docker compose down -v
```

---

## Key Learnings
- Docker images are built from layers — each instruction adds one layer
- Layer caching makes rebuilds fast — only changed layers rebuild
- Copy Gemfile before code to cache gems independently
- Multi-stage builds separate build concerns from runtime
- Docker Compose health checks ensure correct startup order
- Services communicate by service name on Docker network
- Named volumes persist data outside container lifecycle
- Production image has no source code volume mount
- Environment variables keep secrets out of codebase
