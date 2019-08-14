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

`GET /media_sources` returns a serialization of all `media_sources` which were monitored in the last data collection run.

**Example**
```
{
	"data": {
		"id": "3",
		"type": "media_source",
		"attributes": {
			"description": "Democracy dies in darkness",
			"name": "Washington Post",
			"url": "www.washingtonpost.com",
			"latest_data": {
				"data": {
					"id": "3",
					"type": "data_set",
					"attributes": {
						"num_users": 7,
						"num_tweets": 350,
						"num_retweets": 273,
						"index_name": "3_54572fe1-8ed2-490b-87b3-2ff6dcd4d2c8",
						"hashtags": {
							"GIF": "1",
							"WW2": "1",
							"LOVE": "1",
							"MAGA": "1",
							"QAnon": "1",
						}
					}
				}
			}
		}
	}
}
```

`latest_data` serializes the DataSet from the most recent data collection run for a given media source. Its `attributes` are calculated from the data stored in Elasticsearch. `index_name` is the name of an Elasticsearch index specific to this DataSet. `hashtags` is a hash whose keys are hashtags, and whose values are the number of times that hashtag appeared in the data set.
