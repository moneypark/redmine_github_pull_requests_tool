# Provides an endpoint to Github Webhooks to receive payloads related to Pull Requests
# It relies on the "github_webhook" gem to facilitate authentication and easier payload handling.
# Also this class relies on Github Event API V3 data, please refer to its documentation.
#
# @see https://developer.github.com/v3/activity/events/types/#pullrequestevent Github Webhook API
# @see https://github.com/ssaunier/github_webhook Github Webhook Gem
class PullRequestsController < ActionController::Base

  include GithubWebhook::Processor
  skip_before_action :verify_authenticity_token  # Endpoint is secured by the shared secret with GH Webhook APIs.

  # Regexp which decides if the action of the API payload contains the labels
  ASSIGN_LABELS_ACTION_REXP = /^edited|.*labeled$/i

  # Regexp which decides if the action of the API payload contains the reviewers
  ASSIGN_REVIEWERS_ACTION_REXP = /^review_request.*|synchronize$/i

  # Use the GithubWebhook gem to listen to PullRequestEvents
  # @note This controller action has no associated view because it provides a response to the client through respond_to
  #
  # @raise [PluginSettingsMissingError] If the Redmine-Github Pull Requests tool settings were not found
  # @raise [PluginSettingsError] If one of the required settings was not configured
  # @raise [ActiveRecord::RecordNotFound] If the linked Redmine Issue could not be found
  # @param [Hash] payload The PullRequest Payload from the Github Event API
  # @return [nil]
  def github_pull_request(payload)

    # Get the issue ID from the title
    issue_id = get_issue_id payload['pull_request']['title']
    cache_key = get_cache_key issue_id

    # To make sure the same issue cant be updated multiple times while one request is open and to
    # ensure multiprocessing ability, we use the rails caching system to create a lock key on the current issue ID.
    #
    # In development or other environments where the NullStore Cache is used, this will produce no errors,
    # but also the locking will not work because no key can be stored so it cant exist for retrieval.
    while Rails.cache.exist? cache_key
      sleep 0.5
    end

    Rails.cache.write cache_key, true, expires_in: 3.minutes

    begin
      # Get the issue itself or fail
      issue = Issue.find issue_id

      # Get or create the DB model for this pull request
      pull_request = PullRequest.find_or_initialize_by github_id: payload['pull_request']['id']

      # Link the issue
      pull_request.issue = issue

      # Set the basic data which we get from all kind of pull_request events
      set_pull_request_base_data pull_request, payload

      # List of labels are only submitted on following actions:
      # edited, labeled, unlabeled
      if assign_labels_on_action payload['action']
        set_pull_request_labels pull_request, payload['pull_request']['labels']
      end

      # Requested reviewers are only submitted on following actions:
      # review_requested, review_request_removed, synchronize
      if assign_reviewers_on_action payload['action']
        set_pull_request_reviewers pull_request, payload['pull_request']['requested_reviewers']
      end

      # Save or crash the request
      pull_request.save!

      # All relevant data was persisted, now update the issue with the configured custom fields
      RedmineGithubPullRequestsTool::Proxies::PullRequestReviewerProxy.update_issue_reviewers issue
      RedmineGithubPullRequestsTool::Proxies::TargetedBranchesProxy.update_targeted_branches issue

      # Return some data to the Github Webhook trigger which might or not be used
      success_data = {
          redmine_pull_request_id: pull_request.id,
          redmine_issue_id: issue_id,
          redmine_issue_status_id: issue.status.id,
          redmine_issue_status: issue.status.name
      }

      # Return success data
      respond_to do |format|
        format.html { render plain: success_data.to_s, status: :ok }
        format.json { render json: success_data, status: :ok }
      end

    ensure
      # Make sure to unlock the current Issue ID again,
      # no matter what errors might have happened in the previous try block
      Rails.cache.delete cache_key
    end

  # Rescue and show errors associated to the plugin configuration
  rescue RedmineGithubPullRequestsTool::Exceptions::CustomFieldNotFoundError,
         RedmineGithubPullRequestsTool::Exceptions::PluginSettingsError,
         RedmineGithubPullRequestsTool::Exceptions::PluginSettingsMissingError => e
    respond_to do |format|
      format.html { render plain: e.to_s, status: :internal_server_error }
      format.json { render json: { error: e }, status: :internal_server_error }
    end

  # Rescue and show errors associated to the submitted payload
  rescue RedmineGithubPullRequestsTool::Exceptions::MalformedPullRequestTitleError,
         RedmineGithubPullRequestsTool::Exceptions::RelatedIssueNotFoundError => e
    respond_to do |format|
      format.html { render plain: e.to_s, status: :bad_request }
      format.json { render json: { error: e }, status: :bad_request }
    end

  end

  private
  # Create a cache key for an issue lock
  #
  # @param [Integer] issue_id Issue Id
  # @return [String] The cache key
  def get_cache_key(issue_id)
    "ghprt_#{issue_id}_lock"
  end

  # Private method to set the base PR data from the Github API Payload
  #
  # @param [PullRequest] pull_request The targeted Pull Request
  # @param [Hash] payload The data as a Hash coming from the Gtihub Event API
  # @return [nil]
  def set_pull_request_base_data(pull_request, payload)
    pull_request.repo_name = payload['repository']['name']
    pull_request.github_url = payload['pull_request']['html_url']
    pull_request.github_number = payload['pull_request']['number']
    if payload['pull_request']['state'] == 'closed'
      pull_request.status = payload['pull_request']['merged'] ? 'merged' : 'closed'
    else
      pull_request.status = payload['pull_request']['state']
    end
    pull_request.title = payload['pull_request']['title']
    pull_request.body = payload['pull_request']['body']
    pull_request.locked = payload['pull_request']['locked']
    pull_request.pr_created_at = DateTime.parse(payload['pull_request']['created_at'])
    pull_request.pr_closed_at = DateTime.parse(payload['pull_request']['closed_at']) rescue nil
    pull_request.pr_merged_at = DateTime.parse(payload['pull_request']['merged_at']) rescue nil
    pull_request.head_branch_label = payload['pull_request']['head']['label']
    pull_request.head_branch_ref = payload['pull_request']['head']['ref']
    pull_request.head_branch_sha = payload['pull_request']['head']['sha']
    pull_request.base_branch_label = payload['pull_request']['base']['label']
    pull_request.base_branch_ref = payload['pull_request']['base']['ref']
    pull_request.base_branch_sha = payload['pull_request']['base']['sha']
    begin
      author = RedmineGithubPullRequestsTool::Proxies::GithubUserProxy
                   .get_user_by_github_login payload['pull_request']['head']['user']['login']
    rescue RedmineGithubPullRequestsTool::Exceptions::UserByGithubLoginNotFoundError
      author = nil
    end
    pull_request.author = author
  end

  # Assign all the current PR reviewers
  #
  # @param [PullRequest] pull_request The targeted Pull Request
  # @param [Array<Hash>] reviewers The reviewers as an array coming from the Gtihub Event API
  # @return [nil]
  def set_pull_request_reviewers(pull_request, reviewers)
    pull_request.reviewers.clear
    reviewers.each do |reviewer_data|
      begin
        user = RedmineGithubPullRequestsTool::Proxies::GithubUserProxy
                   .get_user_by_github_login reviewer_data['login']
      rescue RedmineGithubPullRequestsTool::Exceptions::UserByGithubLoginNotFoundError
        next
      end
      pull_request.reviewers << user
    end
  end

  # Assign all the current PR labels
  #
  # @param [PullRequest] pull_request The targeted Pull Request
  # @param [Array<Hash>] labels The labels as an array coming from the Gtihub Event API
  # @return [nil]
  def set_pull_request_labels(pull_request, labels)
    pull_request.labels.clear
    labels.each do |label_data|
      pull_request.labels << get_or_create_label(label_data)
    end
  end

  # Get or create a Github label
  #
  # @param [Hash] label_data The Label data coming from the Github Event API
  # @return [Label] The already existing and updated or newly created Label
  def get_or_create_label(label_data)
    label = Label.find_or_initialize_by label_github_id: label_data['id']
    label.url = label_data['url']
    label.name = label_data['name']
    label.color = label_data['color']
    label.default = label_data['default']
    label.save!
    label
  end

  # Given the Action of the payload, determine if labels are included in the payload
  #
  # @param [String] action The action specified in the payload
  # @return [bool] If the payload contains the labels
  def assign_labels_on_action(action)
    not (action =~ ASSIGN_LABELS_ACTION_REXP).nil?
  end

  # Given the Action of the payload, determine if reviewers are included in the payload
  #
  # @param [String] action The action specified in the payload
  # @return [bool] If the payload contains the reviewers
  def assign_reviewers_on_action(action)
    not (action =~ ASSIGN_REVIEWERS_ACTION_REXP).nil?
  end

  # Scan the PR title for a Task ID and get it as an integer
  #
  # @param [String] pr_title The PR title
  # @return [Integer] The ID of the associated Task
  def get_issue_id(pr_title)
    title_parts = pr_title.scan(get_issue_id_scanner)
    if title_parts.length != 1
      raise RedmineGithubPullRequestsTool::Exceptions::MalformedPullRequestTitleError.new pr_title
    end
    title_parts[0][0].to_i
  end

  # Gets the configured Issue ID Regexp from settings as a case-insensitive Ruby Regexp object
  # This Regexp can be set in the settings of the plugin
  #
  # @raise [PluginSettingsMissingError] If the Redmine-Github Pull Requests tool settings were not found
  # @raise [PluginSettingsError] If the Issue ID Scan Pattern was not set
  # @return [Regexp] The case insensitive Regexp object to match Issue IDs against
  def get_issue_id_scanner
    unless Setting.respond_to? :plugin_redmine_github_pull_requests_tool
      raise RedmineGithubPullRequestsTool::Exceptions::PluginSettingsMissingError.new
    end
    settings = Setting.plugin_redmine_github_pull_requests_tool
    unless settings.key?('issue_id_scan_pattern') && !settings['issue_id_scan_pattern'].empty?
      raise RedmineGithubPullRequestsTool::Exceptions::PluginSettingsError.new :issue_id_scan_pattern
    end
    Regexp.new settings['issue_id_scan_pattern'], Regexp::IGNORECASE
  end

  # Gets the configured Github Webhook Secret so that issued Pull Request Events from Github Webhooks
  # can be authorized. This value can be set in the settings of the plugin
  #
  # @raise [PluginSettingsMissingError] If the Redmine-Github Pull Requests tool settings were not found
  # @raise [PluginSettingsError] If the Github Webhook API Secret was not set
  # @return [String] The configured Github Webhook Secret
  def webhook_secret(payload)
    unless Setting.respond_to? :plugin_redmine_github_pull_requests_tool
      raise RedmineGithubPullRequestsTool::Exceptions::PluginSettingsMissingError.new
    end
    settings = Setting.plugin_redmine_github_pull_requests_tool
    unless settings.key?('github_webhook_api_secret') && !settings['github_webhook_api_secret'].empty?
      raise RedmineGithubPullRequestsTool::Exceptions::PluginSettingsError.new :github_webhook_api_secret
    end
    settings['github_webhook_api_secret']
  end
end
