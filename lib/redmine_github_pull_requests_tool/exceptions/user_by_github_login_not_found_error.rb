module RedmineGithubPullRequestsTool
  module Exceptions
    # This custom error indicates that a User could not be found through a Github Login name
    class UserByGithubLoginNotFoundError < StandardError
      attr_reader :login_name

      # Pass the login name and initialize a StandardError with an empty message since to_s will be overridden
      #
      # @param [Symbol] login_name The user name which could not be found
      def initialize(login_name=nil)
        @login_name = login_name
        super('')
      end

      # Override the default to_s Method to indicate which user can't be found
      def to_s
        I18n.t 'exceptions.user_by_github_login_not_found', login_name: login_name
      end
    end
  end
end
