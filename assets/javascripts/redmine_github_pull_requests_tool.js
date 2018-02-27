function showAllPullRequests() {
    $('.pull-requests-list').show();
    Cookies.set('pull_request_display', 'show');
}

function hideAllPullRequests() {
    $('.pull-requests-list').hide();
    Cookies.set('pull_request_display', 'hide');
}
