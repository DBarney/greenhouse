#Greenhouse [![Build Status](https://travis-ci.org/DBarney/greenhouse.svg?branch=master)](https://travis-ci.org/DBarney/greenhouse)

Green house is a small time series database that I am writing for fun to help track the temperature in a small green house that I own. As I don't have the equipment (IoT stuff) to actually do that right now, I'm going to be tracking stats from my machine that I can easily generate.

#Rationale

I really want to explore what it would take to write a time series database that can draw a few graphs for me. I enjoy lua, and I really like how coroutine based lua works inside of the luvi project. Also I am going to be running this on a Raspberry Pi so resources are limited. Mush them all together and you got Greenhouse built from lua on luvi.

##api

The api is going to be very simple.

request | description | response
-|-|-
GET /query?name={"pattern":"info:me.com+count","start":"1h","stop":"now","step":60} | compile a series of data points into something that can be graphed | `{"name":{"points":[0.1,0.2],"count":2\,"min":0.1,"max":0.2}}`
GET /complete/:word | auto complete a word from the set of time series stored in the database | `["word","word2"]`
PUT /metrics | send a set of metrics to green house and have them added to the store | 201 CREATED

##components

Currently there are plans for 2 components in Greenhouse, the first being the data store, and the second being the image api that will cache and generate images for the end client. They will be designed to work together seemlessly.

##failover

None. good luck.

Maybe sometime down the road, if I really feel like it, or if the project evolves beyond what I envision for it.
