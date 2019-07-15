# API documentation

## Introduction

The ODIE API provides a read-only interface to metadata about tweets being watched by ODIE. Specifically, it lets users find out:
* which media sources were monitored in a given data ingestion run;
* what elasticsearch indexes were used to store data from those runs;
* additional metadata about the configuration of these data ingestion runs.

It does *not*:
* directly provide tweet data; this should be fetched from elasticsearch.
* guarantee the existence of elasticsearch data (older indexes may be periodically deleted).
* Allow for media sources and data ingestion runs to be configured; this should be done by administrators through the ODIE admin site.

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
  -X GET http://localhost:3000/data_sets/1.json \
  -b cookie
```

## Errors

## Resources

### Media Source
This is an object representing a media source of interest.

**Endpoints**
```
GET /media_sources
GET /media_sources/:id
```

`GET /media_sources` returns a list of all `media_sources` which were monitored in the last data collection run.

**Attributes**
`:id`: integer
`:description`: text
`:name`: string
`:url`: string
`:latest_index`: string; the name of the elasticsearch index which contains the most recently collected set of user tweets.

Note that the tweets in the latest index do not necessarily refer to the media source itself; they are recent tweets, about anything, by a sample of users who at some point during the data collection run referred to this media source.

**Example**
```
{
  "data": {
    "id": "3",
    "type": "media_sources",
    "attributes": {
      "description": "The free encyclopedia that anyone can edit",
      "name": "Wikipedia",
      "url": "https://en.wikipedia.org/",
      "latest_index": "y578-vnkj-1uh"
    },
  }
}
```
