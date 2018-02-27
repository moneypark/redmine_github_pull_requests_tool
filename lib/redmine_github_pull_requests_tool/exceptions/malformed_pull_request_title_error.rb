module RedmineGithubPullRequestsTool
  module Exceptions
    # This custom error indicates that a Pull Request title could not be matched
    class MalformedPullRequestTitleError < StandardError
      attr_reader :title

      # Pass the title and initialize a StandardError with an empty message since to_s will be overridden
      #
      # @param [String] title The title which could not be matched
      def initialize(title=nil)
        @title = title
        super('')
      end

      # Override the default to_s Method to indicate which title is malformed
      def to_s
        I18n.t 'exceptions.malformed_pr_title', title: title
      end
    end
  end
end
