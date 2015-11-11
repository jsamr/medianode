authHandlerDir="../auth_handlers/"
ErrorCodes = require("./error-codes")
methods = require("./methods")
_       = require("lodash")
handlerRequiredMethods=["assertCredentials","start","stop","authClientSync"]
RECONNECT_AFTER_S_DEFAULT=6000
States={
  OFFLINE:{}
  ONLINE:{}
}

getCurrentEpoch_s=()->(new Date()).getTime()/1000

optional= (lib)->
  out=null
  try
    out=require(lib)
  catch e then console.warn e
  out

assertHandlerHasExpectedSignature = (handler,name) ->
  if _.intersection(Object.keys(handler),handlerRequiredMethods).length!=4
    console.error "Error loading handler #{name}, must EXACTLY have the following methods defined :"
    console.error handlerRequiredMethods
    process.exit 1
  if not _.every _.values(handler), _.isFunction
    console.error "Error loading handler #{name}, all fields must be functions! :"
    console.error handlerRequiredMethods
    process.exit 1

authHandlerPrototype=
  lastConnectAttempt_epoch:null
  state  : States.OFFLINE
  reconnectAfter_s : RECONNECT_AFTER_S_DEFAULT
  turnOffline:(res) ->
    @state=States.OFFLINE
    @lastConnectAttempt_epoch=getCurrentEpoch_s()
    try @stop()
    catch e
    methods.setErrorCode(res,ErrorCodes.auth_handler_error,500)
  turnOnline:()->
    error=null
    try @start()
    catch e then error=e
    if error is null then @state=States.ONLINE
    error
  shouldReconnect: -> getCurrentEpoch_s()-@lastConnectAttempt_epoch>=@reconnectAfter_s
  authClient: (credentials, res, app) ->
    error = null
    success = false
    credentialsValid = @assertCredentials(credentials)
    if not credentialsValid then methods.setErrorCode(res,ErrorCodes.auth_handler_credentials,422)
    else
      try success = @authClientSync(credentials)
      catch e then error = e
      if error isnt null then @turnOffline(res)
      else
        if success then app._tokens.publish(res)
        else methods.setErrorCode(res,ErrorCodes.auth_failure,403)

  attemptAuthClient : (credentials, res, app) ->
    if @state is States.ONLINE then @authClient credentials,res,app
    else
      if @shouldReconnect()
        if @turnOnline() isnt null then @turnOffline(res)
        else @authClient credentials,res, app
      else methods.setErrorCode(res,ErrorCodes.auth_handler_error,500)

module.exports = {
  load:(moduleName,uri,options,reconnectAfter_s)->
    module=optional("#{authHandlerDir}#{moduleName}")
    handler=null
    if module is null
      console.error "auth_handler #{auth_handler.name} npm module does not exists in path #{authHandlerDir}#{auth_handler.name} "
      process.exit 1
    if not _.isFunction(module)
      console.error "auth_handler #{auth_handler.name} npm module should export a function"
      process.exit 1
    try  handler=module(uri,options)
    catch e
      console.error "auth_handler #{auth_handler.name} npm module encountered an error while loading"
      console.error e
      process.exit 1
    # Inherits from authHandlerPrototype
    assertHandlerHasExpectedSignature(handler,moduleName)
    fullHandler=_.create(authHandlerPrototype, handler)
    if reconnectAfter_s then fullHandler.reconnectAfter_s=reconnectAfter_s
    fullHandler
}