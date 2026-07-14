## Overview
Integrated Elasticsearch into the Rails API to enable full-text search,
filtering and aggregations on Post data. Elasticsearch runs as a separate
Docker container alongside Rails and PostgreSQL.

---

## What is Elasticsearch

Elasticsearch is a dedicated search engine optimized for full-text search.

| PostgreSQL | Elasticsearch |
|------------|---------------|
| Source of truth | Searchable copy |
| Slow on text search | Fast on text search |
| SQL LIKE queries | Query DSL |
| No relevance scoring | Returns by relevance |
| No typo tolerance | Handles fuzzy matches |

PostgreSQL stores the data. Elasticsearch makes it searchable.
They stay in sync automatically through model callbacks.

---

## Docker Setup

```yaml
elasticsearch:
  image: docker.elastic.co/elasticsearch/elasticsearch:8.13.0
  environment:
    - discovery.type=single-node
    - xpack.security.enabled=false
    - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    - logger.level=WARN
  ports:
    - "9200:9200"
  healthcheck:
    test: ["CMD-SHELL", "curl -f http://localhost:9200 || exit 1"]
    interval: 10s
    timeout: 5s
    retries: 5
    start_period: 30s
```

Verify Elasticsearch is running:
```bash
curl http://localhost:9200
```

---

## Gems

```ruby
gem 'elasticsearch-model', '~> 8.0'
gem 'elasticsearch-rails', '~> 8.0'
gem 'elasticsearch', '~> 8.0'
```

Version must match Elasticsearch server major version.
Server is 8.13.0 so gems must be 8.x.

---

## Initializer

```ruby
# config/initializers/elasticsearch.rb
Elasticsearch::Model.client = Elasticsearch::Client.new(
  host: ENV.fetch('ELASTICSEARCH_URL', 'http://localhost:9200'),
  log: false
)
```

In Docker — `ELASTICSEARCH_URL=http://elasticsearch:9200`
`elasticsearch` is the Docker Compose service name.

---

## Post Model

```ruby
class Post < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  belongs_to :user
  scope :published, -> { where(published: true) }

  after_commit :clear_search_cache

  private

  def clear_search_cache
    Rails.cache.delete_matched("search:*")
  end
end
```

- `Elasticsearch::Model` — adds `.search` method to Post
- `Elasticsearch::Model::Callbacks` — auto syncs on create, update, destroy

### Index existing data
```bash
docker compose exec web bundle exec rails console
Post.import
```

`=> 0` means zero errors — all posts indexed successfully.

---

## Search Endpoint

`GET /search?q=<query>&published=<true|false>`

---

## Elasticsearch Query DSL

### Basic search
```ruby
Post.search("ruby")
```

### Bool query with filter
```ruby
{
  query: {
    bool: {
      must: {
        match: { title: query }
      },
      filter: {
        term: { published: true }
      }
    }
  }
}
```

### Bool query components

- `must` — full-text search, contributes to relevance score
- `filter` — exact match, does not affect relevance score
- `bool` — combines multiple conditions together

### With aggregations
```ruby
{
  query: { bool: { must: { match: { title: query } } } },
  aggs: {
    published_breakdown: {
      terms: { field: :published }
    }
  }
}
```

Aggregations return analytics alongside results:
```json
"aggregations": {
  "published_breakdown": {
    "true": 3,
    "false": 1
  }
}
```

---

## Sample Requests

```bash
# Basic search
curl "http://localhost:3000/search?q=ruby"

# Filter published only
curl "http://localhost:3000/search?q=rails&published=true"

# Filter unpublished only
curl "http://localhost:3000/search?q=rails&published=false"
```

### Sample Response
```json
{
  "query": "rails",
  "published_filter": null,
  "total": 3,
  "aggregations": {
    "published_breakdown": {
      "true": 2,
      "false": 1
    }
  },
  "results": [
    {
      "id": 1,
      "title": "Learning Ruby on Rails",
      "published": true,
      "user_id": 1
    }
  ]
}
```

---

## Why Separate Search Endpoint

A dedicated `GET /search` endpoint was chosen over modifying the existing
GraphQL posts resolver for these reasons:

- **Single Responsibility** — SearchController owns search, PostsResolver owns CRUD
- **Independent caching** — search cache has different TTL and invalidation strategy
- **Aggregations** — analytics data does not belong inside a posts GraphQL response
- **HTTP caching** — GET requests are cacheable at HTTP level, GraphQL POST is not
- **Rate limiting** — search can be rate limited independently without affecting GraphQL
- **Security** — Elasticsearch is isolated from the GraphQL layer

---

## Key Learnings
- Elasticsearch is a search engine — not a replacement for PostgreSQL
- Model callbacks keep Elasticsearch in sync automatically
- Bool query combines must (full-text) and filter (exact match)
- Must affects relevance score, filter does not
- Aggregations provide analytics alongside search results
- Elasticsearch version must match gem major version
- Service name in Docker Compose is used as hostname
- `Post.import` indexes all existing records into Elasticsearch
