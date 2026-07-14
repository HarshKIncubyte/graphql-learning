## What is Redis
Redis is an in-memory data store. Data lives in RAM instead of disk making
it extremely fast. Used for caching, queues, session storage and analytics.

## Why Redis alongside PostgreSQL
PostgreSQL is the source of truth — permanent, relational, disk-based.
Redis is the speed layer — temporary, simple, memory-based.
Same search query hitting Elasticsearch every time is wasteful.
Redis caches the result so repeated searches return instantly.

## Caching
First request hits Elasticsearch and stores result in Redis.
Second request returns from Redis without touching Elasticsearch.

**Proof:**
First request:  Time: 1.005s  ← Elasticsearch
Second request: Time: 0.039s  ← Redis cache
25x faster on cache hit.

## TTL — Time To Live
Every cache key has an expiry time. After 10 minutes the cache
expires automatically and the next request hits Elasticsearch again.

**Proof:**
redis-cli ttl "search:ruby:published:"
(integer) 534  ← seconds remaining

## Cache Invalidation
When a Post is created, updated or deleted the search results change.
Stale cache must be cleared. `after_commit` callback clears all search
cache keys automatically whenever a Post changes.

**Proof:**
Before creating post
redis-cli keys "*"  →  "search:ruby:published:"
After creating post
redis-cli keys "*"  →  (empty array)

## Redis Data Structures

### String
Simplest structure. Used for counters and simple values.
`INCR` atomically increments a counter.
Used to track how many times each search term is searched.

### List
Ordered collection that allows duplicates.
`LPUSH` adds to front. `LTRIM` keeps only last N items.
Used to track recent searches in order.

### Set
Unordered collection that automatically deduplicates.
`SADD` ignores duplicates silently.
Used to track unique search terms for analytics.

**Proof:**
```json
{
  "search_count": 2,
  "recent_searches": ["ruby", "docker", "rails", "ruby"],
  "unique_searches": ["ruby", "rails", "docker"]
}
```
recent_searches shows ruby twice — List allows duplicates.
unique_searches shows ruby once — Set deduplicates automatically.

## RedisService
All Redis operations extracted into a dedicated service class.
Single responsibility — SearchController handles HTTP, RedisService handles Redis.
Reusable across the app and independently testable.

## Session Storage
This is an API-only Rails app. Sessions are disabled by design.
JWT tokens are the correct authentication approach for API-only apps.
