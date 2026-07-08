# Day 3 – Testing GraphQL with RSpec, VCR & Strong Migrations

---

## RSpec

### Setup
Added rspec-rails, factory_bot_rails, faker in development and test group.
Added vcr, webmock, simplecov in test group only — webmock blocks real HTTP
in tests so it should never run in development.

```bash
rails generate rspec:install
```

### Structure

**describe** — what we are testing, usually a class or method name

**context** — a specific scenario or state, usually starts with "when"

**it** — a single test case, defines one expectation

Together they read like a sentence:
    Users Query
      querying a single user
        returns nil for non-existent user

### let vs let!

- `let` — lazy, only runs when called inside the test
- `let!` — eager, runs before every test even if not called
- Use `let!` when a record must exist in DB before the test runs

### Matchers

- `eq` — assert equality
- `include` — assert value is present
- `be_nil` — assert nil
- `be_empty` — assert empty collection
- `change(Model, :count).by(1)` — assert DB record created or deleted
- predicate methods like `nil?` become `be_nil` in RSpec

### Hooks

- `before(:each)` — runs before every individual test
- `before(:all)` — runs once before all tests in a describe/context block
- Use hooks for setup and cleanup only, avoid heavy logic inside them

### Shared Examples & Shared Context

- Shared examples — define a set of tests once and reuse across multiple specs
- Shared context — share setup code like let blocks and before hooks
- Purpose is to keep specs DRY

### Testing GraphQL endpoints

All GraphQL tests are request specs — `type: :request` — because GraphQL
is a single endpoint `POST /graphql`. We test the full request/response cycle
rather than unit testing individual resolver methods.

### find vs find_by in resolvers

`User.find(id)` raises `ActiveRecord::RecordNotFound` when record does not exist.
Rails catches it and returns an HTML 404 page — breaks JSON parsing in tests.

`User.find_by(id: id)` returns nil — GraphQL returns null in the response cleanly.
Always use `find_by` in resolvers.

### SimpleCov

SimpleCov measures what percentage of application code is exercised by tests.
Filter out auto-generated boilerplate files for accurate coverage numbers.
Achieved 80%+ coverage on the GraphQL layer.

---

## VCR

VCR records real HTTP interactions the first time a test runs and replays
them on every run after that.

- First run — hits the real API, saves response to a cassette file under `spec/cassettes/`
- Every run after — replays from cassette, no real HTTP call made

This makes tests fast, reliable and offline-capable.

### Setup

```ruby
VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.filter_sensitive_data('<API_KEY>') { ENV['API_KEY'] }
end
```

`filter_sensitive_data` replaces API keys in cassette files so they are
safe to commit to GitHub.

### Using in a test

```ruby
describe '.fetch_user', vcr: { cassette_name: 'github/user' } do
  it 'returns user data' do
    result = GitHubService.fetch_user('octocat')
    expect(result).to have_key('login')
  end
end
```

### Recording modes

- `:new_episodes` — use existing cassette, record only new requests
- `:none` — never hit real API, fail if cassette missing
- `:all` — always re-record
- `:once` — record once, never re-record

---

## Strong Migrations

strong_migrations gem automatically catches unsafe migrations in development
before they cause downtime in production.

### How it works

It hooks into ActiveRecord migrations and checks each operation against
known dangerous patterns. If it finds one it raises an error with a clear
message and the safe alternative before the migration runs.

### start_after

```ruby
StrongMigrations.start_after = 20260708062800
```

Ignores all migrations before this timestamp so existing migrations
are not retroactively flagged.

### Unsafe index creation

```ruby
# UNSAFE — locks the table, blocks all writes during index creation
add_index :posts, :title

# SAFE
disable_ddl_transaction!
add_index :posts, :title, algorithm: :concurrently
```

**algorithm: :concurrently** — creates the index in the background while
reads and writes continue. No table lock, no downtime.

**disable_ddl_transaction!** — PostgreSQL does not allow concurrent index
creation inside a transaction. Rails wraps migrations in transactions by
default so we must disable it.

**Risk** — if the migration fails halfway it will not roll back automatically.
The index may need to be manually dropped before retrying.
