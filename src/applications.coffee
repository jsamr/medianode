tokens        = require('./tokens')
configuration = require("../config.json")
methods       = require("./methods")
ErrorCodes    = require("./error-codes")
_             = require("lodash")

auth_handlers =configuration.auth_handlers
sessionHash=null

optional= (lib)->
  out=null
  try
    out=require(lib)
  catch e then console.log e
  out


authHandlerDir="../auth_handlers/"


class Application
  authClient: (res,credentials) ->
    authSuccess=@_authHandler.authsync(credentials)
    if authSuccess then @_tokens.publish(res)
    else methods.setErrorCode(res,ErrorCodes.auth_failure,403)

  revokeClient:(token)-> @_tokens.revoke(token)

  controlClient:(token,res,next)-> @_tokens.registered token,res,next

  clearTokens: ->  @_tokens.clear()

  constructor:(params,name)->
    if params.auth_handler is null
      console.error "no auth_handler for application #{name}"
      process.exit 1
    auth_handler=params.auth_handler
    if  auth_handler.name not in auth_handlers
      console.error "auth_handler #{auth_handler.name} not declared in config.json"
      process.exit 1
    authModule=optional("#{authHandlerDir}#{auth_handler.name}")
    if authModule is null
      console.error "auth_handler #{auth_handler.name} npm module does not exists in path #{authHandlerDir}#{auth_handler.name} "
      process.exit 1
    if not _.isFunction(authModule)
      console.error "auth_handler #{auth_handler.name} npm module should export a function"
      process.exit 1
    @_authHandler=authModule(auth_handler.uri,params.options)
    @_tokens=tokens(name, @)



applications={}
for appName,params of configuration.applications
  applications[appName]=new Application(params,appName)

module.exports=applications
