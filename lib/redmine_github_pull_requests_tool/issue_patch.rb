module RedmineGithubPullRequestsTool
  # MonkeyPatch the PullRequest association to the Issue model
  module IssuePatch
    def self.included(base) # :nodoc:
      base.class_eval do
        has_many :pull_requests
      end
    end
  end
end
