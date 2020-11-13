class MakeBodyText < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    change_column :pull_requests, :body, :text, null: true
  end
end