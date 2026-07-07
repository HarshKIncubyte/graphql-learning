# spec/graphql/mutations/delete_user_spec.rb
require 'rails_helper'

RSpec.describe 'DeleteUser Mutation', type: :request do
  let!(:user) { create(:user) }

  it 'deletes the user' do
    mutation = <<~GRAPHQL
      mutation {
        deleteUser(input: { id: "#{user.id}" }) {
          success
          errors
        }
      }
    GRAPHQL

    expect { post_graphql(mutation) }.to change(User, :count).by(-1)

    expect(graphql_response_data('deleteUser')['success']).to be true
  end

  it 'returns error for non-existent user' do
    mutation = <<~GRAPHQL
      mutation {
        deleteUser(input: { id: "0" }) {
          success
          errors
        }
      }
    GRAPHQL

    post_graphql(mutation)

    data = graphql_response_data('deleteUser')
    expect(data['success']).to be false
    expect(data['errors']).to include('User not found')
  end
end
