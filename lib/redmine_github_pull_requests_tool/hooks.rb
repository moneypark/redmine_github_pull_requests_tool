module RedmineGithubPullRequestsTool
  # Hook into Redmine views to render pull request data within an Issue Detail view
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_issues_show_description_bottom, partial: 'pull_requests/issue_overview'
  end
end
