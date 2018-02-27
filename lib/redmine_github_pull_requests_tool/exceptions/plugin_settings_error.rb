module RedmineGithubPullRequestsTool
  module Exceptions
    # This custom error indicates that a required setting of the plugin was not configured
    class PluginSettingsError < StandardError
      attr_reader :key

      # Pass the settings key and initialize a StandardError with an empty message since to_s will be overridden
      #
      # @param [Symbol] key The settings key which is missing
      def initialize(key=nil)
        @key = key
        super('')
      end

      # Override the default to_s Method to indicate which key is missing
      def to_s
        I18n.t 'exceptions.plugin_setting_key_missing', key: key
      end
    end
  end
end
