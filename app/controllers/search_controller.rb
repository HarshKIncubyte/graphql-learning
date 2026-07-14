class SearchController < ApplicationController
  CACHE_EXPIRY = 10.minutes

  def search
    query = params[:q]
    published = params[:published]

    if query.blank?
      render json: { error: "Please provide a search query" }, status: :bad_request
      return
    end

    cache_key = "search:#{query.downcase}:published:#{published}"

    cached_result = Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRY) do
      perform_search(query, published)
    end

    render json: cached_result
  end

  private

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
