require "net/http"
require "json"

class GithubService
  BASE_URL = "https://api.github.com"

  def fetch_user(username)
    uri = URI("#{BASE_URL}/users/#{username}")
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: 5) do |http|
      http.get(uri.path)
    end

    return { error: "User not found" } if response.code == "404"
    return { error: "GitHub API error" } unless response.code == "200"

    JSON.parse(response.body)
  end
end
