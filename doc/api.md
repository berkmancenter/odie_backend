# API documentation

## Introduction

The ODIE API provides a read-only interface to metadata about tweets being
watched by ODIE. Specifically, it lets users find out:
* which sets of Twitter users were monitored in a given data ingestion run;
* aggregated metadata about their tweets; and
* what elasticsearch indexes were used to store data from those runs.

It does *not*:
* directly provide tweet data; this should be fetched from elasticsearch.
* guarantee the existence of elasticsearch data (older indexes may be
  periodically deleted).
* Allow for queries and data ingestion runs to be configured; this should be
  done by administrators through the ODIE admin site.

## Authentication

Authentication is via user/password. See [Devise](https://github.com/plataformatec/devise) documentation for details.

**Example**
Get cookie:
```
curl -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -X POST http://localhost:3000/users/sign_in \
  -d '{"user": {"email": "api@example.com", "password": "password"}}' \
  -c cookie
```

Use cookie to fetch data:
```
curl -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -X GET http://localhost:3000/media_sources/1.json \
  -b cookie
```

## Errors

## Resources

### Cohort
This is an object representing a set of Twitter users.

**Endpoints**
```
GET /cohorts
GET /cohorts/:id
GET /cohorts/?ids[]=1&ids[]=2
```

Respectively, these are:
* all known `cohorts`
* a given cohort, and the data from its last data collection run;
* all cohorts with the given IDs, and aggregated data across all their most
  recent data collection runs.

**Example**
```
{
  "data": {
    "id": "2",
    "type": "cohort",
    "attributes": {
      "description": "BKC",
      "latest_data": {
        "data": {
          "id": "12",
          "type": "data_set",
          "attributes": {
            "num_users": 1,
            "num_tweets": 50,
            "num_retweets": 24,
            "index_name": "2_3c39c0ec-8965-483e-9a6b-0e0755c733dc",
            "hashtags": {},
            "top_mentions": {
              "BKCHarvard": "22",
              "draganakaurin": "6",
              "JasmineMcNealy": "5"
            },
            "top_retweets": {},
            "top_sources": {
              "bit.ly": "16",
              "medium.com": "6",
              "twitter.com": "11"
            },
            "top_urls": {},
            "top_words": {
              "-": "6",
              "bkc": "6",
              "can": "6",
              "new": "6",
              "today": "5",
              "@bkcharvard": "5"
            }
          }
        }
      }
    }
  }
}
```

`latest_data` serializes the DataSet from the most recent data collection run
for a given Cohort. Its `attributes` are calculated from the data stored in
Elasticsearch or retrieved during tweet collection.
* `index_name` is the name of an Elasticsearch index specific to this DataSet.
* The `num_x` are counts of the number of distinct objects of the indicated type
  in the data set.
* `hashtags`, and the various `top_x` are hashes whose keys are the indicated
  data, and whose values are the number of times that item appeared in the data
  set.
  * There is a threshold value below which data will not be returned (defaults to 5).
  * `hashtags` do not include the `#` character.
  * `top_mentions` do not include the `@` character.
  * `top_words` is a naive count which filters out stopwords using a
    language-specific filter (and also the term `RT`), but which does not
    perform stemmatization or lemmatization.
  * `top_urls` omits the querystring component of the URL before counting. This
    should enable it to collate URLs which represent the same destination with
    different social media tracking garbage at the end (`fbclid`, `utm_source`,
    etc.). Sometimes this may have discarded meaningful data, though.

When fetching data for multiple cohorts:
* The `data` element will contain a list of hashes of the same format as the
  hash in the `data` element above.
* There will also be an `aggregates` element which aggregates data across all
  cohorts in the set, again throwing out anything below a given threshold. It
  will be identical in format to the `latest_data.attributes` hash above.
