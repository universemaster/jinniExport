@echo off
cmd /k node_modules\.bin\casperjs.cmd app.coffee --username=bob --password=abc123 --file=jinni.json
pause