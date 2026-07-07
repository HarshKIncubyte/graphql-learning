# spec/graphql/mutations/create_user_spec.rb

require 'rails_helper'

RSpec.describe 'CreateUser Mutation', type: :request do
  let(:name) { 'Alice' }
  let(:email) { 'alice@example.com' }

  let(:mutation) do
    <<~GRAPHQL
      mutation {
        createUser(input: { name: "#{name}", email: "#{email}" }) {
          user { id name email }
          errors
        }
      }
    GRAPHQL
  end

  subject(:execute_mutation) { post_graphql(mutation) }
  let(:create_user_data) { graphql_response_data('createUser') }

  context 'with valid input' do
    it 'creates a user' do
      expect { execute_mutation }.to change(User, :count).by(1)
      expect(response.status).to eq(200)

      expect(create_user_data['user']['email']).to eq(email)
      expect(create_user_data['user']['name']).to eq(name)
      expect(create_user_data['errors']).to be_empty
    end
  end

  context 'when email already exists' do
    let!(:existing_user) { create(:user, email: 'alice@example.com') }

    it 'returns validation errors and does not create a new user' do
      expect { execute_mutation }.not_to change(User, :count)
      expect(response.status).to eq(200)

      expect(create_user_data['user']).to be_nil
      expect(create_user_data['errors']).to include('Email has already been taken')
    end
  end

  context 'when email is missing' do
    let(:mutation) do
      <<~GRAPHQL
        mutation {
          createUser(input: { name: "#{name}" }) {
            user { id }
            errors
          }
        }
      GRAPHQL
    end

    it 'returns a GraphQL argument error' do
      execute_mutation
      expect(graphql_errors).to be_present
    end
  end
end
