require('../lib/redisUtils')
redis         = require("redis")
configuration = require("../config.json")
cleanup       = require("../lib/cleanup")
crypto        = require("crypto")
ErrorCodes    = require("./error-codes")
methods       = require("./methods")
applications  = require("./applications")
_             = require("lodash")

redisClient   = redis.createClient(configuration.redis.socket)
DEFAULT_TOKEN_SIZE=32

setHeaders=(res)->
  res.setHeader "Access-Control-Allow-Origin", '*'
  res.setHeader "Access-Control-Allow-Methods", "GET, POST"


cleanupCode= ->
    if configuration.serv.delTokensOnShutdown
      _.invoke applications, "clearTokens"
      console.info "Flushing tokens out from redis"
    if redisClient
      console.log("Quitting redis client")
      redisClient.quit()
    console.log "Closing applications"
    _.invoke applications, "close"

redisClient.on("error", (err)->
  console.error "REDIS CLIENT PROBABLY UNAVAILABLE AT SOCKET #{configuration.redis.socket} "
  console.error err
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
    console.log(token)
    redisClient.exists(prefix+token,(err,exists)->
      console.log exists
      if exists is 1
        if next then next()
        else
          setHeaders(res)
          res.end()
      else methods.setErrorCode(res, ErrorCodes.session, 403)
    )
  revoke       :  (token)    -> redisClient.del(prefix+token)
  publish      :  (res) -> store((err,token)->
      if err
        console.error err
        methods.setErrorCode(res,ErrorCodes.redis)
      else
        res.setHeader 'Content-Type', 'application/json'
        setHeaders(res)
        authentification={
          epoch:new Date()/1000
          token:token
        }
        if(configuration.serv.log) then console.log("Generating token #{token}")
        res.end(JSON.stringify authentification)
  )
  clear : -> redisClient.delPattern "#{prefix}*"



