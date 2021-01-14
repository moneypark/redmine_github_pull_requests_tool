# Redmine Github Pull Requests Tool
A Redmine Plugin that integrates Pull Requests, their statuses, 
reviewers and targeted branches into Issues. It provides an endpoint
to Github Webhooks so that it can track creation and changes on each 
Pull Request for each repo that has a webhook configured with the endpoint
on this Plugin.

## Requirements
* Ruby 2.2 or higher
* Redmine 3.4 or higher
* Github repo(s) and access to Webhook settings
* A naming pattern for all of your repo's Pull Request Titles which contains 
the ID of the targeted Issue in Redmine that you can express with a Regexp

Chances are that this plugin will work for Versions of 
Redmine between 3.0 and 3.4, but it is not tested against pre-3.4 versions,
so use it on your own risk. However it will certainly not work with pre-2.0 
versions of Ruby.

## Installing the plugin
See [Installing a plugin](http://www.redmine.org/projects/redmine/wiki/Plugins) 
in the Redmine Wiki.

## Setup
Once the installation is done, go to the Redmine administration

### Add Custom fields
1. **Pull Request Reviewers**
    * Type of related object is `Issues`
    * Format is `User`
    * `Multiple values` must be `true`
2. **Pull Request Targeted Branches**
    * Type of related object is `Issues`
    * Format is `List`
    * `Multiple values` must be `true`
    * Enter a placeholder in `Possible Values` (The possible and actual values will
    be controlled by this Plugin since it can become cumbersome to take care of all 
    possible targeted Branches)
3. **User's Github Login Name**
    * Type of related object is `Users`
    * Format is `Text`
    * You can add the Regexp Validation that matches a valid Github User names: 
    `^[a-zA-Z\d](?:[a-zA-Z\d]|-(?=[a-zA-Z\d])){0,38}$` - 
    [Thanks to shinnn](https://github.com/shinnn/github-username-regex)
    * Make the field `Visible` and `Editable` so that Users can update their
    profile with their Github Login name by themselves

### Setting up the plugin
| Setting | Description |
| ------- | ----------- |
| **Issue ID Scan Pattern** | Enter a valid Ruby Regexp that can scan for a numeric ID within your Pull Request naming pattern. It must contain one matching group. Pre-filled with `^task[ _\-](\d+).*$` (Matching is case-insensitive) - this would match Titles like "Task-123, adds tests", "Task 321 removes tests" etc. |
| **Github Webhook API Secret** | Ensure that you are using the same value here as you do in your Github Repo Settings. |
| **Custom Field for User's Github Login name** | Link the custom field you have created earlier for `User's Github Login Name` |
| **Custom Field for PR Reviewers** | Link the custom field you have created earlier for  `Pull Request Reviewers` |
| **Custom Field for list of Targeted Branches** | Link the custom field you have created earlier for `Pull Request Targeted Branches` |

### Setting up the Webhook on Github
Head over to the Settings page of your Repo on Github and set up a Webhook which 
listens to events of `Pull Requests`. Enter your domain plus the relative part of 
`/github_webhooks/`, so that the URL looks like 
`https://redmine.foo.bar/github_webhooks/`.
