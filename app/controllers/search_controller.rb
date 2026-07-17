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

  def track_search(query)
    RedisService.track(query)
  end

  def perform_search(query, published)
    PostSearchService.new(query: query, published: published).call
  end
end
