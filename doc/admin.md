# Admin documentation

## Accessing the admin site
When you log in with your admin account, you will be redirected to `/admin`.

## Managing media sources
At `/admin/media_sources` (also accessible via the sidebar menu at `/admin`), you can create and edit media sources.

### A note on the `keyword` field
You don't need to fill in the `keyword` field; it will be automatically generated from the URL you provide.

This is the term that will actually be used to search Twitter. It should be just the domain part of the URL. This is important because links to a given media site may appear in many different formats (e.g. with and without `www`), and we want to use a search term that is most likely to capture all of these possibilities.

If you find that the generated keyword is not accurately finding the content you want, you can override it.

__Not yet implemented__:
* Tweets will be filtered on the `expanded_url` field using this keyword, to (almost) ensure that the tweet actually links to the media source, rather than merely referencing it in the text.
* It will be possible to configure a different number of accounts to be monitored for each media source. (Right now they share a default number.)

## Data collection runs
All of the `active` media sources will be included in the data set for the next tweet collection run.

__Not yet implemented__:
* Features to view the configuration for the next data collection run and kick it off.
* Information about data collection from previous runs.
* The option to set the time period over which analysis is occurring (weekly, monthly) -- this _may not be implementable_ due to limitations of Twitter's API.
