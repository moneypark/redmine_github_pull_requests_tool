module RedmineGithubPullRequestsTool
  module Proxies
    # Proxy class which contains class methods which handle the logic between a Github Login Name and User
    class GithubUserProxy
      # Returns the Github Login Name Custom Field ID
      #
      # @raise [PluginSettingsMissingError] If the Redmine-Github Pull Requests tool settings were not found
      # @raise [PluginSettingsError] If the Github Login Name Custom Field was not associated
      # @raise [CustomFieldNotFoundError] If the Github Login Name Custom Field was not found in the DB
      # @return [Integer] The ID of the configured Redmine Custom Field
      # @note This value must be set by an administrator in the Plugin Settings
      def self.github_login_name_field_id
        unless Setting.respond_to? :plugin_redmine_github_pull_requests_tool
          raise Exceptions::PluginSettingsMissingError.new
        end
        settings = Setting.plugin_redmine_github_pull_requests_tool
        unless settings.key?('github_login_name_field_id') && settings['github_login_name_field_id'].to_i > 0
          raise Exceptions::PluginSettingsError.new :github_login_name_field_id
        end
        unless CustomField.exists? id: settings['github_login_name_field_id']
          raise Exceptions::CustomFieldNotFoundError.new 'User Github Login Name'
        end
        settings['github_login_name_field_id'].to_i
      end

      # Given a Github Login name, retrieve the associated user
      #
      # @raise [PluginSettingsMissingError] If the Redmine-Github Pull Requests tool settings were not found
      # @raise [PluginSettingsError] If the Github Login Name Custom field was not associated
      # @raise [CustomFieldNotFoundError] If the Github Login Name Custom Field was not found in the DB
      # @raise [UserByGithubLoginNotFound] If there was no User found matching the given Github Login name
      # @return [User] if a User was associated to the given Github Login Name
      def self.get_user_by_github_login(github_login)
        CustomValue.find_by_custom_field_id_and_value!(
            self.github_login_name_field_id,
            github_login
        ).customized
      rescue ActiveRecord::RecordNotFound
          raise Exceptions::UserByGithubLoginNotFoundError.new github_login
      end
    end
  end
end
