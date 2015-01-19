#!/bin/bash
node_modules/.bin/casperjs app.coffee --username=bob --password=abc123 --file=jinniRatings.json
node_modules/.bin/casperjs extractWishList.coffee --username=bob --password=abc123 --file=jinniWishList.json
