class RemoveRepoNameFromReleases < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change

    remove_index :releases, name: 'idx_release_repo_name'
    remove_column :releases, :repo_name

  end
end
