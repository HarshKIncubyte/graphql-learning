# Day 10 — OOP Principles & TDD Reflection with Sandi Metz

## What I Learned

### All the Little Things (RailsConf 2014)

- **Small objects, small methods** — every method should be so small you can read it in one glance. If you need to scroll, it's too big.
- **Shape of the code** — squint at a method. Lots of indentation and nested ifs means it's doing too many things. Good code is flat.
- **Color of the code** — too many colors in one method means too many concerns mixed together.
- **Shameless green** — write the simplest code first to get to green. Don't be clever on the first pass. Refactor after.
- **Make the change easy, then make the easy change** — clean the structure first, then add the feature. Never do both at once.
- **Duplication is cheaper than the wrong abstraction** — don't extract too early. A bad abstraction is harder to undo than duplicated code.
- **The cost of conditionals** — every `if` is a fork. Replace conditionals with small objects that each handle one case.
- **Open/Closed in practice** — new case = new object. Existing code untouched.

### Get a Whiff of This (RailsConf 2016)

- **Name the smell first** — once you name it, the fix is obvious.
- **Smells come in clusters** — find one, you'll find two or three more nearby.
- **The cure is almost always extraction** — long method → extract method. Large class → extract class.
- **Refactoring is not rewriting** — small, safe, incremental steps. Tests green at every step.
- **The squint test is free** — no tool needed. Just squint. If the shape looks wrong, it is wrong.

**5 smell categories:**

| Group | Examples |
|---|---|
| Bloaters | Long Method, Large Class, Data Clumps |
| OO Abusers | Switch statements, Refused Bequest |
| Change Preventers | Divergent Change, Shotgun Surgery |
| Dispensables | Dead code, duplicate code, speculative code |
| Couplers | Feature Envy, Inappropriate Intimacy |

## What I Built

### Code Smells Found

- `SearchController#perform_search` — **Long Method**. Building the ES query, executing it, and formatting the response all in one place.
- `SearchController#track_search` — **Inappropriate Intimacy**. Controller knowing 3 internal Redis steps for one logical action.
- `GithubService#fetch_user` — no timeout or status check on the HTTP call.

### Extracted PostSearchService

`perform_search` was 40 lines doing 3 jobs. Extracted to a service object with one public `#call` method. Each private method does one thing.

```ruby
# Before
def perform_search(query, published)
  search_definition = { query: { bool: { ... } }, aggs: { ... } }
  # build, execute, serialize all in one place — 40 lines
end

# After
def perform_search(query, published)
  PostSearchService.new(query: query, published: published).call
end
```

### Added RedisService.track

```ruby
# Before
RedisService.increment_search_count(query)
RedisService.add_to_recent_searches(query)
RedisService.add_to_unique_searches(query)

# After
RedisService.track(query)
```

### Other Refactors

- Extracted **SearchCacheInvalidator** — Post model no longer handles cache logic. Delegates to a dedicated service.
- Fixed **GithubService** — added `read_timeout: 5` and response status checks.
- Fixed Rubocop offenses — string literals and trailing whitespace across the codebase.

## Reflection

The biggest shift today was learning to name the smell before touching the code. Once you say "this is a Long Method" the fix is obvious. Without the name you just stare at code.

Sandi's rule — make the change easy, then make the easy change — is something I'll carry into every feature going forward.

Duplication is cheaper than the wrong abstraction. Wait until the pattern is clear before extracting.
