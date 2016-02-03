tokens        = require('./tokens')
configuration = require("../config.json")
methods       = require("./methods")
_             = require("lodash")
authHandlers  = require("./auth-handlers")
declared_auth_handlers =configuration.auth_handlers or []

Logger  = require("pince")
prefix = "media-node:app"

class BasicApplication
  revokeClient:(token)-> @_tokens.revoke(token)
  hasPrerogativeForProject:(projectName)-> projectName in @params.projects
  controlClient:(token,res,next)-> @_tokens.registered token,res,next
  clearTokens: ->  @_tokens.clear()
  close : ->
  constructor:(@params,name)->
    @logger=new Logger "#{prefix}:name"
    @_tokens=tokens(name, @)

class AuthApplication extends BasicApplication
  authClient:(credentials,res) -> @_authHandler.attemptAuthClient credentials, res, @
  close : -> try @_authHandler.stop() catch e then @logger.error JSON.stringify e
  constructor : (params,name)->
    super(params,name)
    if params.auth_handler is null
      @logger.error "no auth_handler for application #{name}"
      process.exit 1
    authHConf=params.auth_handler
    if  authHConf.name not in declared_auth_handlers
      @logger.error "auth_handler #{authHConf.name} not declared in config.json"
      process.exit 1
    @_authHandler=authHandlers.load authHConf.name, authHConf.uri, params.options, params.reconnectAfter_s
    if @_authHandler.turnOnline() isnt null then @logger.warning "Could not start auth handler #{name}, will retry later"

applications={}
ApplicationClass = if configuration.serv.disableAuth then BasicApplication  else AuthApplication
for appName,params of configuration.applications
  applications[appName]=new ApplicationClass(params,appName)


module.exports=applications
