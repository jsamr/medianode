CacheClient   = require('redis-cache-client')
configuration = require("./build-config")
redis         = require("redis")

cache=CacheClient({
  client:redis.createClient(configuration.redis.socket)
  prefix:'core:paths'
})

module.exports={
  fetch:(path,callback)-> cache.get(path,callback)
  save:(path,syspath,callback)-> cache.set(path,syspath,(callback or ->))
}