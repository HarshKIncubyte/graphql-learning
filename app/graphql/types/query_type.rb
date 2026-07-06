# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :users, [ Types::UserType ], null: false, description: "Returns all users"

    field :user, Types::UserType, null: true do
      argument :id, ID, required: true
    end

    field :posts, [ Types::PostType ], null: false do
      argument :published, Boolean, required: false
    end

    def users
      User.all
    end

    def user(id:)
      User.find_by(id: id)
    end

    def posts(published: nil)
      query = Post.all
      query = query.published if published
      query
    end
  end
end
