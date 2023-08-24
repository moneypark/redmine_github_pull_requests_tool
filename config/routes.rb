resource :github_webhooks, only: :create, defaults: { formats: :json }, controller: 'pull_requests'
post :set_release, to: 'releases#set_release'
delete :unset_release, to: 'releases#unset_release'