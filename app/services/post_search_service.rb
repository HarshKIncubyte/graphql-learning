class PostSearchService
  def initialize(query:, published: nil)
    @query = query
    @published = published
  end

  def call
    response = Post.search(build_query)
    results = response.records.to_a

    {
      query: @query,
      published_filter: @published,
      cached: true,
      total: results.count,
      aggregations: {
        published_breakdown: published_breakdown(response.aggregations)
      },
      results: serialize(results)
    }
  end

  private

  def build_query
    query = {
      query: {
        bool: {
          must: {
            match: { title: @query }
          }
        }
      },
      aggs: {
        published_breakdown: {
          terms: { field: :published }
        }
      }
    }

    if @published.present?
      query[:query][:bool][:filter] = {
        term: { published: @published == "true" }
      }
    end

    query
  end

  def published_breakdown(aggregations)
    aggregations
      .published_breakdown
      .buckets
      .each_with_object({}) do |bucket, hash|
        hash[bucket["key_as_string"] || bucket["key"].to_s] = bucket["doc_count"]
      end
  end

  def serialize(results)
    results.map do |post|
      {
        id: post.id,
        title: post.title,
        published: post.published,
        user_id: post.user_id
      }
    end
  end
end
