resource :github_webhooks, only: :create, defaults: { formats: :json }, controller: 'pull_requests'
