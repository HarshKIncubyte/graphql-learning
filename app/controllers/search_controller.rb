class SearchController < ApplicationController
  def search
    query = params[:q]
    published = params[:published]

    if query.blank?
      render json: { error: "Please provide a search query" }, status: :bad_request
      return
    end

    search_definition = {
      query: {
        bool: {
          must: {
            match: { title: query }
          }
        }
      }
    }

    if published.present?
      search_definition[:query][:bool][:filter] = {
        term: { published: published == "true" }
      }
    end

    results = Post.search(search_definition).records.to_a

    render json: {
      query: query,
      published_filter: published,
      total: results.count,
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
