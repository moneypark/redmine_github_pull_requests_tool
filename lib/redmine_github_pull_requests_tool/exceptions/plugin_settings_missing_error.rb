module RedmineGithubPullRequestsTool
  module Exceptions
    # This custom error indicates that the required settings were not found at all in the Setting class of Redmine
    class PluginSettingsMissingError < StandardError
      # Initialize a StandardError with a predefined message saying that the settings for this plugin were not found
      def initialize
        super(I18n.t 'exceptions.plugin_settings_missing')
      end
    end
  end
end
