class ChangeLabelId < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    change_column :labels, :label_github_id, :bigint
  end
end