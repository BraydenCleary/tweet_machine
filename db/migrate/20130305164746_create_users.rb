class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :access_token
      t.string :access_token_secret
      t.string :username
      t.string :profile_image_url
      t.integer :friend_count
    end
  end
end
