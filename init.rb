require 'redmine'

# Get ready for Rails 5.1
if Rails::VERSION::MAJOR >= 5 && Rails::VERSION::MINOR >= 1
  reloader = ActiveSupport::Reloader
else
  reloader = ActionDispatch::Callbacks
end

# Ensure Patches are applied
reloader.to_prepare do
  require_dependency 'issue'
  require_dependency 'user'
  require_dependency 'redmine_github_pull_requests_tool/hooks'

  unless Issue.included_modules.include? RedmineGithubPullRequestsTool::IssuePatch
    Issue.send :include, RedmineGithubPullRequestsTool::IssuePatch
  end

  unless User.included_modules.include? RedmineGithubPullRequestsTool::UserPatch
    User.send :include, RedmineGithubPullRequestsTool::UserPatch
  end
end

# Set up the modules description under lib/

# This module contains all required hooks, patches, proxies and error classes for this Plugin
module RedmineGithubPullRequestsTool
  # This module contains all Proxy classes that handle the exchange of data between the Plugin and
  # configured custom fields
  module Proxies; end
  # This module contains all custom errors that can occur during the processing of a Webhook payload
  module Exceptions; end
end

# Setup the plugin
Redmine::Plugin.register :redmine_github_pull_requests_tool do
  name 'Github Pull Requests Tool for Redmine plugin'
  author 'MoneyPark AG'
  description 'Provides Github Pull Request integration with Redmine and writes data to custom fields'
  version '0.1.2'
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
