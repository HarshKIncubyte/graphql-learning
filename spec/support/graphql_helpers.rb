module GraphqlHelpers
  def post_graphql(query)
    post '/graphql', params: { query: query }
  end

  def graphql_response
    JSON.parse(response.body)
  end

  def graphql_response_data(operation)
    graphql_response.dig('data', operation)
  end

  def graphql_errors
    graphql_response['errors']
  end
end

RSpec.configure do |config|
  config.include GraphqlHelpers, type: :request
end
