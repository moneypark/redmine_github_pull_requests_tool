module RedmineGithubPullRequestsTool
  module Exceptions
    # This custom error indicates that given a specific ID an Issue could not be found in Redmine
    class RelatedIssueNotFoundError < StandardError
      attr_reader :id

      # Pass the id key and initialize a StandardError with an empty message since to_s will be overridden
      #
      # @param [Integer] id The ID which was not found
      def initialize(id=nil)
        @id = id
        super('')
      end

      # Override the default to_s Method to indicate which key is missing
      def to_s
        I18n.t 'exceptions.related_issue_not_found', id: id
      end
    end
  end
end
