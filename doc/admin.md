# Admin documentation

The following pages are available, with their usual meanings:
`/search_queries`
`/search_queries/new`
`/search_queries/(:id)`
`/cohort_collectors`
`/cohort_collectors/new`
`/cohort_collectors/(:id)`

They are restricted to administrators.

## Additional information on SearchQuery

You don't need to fill in the `keyword` field; it will be automatically
generated from the URL you provide.

This is the term that will actually be used to search Twitter. It should be just
the domain part of the URL. This is important because links to a given media
site may appear in many different formats (e.g. with and without `www`), and we
want to use a search term that is most likely to capture all of these
possibilities.

If you find that the generated keyword is not accurately finding the content you
want, you can override it through the rails console. The web site does not
currently allow for that.

## Additional information on CohortCollector

The `/cohort_collectors/(:id)` page also allows you to:
* kick off a streaming twitter data collection run for that cohort collector
* create a cohort based on the last completed twitter data collection run

# Not yet implemented
* Tweets will be filtered on the `expanded_url` field using this keyword, to (almost) ensure that the tweet actually links to the media source, rather than merely referencing it in the text.
* It will be possible to configure a different number of accounts to be monitored for each media source. (Right now they share a default number.)
* Information about data collection from previous runs.
* The option to set the time period over which analysis is occurring (weekly, monthly) -- this _may not be implementable_ due to limitations of Twitter's API.
