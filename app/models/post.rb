class Post < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  belongs_to :user
  scope :published, -> { where(published: true) }

  after_commit :clear_search_cache

  private

  def clear_search_cache
    SearchCacheInvalidator.new.call
  end
end
