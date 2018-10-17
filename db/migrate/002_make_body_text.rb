class MakeBodyText < ActiveRecord::Migration
  def change
    change_column :pull_requests, :body, :text, null: true
  end
end