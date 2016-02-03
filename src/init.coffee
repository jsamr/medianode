fs           = require "fs"
_            = require "lodash"
os           = require 'os'
configuration= require "../config.json"
Logger       = require "pince"
prefix       = "media-node:init"
logger   = new Logger prefix
permissionLogger   = new Logger "#{prefix}:permissions"

checkPermission = (file, mask, cb) ->
  fs.stat file, (error, stats) ->
    if error
      cb error, false
    else
      cb null, ! !(mask & parseInt((stats.mode & parseInt('777', 8)).toString(8)[0]))


if os.platform() isnt "linux"
  logger.error "Must be run on linux"
  process.exit 1
if not configuration?
  logger.error "Missing config.json file"
  process.exit 1
if not _.isObject(configuration.projects)
  logger.error "Missing or bad projects field in config.json file. Must an object"
  process.exit 1
if not configuration.redis?.socket
  logger.error 'Redis must be configured with a unix socket in config.json. ex : "redis":{"socket":"/tmp/redis.sock""}'
  process.exit 1
if not _.isNumber configuration.redis?.expire_min
  logger.error 'Redis must be configured with a expire_min number field in config.json. ex : "redis":{"expire_min":60"}'
  process.exit 1
if not _.isNumber(configuration.serv.port)
  logger.error 'A server port must be specified in config.json file, in "serv.port" '
  process.exit 1

if configuration.serv.disableAuth and not configuration.serv.debug
    logger.error("Impossible to disable authentification in non debug mode. Switch 'debug' to 'true' in your config file.")
    configuration.serv.disableAuth = false
    process.exit 1

if not configuration.applications then logger.warn 'Should have an "application" property with registered applications.'


for prjName,project of configuration.projects
  checkPermission("#{configuration.serv.baseDir}#{project.rootDir}",4,(error,answ)->
    if not answ
      permissionLogger.error "Process media-node has no read and execute file permissions (r-x, 5) for project #{prjName}, or the folder does not exists. Directory #{configuration.serv.baseDir}#{project.rootDir}."
      permissionLogger.error "Execution permission are necessary to enter a directory."
      permissionLogger.error error
      process.exit 1
  )

logger.info "server init successful"
if _.isString configuration.serv.logLevel
  logger.info "setting log level to #{configuration.srv.logLevel}"
  Logger.setLevel configuration.serv.logLevel
else
  logger.info "setting log level to default : info"
  Logger.setLevel "info"