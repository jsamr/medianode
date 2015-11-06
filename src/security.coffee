crypto       = require('crypto')
configuration= require("../config.json")
ErrorCodes   = require("./error-codes")
methods      = require("./methods")
_            = require("lodash")
applications = require("./applications")

security={

  cors: (req,res,next) ->
      console.log "setting cors"
      res.setHeader "Access-Control-Allow-Origin", '*'
      res.setHeader "Access-Control-Allow-Methods", "GET, POST"
      next()


}

if not (configuration.disableAuth and configuration.debug)
  applications = require("./applications")

  security.auth = (req,res)=>
    application=applications[req.params.application]
    if application is undefined
      methods.setErrorCode(res,ErrorCodes.application,403)
      return
    application.authClient(res,req.body)

  security.allow = (req,res,next) ->
    if req.query?.a is undefined
      methods.setErrorCode(res,ErrorCodes.query,422)
      return
    token = req.query.t
    if token is undefined
      methods.setErrorCode(res,ErrorCodes.query,422)
      return
    application=applications[req.query.a]
    if application is undefined
      methods.setErrorCode(res, ErrorCodes.application, 403)
      return
    application.controlClient(token, res, next)


module.exports=security