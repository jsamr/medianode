require('./init')
finalhandler = require('finalhandler')
http         = require('http')
configuration= require("../config.json")
appRouter    = require("./app-router")



server=http.createServer (req,res)-> appRouter(req,res,finalhandler(req,res,{
  message:configuration.debug
}))

server.listen(configuration.port)