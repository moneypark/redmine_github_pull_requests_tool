# This model reflects a Pull Request from Github and has labels as well reviewers and is associated
# with Redmine Issues
class PullRequest < ActiveRecord::Base
  belongs_to :issue
  belongs_to :author, class_name: 'User'
  has_and_belongs_to_many :reviewers, class_name: 'User', foreign_key: :pull_request_id
  has_and_belongs_to_many :labels

  # Return a combined name for the targeted branch
  def targeted_branch
    "#{self.repo_name}:#{self.base_branch_ref}"
  end
end
