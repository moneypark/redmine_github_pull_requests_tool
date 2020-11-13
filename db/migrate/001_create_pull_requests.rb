class CreatePullRequests < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change

    # Add a reflection model for GitHub Pull Requests
    create_table :pull_requests do |t|

      # Github PR data
      t.integer :github_id, null: false
      t.string :github_url, null: false
      t.integer :github_number, null: false
      t.string :repo_name, null: false
      t.string :status, null: false
      t.string :title, null: false
      t.string :body, null: true
      t.boolean :locked, default: false
      t.datetime :pr_created_at, null: false
      t.datetime :pr_updated_at, null: true
      t.datetime :pr_closed_at, null: true
      t.datetime :pr_merged_at, null: true

      # Github Branch data
      t.string :head_branch_label, null: false
      t.string :head_branch_ref, null: false
      t.string :head_branch_sha, null: false
      t.string :base_branch_label, null: false
      t.string :base_branch_ref, null: false
      t.string :base_branch_sha, null: false

      # Linked Redmine data
      t.integer :issue_id, null: false
      t.integer :author_id, null: true

      # Rails default timestamps
      t.timestamps
    end
    add_index :pull_requests, :author_id, name: 'idx_pr_author_id'
    add_index :pull_requests, :issue_id, name: 'idx_pr_issue_id'

    # Reflect repo labels in Redmine
    create_table :labels do |t|
      t.integer :label_github_id, null: false
      t.string :url
      t.string :name, null: false
      t.string :color
      t.boolean :default

      # Rails default timestamps
      t.timestamps
    end
    add_index :labels, :label_github_id, name: 'idx_l_github_id'

    # Join PR and Labels
    create_join_table :pull_requests, :labels do |t|
      t.index [:pull_request_id, :label_id]
    end

    # Join PR and Users (As reviewers)
    create_join_table :pull_requests, :users do |t|
      t.index [:pull_request_id, :user_id]
    end

  end
end
