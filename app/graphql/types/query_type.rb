# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :users, [ Types::UserType ], null: false, description: "Returns all users" do
      argument :limit, Int, required: false
      argument :offset, Int, required: false
    end

    field :user, Types::UserType, null: true do
      argument :id, ID, required: true
    end

    field :posts, [ Types::PostType ], null: false do
      argument :published, Boolean, required: false
    end

    def users(limit: nil, offset: nil)
      query = User.all
      query = query.limit(limit) if limit
      query = query.offset(offset) if offset
      query
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
