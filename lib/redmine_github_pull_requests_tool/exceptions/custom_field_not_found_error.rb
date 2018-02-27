module RedmineGithubPullRequestsTool
  module Exceptions
    # This custom error indicates that a specified and needed Custom Field was not found in the database
    class CustomFieldNotFoundError < StandardError
      attr_reader :name

      # Pass the custom field name and initialize a StandardError with an empty message since to_s will be overridden
      #
      # @param [Symbol] name The name of the custom field which is missing
      def initialize(name=nil)
        @name = name
        super('')
      end

      # Override the default to_s Method to indicate which custom field is missing
      def to_s
        I18n.t 'exceptions.custom_field_not_found', name: name
      end
    end
  end
end
