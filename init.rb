require 'redmine'

# Setup the plugin
Redmine::Plugin.register :redmine_github_pull_requests_tool do
  name 'Github Pull Requests Tool for Redmine plugin'
  author 'MoneyPark AG'
  description 'Provides Github Pull Request integration with Redmine and writes data to custom fields'
  version '0.2.0'
  url 'https://github.com/moneypark/redmine_github_pull_requests_tool'
  author_url 'https://github.com/moneypark/'

  requires_redmine version_or_higher: '3.4'

  settings(
    default: {
      github_login_name_field_id: 0,
      pr_reviewers_field_id: 0,
      pr_targeted_branches_field_id: 0,
      issue_id_scan_pattern: "^task[ _\\-](\\d+).*$",
      github_webhook_api_secret: 'YOUR-WEBHOOK-API-SECRET',
    },
    partial: 'settings/pull_requests_tool_settings'
  )
end

unless Issue.included_modules.include? RedmineGithubPullRequestsTool::IssuePatch
  Issue.send :include, RedmineGithubPullRequestsTool::IssuePatch
end

unless User.included_modules.include? RedmineGithubPullRequestsTool::UserPatch
  User.send :include, RedmineGithubPullRequestsTool::UserPatch
end

require File.expand_path 'lib/redmine_github_pull_requests_tool/hooks', __dir__
