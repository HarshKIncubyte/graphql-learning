class AddIndexToPostsTitle < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!
  def change
    add_index :posts, :title, algorithm: :concurrently
  end
end
