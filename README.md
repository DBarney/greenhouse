#Greenhouse [![Build Status](https://travis-ci.org/DBarney/greenhouse.svg?branch=master)](https://travis-ci.org/DBarney/greenhouse)

Green house is a small time series database that I am writing for fun to help track the temperature in a small green house that I own. As I don't have the equipment (IoT stuff) to actually do that right now, I'm going to be tracking stats from my machine that I can easily generate.

#Rationale

I really want to explore what it would take to write a time series database that can draw a few graphs for me. I enjoy lua, and I really like how coroutine based lua works inside of the luvi project. Also I am going to be running this on a Raspberry Pi so resources are limited. Mush them all together and you got Greenhouse built from lua on luvi.

##Building

Building is very simple. all that is needed is jualit installed in the greenhouse folder. Then `make` will generate a greenhouse binary.

##Commands

greenhouse exposes two commands currently.

- `greenhouse` will start the server and it will record all stats.
- `greenhouse bed` will start a test client that will send test data to a greenhouse server. This can be used to examine how greenhouse behaves and responds to queries.


##API

The api is going to be very simple.

request | description | response
------- | ----------- | --------
GET /query?load={"pattern":"greenhouse:load","start":"12m","stop":"now","step":12} | query the api for timeseres that match the pattern and tags provided | --json data see below--
GET /complete/:word | auto complete a word from the set of time series stored in the database | `["word","word2"]`
PUT /metrics | send a set of metrics to green house and have them added to the store | 201 CREATED

## Json format for query results

```

curl '127.0.0.1:8080/query?load=\{"pattern":"greenhouse:load","start":"12m","stop":"now","step":12\}' | python -mjson.tool
{
    "load": {
        "count": 3,
        "timeseries": [
            {
                "count": 12,
                "max": 1.5083821614583,
                "min": 1.2403971354167,
                "name": "greenhouse:load5",
                "points": [
                    null,
                    1.397705078125,
                    1.4198404947917,
                    1.40068359375,
                    1.4003092447917,
                    1.5083821614583,
                    1.38818359375,
                    1.3558756510417,
                    1.3076985677083,
                    1.259521484375,
                    1.2403971354167,
                    1.335693359375
                ],
                "tags": {
                    "host": "this.machine"
                }
            },
            {
                "count": 12,
                "max": 1.7506510416667,
                "min": 1.093017578125,
                "name": "greenhouse:load1",
                "points": [
                    null,
                    1.7159423828125,
                    1.613037109375,
                    1.4169921875,
                    1.4867350260417,
                    1.7506510416667,
                    1.2093098958333,
                    1.2239583333333,
                    1.134765625,
                    1.093017578125,
                    1.1350911458333,
                    1.6014811197917
                ],
                "tags": {
                    "host": "this.machine"
                }
            },
            {
                "count": 12,
                "max": 1.5056966145833,
                "min": 1.3697916666667,
                "name": "greenhouse:load15",
                "points": [
                    null,
                    1.4891357421875,
                    1.492431640625,
                    1.47958984375,
                    1.4715983072917,
                    1.5056966145833,
                    1.45849609375,
                    1.439208984375,
                    1.4130859375,
                    1.38720703125,
                    1.3697916666667,
                    1.3946126302083
                ],
                "tags": {
                    "host": "this.machine"
                }
            }
        ]
    }
}
```

##components

Currently there are plans for 2 components in Greenhouse, the first being the data store, and the second being the image api that will cache and generate images for the end client. They will be designed to work together seemlessly.

##failover

None. good luck.

Maybe sometime down the road, if I really feel like it, or if the project evolves beyond what I envision for it.
