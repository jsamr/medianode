Logger        = require 'pince'
# FAST AND DIRTY FIX TO https://github.com/mad-eye/pince/issues/12
Logger.prototype.error=(message)-> console.error "#{new Date} error:  [#{@name}]  #{message}"
require('./init')
finalhandler  = require('finalhandler')
http          = require('http')
configuration = require("./build-config")
appRouter     = require("./app-router")



server=http.createServer (req,res)-> appRouter(req,res,finalhandler(req,res,{
  message:configuration.serv.debug
}))

server.listen(configuration.serv.port)