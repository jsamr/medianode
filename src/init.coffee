fs           = require("fs")
_            = require("lodash")
os           = require('os')
configuration= require("../config.json")


checkPermission = (file, mask, cb) ->
  fs.stat file, (error, stats) ->
    if error
      cb error, false
    else
      cb null, ! !(mask & parseInt((stats.mode & parseInt('777', 8)).toString(8)[0]))


if os.platform() isnt "linux"
  console.error "Must be run on linux"
  process.exit 1
if not configuration?
  console.error "Missing config.json file"
  process.exit 1
if not _.isObject(configuration.projects)
  console.error "Missing or bad projects field in config.json file. Must an object"
  process.exit 1
if not configuration.redis?.socket
  console.error 'redis must be configured with a unix socket in config.json. ex : "redis":{"socket":"/tmp/redis.sock""}'
  process.exit 1
if not _.isNumber(configuration.port)
  console.error 'A "port" must be specified in config.json file '
  process.exit 1

if not configuration.applications then console.warn 'Should have an "application" property with registered applications.'

for prjName,project of configuration.projects
  checkPermission("#{configuration.baseDir}#{project.rootDir}",5,(error,answ)->
    if not answ
      console.error "Process #{process.id} has not read and execute file permissions for project #{prjName}, directory #{base}#{project.rootDir}."
      console.error "Execution permission are necessary to enter a directory."
      console.error error
      process.exit 1
  )
