require('../lib/redisUtils')
redis         = require("redis")
configuration = require("./build-config")
cleanup       = require("../lib/cleanup")
crypto        = require("crypto")
ErrorCodes    = require("./error-codes")
methods       = require("./methods")
applications  = require("./applications")
_             = require("lodash")
Logger  = require("pince")
prefix = "media-node:redis"
appLogger   = new Logger "media-node"
redisLogger = new Logger prefix
tokenLogger = new Logger "#{prefix}:tokens"
redisClient   = redis.createClient(configuration.redis.socket)
DEFAULT_TOKEN_SIZE=32

setHeaders=(res)->
  res.setHeader "Access-Control-Allow-Origin", '*'
  res.setHeader "Access-Control-Allow-Methods", "GET, POST"


cleanupCode= ->
    if configuration.serv.delTokensOnShutdown
      _.invoke applications, "clearTokens"
      redisLogger.info "Flushing tokens out from redis"
    if redisClient
      redisLogger.info("Quitting redis client")
      redisClient.quit()
    appLogger.info "Closing applications"
    _.invoke applications, "close"

redisClient.on("error", (err)->
  redisLogger.error "REDIS CLIENT PROBABLY UNAVAILABLE AT SOCKET #{configuration.redis.socket} "
  redisLogger.error JSON.stringify err
  process.exit 1
)

cleanup(cleanupCode)


module.exports=(name)->
  prefix="apps:#{name}:"
  store = (cb) ->
    token = crypto.randomBytes(DEFAULT_TOKEN_SIZE).toString('hex')
    redisClient.set(prefix+token, true,'EX', configuration.redis.expire_min*60,'NX',
      (err,rep)-> if rep is 0 and err is null then store(cb) else cb.call(null,err,token))

  registered   :  (token, res, next)    ->
    redisClient.exists(prefix+token,(err,exists)->
      if err
        redisLogger.error JSON.stringify err
        methods.setErrorCode res, ErrorCodes.redis, 500, null, redisLogger
        return
      if exists is 1
        if next then next()
        else
          setHeaders(res)
          res.end()
      else methods.setErrorCode res, ErrorCodes.session, 403, null, tokenLogger
    )
  revoke       :  (token)    -> redisClient.del(prefix+token)
  publish      :  (res) -> store((err,token)->
      if err
        redisLogger.error JSON.stringify err
        methods.setErrorCode res,ErrorCodes.redis, null, redisLogger
      else
        res.setHeader 'Content-Type', 'application/json'
        setHeaders(res)
        authentification={
          epoch_s:new Date()/1000+configuration.redis.expire_min*60
          token:token
        }
        tokenLogger.debug "Generating token #{token}"
        res.end(JSON.stringify authentification)
  )
  clear : -> redisClient.delPattern "#{prefix}*"



