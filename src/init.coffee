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
if not _.isNumber configuration.redis?.expire_min
  console.error 'redis must be configured with a expire_min number field in config.json. ex : "redis":{"expire_min":60"}'
  process.exit 1
if not _.isNumber(configuration.serv.port)
  console.error 'A server port must be specified in config.json file, in "serv.port" '
  process.exit 1

if configuration.serv.disableAuth and not configuration.serv.debug
    console.warn("WARNING : Impossible to disable authentification in non debug mode.")
    configuration.serv.disableAuth = false

if not configuration.applications then console.warn 'Should have an "application" property with registered applications.'


for prjName,project of configuration.projects
  checkPermission("#{configuration.serv.baseDir}#{project.rootDir}",5,(error,answ)->
    if not answ
      console.error "Process #{process.id} has not read and execute file permissions for project #{prjName}, directory #{base}#{project.rootDir}."
      console.error "Execution permission are necessary to enter a directory."
      console.error error
      process.exit 1
  )

console.log("media-node : Server init successful")
