module RedmineGithubPullRequestsTool
  module Proxies
    # Proxy class which contains class methods which handle the logic of Pull Request Reviewers and
    # their custom field in Redmine.
    class PullRequestReviewerProxy

      # Returns the Pull Request Reviewers Custom Field ID
      #
      # @raise [PluginSettingsMissingError] If the Redmine-Github Pull Requests tool settings were not found
      # @raise [PluginSettingsError] If the Pull Request Reviewers Custom Field was not associated
      # @raise [CustomFieldNotFoundError] If the Pull Request Reviewers Custom Field was not found in the DB
      # @return [Integer] The ID of the configured Redmine Custom Field
      # @note This value must be set by an administrator in the Plugin Settings
      def self.pr_reviewers_field_id
        unless Setting.respond_to? :plugin_redmine_github_pull_requests_tool
          raise Exceptions::PluginSettingsMissingError.new
        end
        settings = Setting.plugin_redmine_github_pull_requests_tool
        unless settings.key?('pr_reviewers_field_id') && settings['pr_reviewers_field_id'].to_i > 0
          raise Exceptions::PluginSettingsError.new :pr_reviewers_field_id
        end
        unless CustomField.exists? id: settings['pr_reviewers_field_id']
          raise Exceptions::CustomFieldNotFoundError.new 'Pull Request Reviewers'
        end
        settings['pr_reviewers_field_id'].to_i
      end

      # Set all current Pull Request Reviewers of an Issue.
      # It takes into consideration all related Pull Request and updates the custom field
      #
      # @param [::Issue] issue The targeted Redmine issue
      # @raise [PluginSettingsMissingError] If the Redmine-Github Pull Requests tool settings were not found
      # @raise [PluginSettingsError] If the Pull Request Reviewers Custom Field was not associated
      # @raise [CustomFieldNotFoundError] If the Pull Request Reviewers Custom Field was not found in the DB
      # @return [nil]
      def self.update_issue_reviewers(issue)
        self.clean_issue_reviewers issue  # Remove all associated PR reviewers from the issue
        PullRequest
          .where(issue_id: issue.id)  # Get all related Pull Requests to this issue
          .reject { |pr| pr.reviewers.empty? }  # Exclude PR from matching if it has no reviewers
          .collect { |pr| pr.reviewers }  # Get all reviewers from all associated PRs
          .flatten  # Make it flat
          .uniq  # Don't repeat values
          .each do |reviewer|
            # Create a custom value so that we can work as usual with redmine
            CustomValue.create(
                custom_field_id: self.pr_reviewers_field_id,
                customized_type: 'Issue',
                customized_id: issue.id,
                value: reviewer.id
            )
          end
      end

      # Remove all Custom Values that equal a Pull Request Reviewer for an Issue.
      #
      # @param [::Issue] issue The targeted Redmine issue
      # @raise [PluginSettingsMissingError] If the Redmine-Github Pull Requests tool settings were not found
      # @raise [PluginSettingsError] If the Pull Request Reviewers Custom Field was not associated
      # @raise [CustomFieldNotFoundError] If the Pull Request Reviewers Custom Field was not found in the DB
      # @return [nil]
      def self.clean_issue_reviewers(issue)
        # Removes all PR reviewers from an issue
        CustomValue.where(
            custom_field_id: self.pr_reviewers_field_id,
            customized_type: 'Issue',
            customized_id: issue.id
        ).destroy_all
      end
    end
  end
end
