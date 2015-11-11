tokens        = require('./tokens')
configuration = require("../config.json")
methods       = require("./methods")
ErrorCodes    = require("./error-codes")
_             = require("lodash")
authHandlers  = require("./auth-handlers")
cleanup       = require("../lib/cleanup")
declared_auth_handlers =configuration.auth_handlers or []
sessionHash=null



class BasicApplication
  revokeClient:(token)-> @_tokens.revoke(token)
  hasPrerogativeForProject:(projectName)-> projectName in @params.projects
  controlClient:(token,res,next)-> @_tokens.registered token,res,next
  clearTokens: ->  @_tokens.clear()
  close : ->
  constructor:(@params,name)-> @_tokens=tokens(name, @)

class AuthApplication extends BasicApplication
  authClient:(credentials,res) -> @_authHandler.attemptAuthClient credentials, res, @
  close : -> try @_authHandler.stop() catch e
  constructor : (params,name)->
    super(params,name)
    if params.auth_handler is null
      console.error "no auth_handler for application #{name}"
      process.exit 1
    authHConf=params.auth_handler
    if  authHConf.name not in declared_auth_handlers
      console.error "auth_handler #{authHConf.name} not declared in config.json"
      process.exit 1
    @_authHandler=authHandlers.load(authHConf.name,authHConf.uri ,params.options,params.reconnectAfter_s)
    if @_authHandler.turnOnline() isnt null then console.warning "Could not start auth handler #{name}, will retry later"

applications={}
ApplicationClass = if configuration.serv.disableAuth then BasicApplication  else AuthApplication
for appName,params of configuration.applications
  console.log(_.isFunction(ApplicationClass))
  applications[appName]=new ApplicationClass(params,appName)


module.exports=applications
