class SearchController < ApplicationController
  CACHE_EXPIRY = 10.minutes

  def search
    query = params[:q]
    published = params[:published]

    if query.blank?
      render json: { error: "Please provide a search query" }, status: :bad_request
      return
    end

    track_search(query)

    cache_key = "search:#{query.downcase}:published:#{published}"

    cached_result = Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRY) do
      perform_search(query, published)
    end

    render json: cached_result.merge(
      search_count: RedisService.get_search_count(query),
      recent_searches: RedisService.get_recent_searches,
      unique_searches: RedisService.get_unique_searches
    )
  end

  private

  # SMELL: The controller is telling RedisService exactly what 3 steps to do.
  # Controller should just say "track this" and RedisService handles the rest.
  def track_search(query)
    RedisService.track(query)
  end

  # SMELL: One method doing 3 jobs — build ES query, run it, format response.
  def perform_search(query, published)
    search_definition = {
      query: {
        bool: {
          must: {
            match: { title: query }
          }
        }
      },
      aggs: {
        published_breakdown: {
          terms: { field: :published }
        }
      }
    }

    if published.present?
      search_definition[:query][:bool][:filter] = {
        term: { published: published == "true" }
      }
    end

    response = Post.search(search_definition)
    results = response.records.to_a
    aggregations = response.aggregations

    published_breakdown = aggregations
      .published_breakdown
      .buckets
      .each_with_object({}) do |bucket, hash|
        hash[bucket["key_as_string"] || bucket["key"].to_s] = bucket["doc_count"]
      end

    {
      query: query,
      published_filter: published,
      cached: true,
      total: results.count,
      aggregations: {
        published_breakdown: published_breakdown
      },
      results: results.map { |post|
        {
          id: post.id,
          title: post.title,
          published: post.published,
          user_id: post.user_id
        }
      }
    }
  end
end
