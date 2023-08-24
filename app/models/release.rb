# The implementation of this is up to the Owner of the Redmine instance, he has to decide which tags should be
# shown and which not. The intended use of this model is to let users know in which release the PR is included,
# which can be done by looping over
class Release < ActiveRecord::Base
  has_many :pull_requests, dependent: :nullify
end
