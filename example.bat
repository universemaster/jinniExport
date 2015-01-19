@echo off
cmd /k node_modules\.bin\casperjs.cmd app.coffee --username=bob --password=abc123 --file=jinniRatings.json
cmd /k node_modules\.bin\casperjs.cmd extractWishList.coffee --username=bob --password=abc123 --file=jinniWishList.json
pause