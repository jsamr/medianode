require('../lib/redisUtils')
redis         = require("redis")
configuration = require("../config.json")
cleanup       = require("../lib/cleanup")
crypto        = require("crypto")
ErrorCodes    = require("./error-codes")
methods       = require("./methods")
applications  = require("./applications")
redisClient   = redis.createClient(configuration.redis.socket)

tokensPolicy= ->
    if configuration.delTokensOnShutdown
      _.invoke applications, "clearTokens"
      console.info "Flushing tokens out"
    if redisClient then redisClient.quit()

redisClient.on("error", (err)->
  console.error "REDIS CLIENT PROBABLY UNAVAILABLE AT SOCKET #{configuration.redis.socket} "
  console.error err
  process.exit 1
)

cleanup(tokensPolicy)


module.exports=(name)->
  prefix="apps:#{name}:"
  store = (cb) ->
    token = crypto.randomBytes(48).toString('hex')
    redisClient.set(prefix+token, true,'EX', configuration.redis.expire_min*60,'NX',
      (err,rep)-> if rep is 0 and err is null then store(cb) else cb.call(null,err,token))

  registered   :  (token, res, next)    ->
    redisClient.exists(prefix+token,(token,exists)->
      if exists is 1 then next()
      else methods.setErrorCode(res, ErrorCodes.session, 403)
    )
  revoke       :  (token)    -> redisClient.del(prefix+token)
  publish      :  (res) -> store((err,token)->
    if err
      console.error err
      methods.setErrorCode(res,ErrorCodes.redis)
    else
      res.setHeader 'Content-Type', 'application/json'
      res.setHeader "Access-Control-Allow-Origin", '*'
      res.setHeader "Access-Control-Allow-Methods", "GET, POST"
      authentification={
        epoch:new Date()/1000
        token:token
      }
      console.log token
      res.end(JSON.stringify authentification)
  )
  clear : -> redisClient.delPattern "#{prefix}*"



