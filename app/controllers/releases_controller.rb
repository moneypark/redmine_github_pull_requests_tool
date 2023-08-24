# Provides an endpoint to manage associations between Pull Requests and releases
# Releases is just a model containing a name, but it is helpful to know the tag/release
# in which the PR was introduced to the release lifecycle. This value can be used however you prefer,
# but it is suggested to always associate a PR with the release candidate, minor or patch release which
# introduced it.
class ReleasesController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def unset_release
    if params[:release_name]
      release = Release.find_by_name params[:release_name]
      if release
        PullRequest.where(release_id: release.id).update_all(release_id: nil)
        release.destroy
      end
    elsif params[:pull_request_ids].length
      PullRequest.where(github_id: params[:pull_request_ids]).update_all(release_id: nil)
    end
  end

  def set_release
    release = Release.find_by_name params[:release_name]
    unless release
      release = Release.create name: params[:release_name]
    end
    PullRequest.where(github_id: params[:pull_request_ids]).update_all(release_id: release.id)
  end

end