module RedmineGithubPullRequestsTool
  # MonkeyPatch the PullRequest association to the User model
  module UserPatch
    def self.included(base) # :nodoc:
      base.class_eval do
        has_and_belongs_to_many :pull_request_reviews, class_name: 'PullRequest', foreign_key: :pull_request_id
      end
    end
  end
end
