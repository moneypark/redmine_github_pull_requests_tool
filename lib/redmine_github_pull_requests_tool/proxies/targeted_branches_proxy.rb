module RedmineGithubPullRequestsTool
  module Proxies
    # Proxy class which contains class methods which handle the logic of Pull Request Targeted Branches and
    # their custom field in Redmine.
    class TargetedBranchesProxy

      # Returns the Pull Request Targeted Branches Custom Field ID
      #
      # @raise [PluginSettingsMissingError] If the Redmine-Github Pull Requests tool settings were not found
      # @raise [PluginSettingsError] If the Pull Request Targeted Branches Custom Field was not associated
      # @raise [CustomFieldNotFoundError] If the Pull Request Targeted Branches Custom Field was not found in the DB
      # @return [Integer] The ID of the configured Redmine Custom Field
      # @note This value must be set by an administrator in the Plugin Settings
      def self.pr_targeted_branches_field_id
        unless Setting.respond_to? :plugin_redmine_github_pull_requests_tool
          raise Exceptions::PluginSettingsMissingError.new
        end
        settings = Setting.plugin_redmine_github_pull_requests_tool
        unless settings.key?('pr_targeted_branches_field_id') && settings['pr_targeted_branches_field_id'].to_i > 0
          raise Exceptions::PluginSettingsError.new :pr_targeted_branches_field_id
        end
        unless CustomField.exists? id: settings['pr_targeted_branches_field_id']
          raise Exceptions::CustomFieldNotFoundError.new 'Targeted Branches'
        end
        settings['pr_targeted_branches_field_id'].to_i
      end

      # Set all current Pull Request Targeted Branches of an Issue.
      # It takes into consideration all related Pull Request and updates the custom field
      #
      # @param [::Issue] issue The targeted Redmine issue
      # @raise [PluginSettingsMissingError] If the Redmine-Github Pull Requests tool settings were not found
      # @raise [PluginSettingsError] If the Pull Request Targeted Branches Custom Field was not associated
      # @raise [CustomFieldNotFoundError] If the Pull Request Targeted Branches Custom Field was not found in the DB
      # @return [nil]
      def self.update_targeted_branches(issue)
        self.clean_targeted_branches issue  # Remove all associated PR Targeted Branches from the issue
        PullRequest
          .where(issue: issue)  # Get all related Pull Requests to this issue
          .collect { |pr| pr.targeted_branch }  # Get all targeted branches from all associated PRs
          .uniq  # Don't repeat values
          .each do |branch_label|
            # Create a custom value so that we can work as usual with redmine
            CustomValue.create(
                custom_field_id: self.pr_targeted_branches_field_id,
                customized_type: 'Issue',
                customized_id: issue.id,
                value: branch_label
            )
          end
        self.update_possible_values
      end

      # Remove all Custom Values that equal a Pull Request Target branch for an Issue.
      #
      # @param [::Issue] issue The targeted Redmine issue
      # @raise [PluginSettingsMissingError] If the Redmine-Github Pull Requests tool settings were not found
      # @raise [PluginSettingsError] If the Pull Request Targeted Branches Custom Field was not associated
      # @raise [CustomFieldNotFoundError] If the Pull Request Targeted Branches Custom Field was not found in the DB
      # @return [nil]
      def self.clean_targeted_branches(issue)
        # Removes all PR Targeted Branches from an issue
        CustomValue.where(
            custom_field_id: self.pr_targeted_branches_field_id,
            customized_type: 'Issue',
            customized_id: issue.id
        ).destroy_all
      end

      private
      # Updates the custom field's possible values by getting all distinct targeted branches from all known Pull Requests
      #
      # @note This method will always override the possible values of the Targeted Branches custom field
      def self.update_possible_values
        values = PullRequest.distinct.pluck(:repo_name, :base_branch_ref)  # SELECT DISTINCT repo_name, base_branch_ref ...
        field = CustomField.find self.pr_targeted_branches_field_id
        field.possible_values = values.map { |pair| pair.join ':' }.sort
        field.save
      end
    end
  end
end
