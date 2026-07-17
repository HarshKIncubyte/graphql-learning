require 'rails_helper'

RSpec.describe 'Users Query', type: :request do
  describe 'querying all the users' do
    let!(:users) { create_list(:user, 5) }
    let(:query) do
      <<~GRAPHQL
        query {
          users {
            id
            name
            email
          }
        }
      GRAPHQL
    end

    it 'returns all the users' do
      post '/graphql', params: { query: query }

      json = JSON.parse(response.body)
      data = json['data']['users']

      expect(response).to have_http_status(:ok)
      expect(data.length).to eq(5)
    end
  end

  describe 'querying users with pagination' do
    let!(:users) { create_list(:user, 5) }

    it 'returns only the requested number of users when limit is given' do
      query = <<~GRAPHQL
        query {
          users(limit: 2) {
            id
            name
            email
          }
        }
      GRAPHQL

      post '/graphql', params: { query: query }

      json = JSON.parse(response.body)
      data = json['data']['users']

      expect(response).to have_http_status(:ok)
      expect(data.length).to eq(2)
    end

    it 'skips the requested number of users when offset is given' do
      query = <<~GRAPHQL
        query {
          users(offset: 2) {
            id
            email
          }
        }
      GRAPHQL

      post '/graphql', params: { query: query }

      json = JSON.parse(response.body)
      data = json['data']['users']

      expect(data.map { |u| u['email'] }).to eq(users[2..].map(&:email))
    end

    it 'paginates correctly when limit and offset are combined' do
      query = <<~GRAPHQL
        query {
          users(limit: 2, offset: 2) {
            id
            email
          }
        }
      GRAPHQL

      post '/graphql', params: { query: query }

      json = JSON.parse(response.body)
      data = json['data']['users']

      expect(data.map { |u| u['email'] }).to eq(users[2..3].map(&:email))
    end
  end

  describe 'querying a single user by ID' do
    let!(:user) { create(:user) }
    let(:query) do
      <<~GRAPHQL
        query{
          user(id: #{user.id}) {
            id
            name
            email
          }
        }
      GRAPHQL
    end

    it 'returns the user with the specified ID' do
      post '/graphql', params: { query: query }

      json = JSON.parse(response.body)
      data = json['data']['user']

      expect(data['email']).to eq(user.email)
      expect(data['name']).to eq(user.name)
    end

    it 'returns nil for non-existent user' do
      query = <<~GRAPHQL
        query {
          user(id: "0") {
            id
            name
            email
          }
        }
      GRAPHQL

      post '/graphql', params: { query: query }

      json = JSON.parse(response.body)
      expect(json['data']['user']).to be_nil
    end
  end
end
