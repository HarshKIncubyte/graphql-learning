class SearchCacheInvalidator
  def call
    Rails.cache.delete_matched("search:*")
  end
end
