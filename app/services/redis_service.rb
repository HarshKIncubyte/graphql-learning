class RedisService
  REDIS = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
  RECENT_SEARCHES_LIMIT = 10

  def self.track(term)
    increment_search_count(term)
    add_to_recent_searches(term)
    add_to_unique_searches(term)
  end

  def self.increment_search_count(term)
    REDIS.incr("search_count:#{term.downcase}")
  end

  def self.get_search_count(term)
    REDIS.get("search_count:#{term.downcase}").to_i
  end

  def self.add_to_recent_searches(term)
    REDIS.lpush("recent_searches", term.downcase)
    REDIS.ltrim("recent_searches", 0, RECENT_SEARCHES_LIMIT - 1)
  end

  def self.get_recent_searches
    REDIS.lrange("recent_searches", 0, RECENT_SEARCHES_LIMIT - 1)
  end

  def self.add_to_unique_searches(term)
    REDIS.sadd("unique_searches", term.downcase)
  end

  def self.get_unique_searches
    REDIS.smembers("unique_searches")
  end
end
