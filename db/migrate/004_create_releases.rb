class CreateReleases < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change

    create_table :releases do |t|
      t.string :name, null: false
      t.string :repo_name, null: false

      # Rails default timestamps
      t.timestamps
    end
    add_index :releases, :name, name: 'idx_release_name'
    add_index :releases, :repo_name, name: 'idx_release_repo_name'

    add_column :pull_requests, :release_id, :integer, null: true
    add_index :pull_requests, :release_id, name: 'idx_pr_release_id'

  end
end
