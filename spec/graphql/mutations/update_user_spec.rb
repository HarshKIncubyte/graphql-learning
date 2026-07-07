# spec/graphql/mutations/update_user_spec.rb
require 'rails_helper'

RSpec.describe 'UpdateUser Mutation', type: :request do
  let!(:user) { create(:user) }

  context 'with valid input' do
    let(:mutation) do
      <<~GRAPHQL
        mutation {
          updateUser(input: { id: "#{user.id}", name: "Updated Name" }) {
            user { id name }
            errors
          }
        }
      GRAPHQL
    end

    it 'updates the user' do
      post_graphql(mutation)

      data = graphql_response_data('updateUser')
      expect(data['user']['name']).to eq('Updated Name')
      expect(data['errors']).to be_empty
    end
  end

  context 'with non-existent id' do
    let(:mutation) do
      <<~GRAPHQL
        mutation {
          updateUser(input: { id: "0", name: "Ghost" }) {
            user { id }
            errors
          }
        }
      GRAPHQL
    end

    it 'returns user not found error' do
      post_graphql(mutation)

      data = graphql_response_data('updateUser')
      expect(data['user']).to be_nil
      expect(data['errors']).to include('User not found')
    end
  end
end
