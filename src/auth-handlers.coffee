authHandlerDir="../auth_handlers/"
ErrorCodes = require("./error-codes")
methods = require("./methods")
_       = require("lodash")
Logger  = require("pince")
prefix = "media-node:auth-handlers"
loaderLogger = new Logger "#{prefix}:loader"
logger = new Logger prefix
handlerRequiredMethods=["assertCredentials","authClientASync"]
RECONNECT_AFTER_S_DEFAULT=6000

optional= (lib)->
  out=null
  try out=require(lib)
  catch e then loaderLogger.warn e
  out

assertHandlerHasExpectedSignature = (handler,name) ->
  if _.intersection(Object.keys(handler),handlerRequiredMethods).length!=2
    loaderLogger.error "handler #{name} must EXACTLY have the following methods defined : #{JSON.stringify handlerRequiredMethods}"
    process.exit 1
  if not _.every _.values(handler), _.isFunction
    loaderLogger.error "handler #{name} : all fields must be functions! : #{JSON.stringify handlerRequiredMethods}"
    process.exit 1

authHandlerPrototype=
  lastConnectAttempt_epoch:null
  reconnectAfter_s : RECONNECT_AFTER_S_DEFAULT

  authClient: (credentials, res, app) ->
    credentialsValid = @assertCredentials(credentials)
    if not credentialsValid then methods.setErrorCode res,ErrorCodes.auth_handler_credentials,422, null, @logger
    else
      @authClientASync(credentials).then (success) =>
          if success then app._tokens.publish(res)
          else methods.setErrorCode res, ErrorCodes.auth_failure, 403, null, @logger
        .catch (err) =>
          logger.error err
          methods.setErrorCode res, ErrorCodes.auth_handler_error, 500, null, @logger

  attemptAuthClient : (credentials, res, app) -> @authClient credentials,res,app

module.exports = {
  load:(moduleName,uri,options,reconnectAfter_s)->
    module=optional("#{authHandlerDir}#{moduleName}")
    handler=null
    if module is null
      loaderLogger.warn "handler #{moduleName} npm module does not exists in path #{authHandlerDir}#{moduleName} "
      process.exit 1
    if not _.isFunction(module)
      loaderLogger.error "handler #{moduleName} npm module must export a function"
      process.exit 1
    try  handler=module(uri,options)
    catch e
      loaderLogger.error "auth_handler #{moduleName} npm module encountered an error while loading"
      loaderLogger.error  e
      process.exit 1
    # Inherits from authHandlerPrototype
    assertHandlerHasExpectedSignature(handler,moduleName)
    handler.logger=new Logger("#{prefix}:#{moduleName}")
    fullHandler=_.create(authHandlerPrototype, handler)
    if reconnectAfter_s then fullHandler.reconnectAfter_s=reconnectAfter_s
    fullHandler
}