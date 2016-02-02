crypto       = require('crypto')
configuration= require("../config.json")
ErrorCodes   = require("./error-codes")
methods      = require("./methods")
_            = require("lodash")
applications = require("./applications")

security={

  cors: (req,res,next) ->
      res.setHeader "Access-Control-Allow-Origin", '*'
      res.setHeader "Access-Control-Allow-Methods", "GET, POST"
      next()

  checkQuery:(req,res,next) ->
    if req.query?.a is undefined
      methods.setErrorCode(res,ErrorCodes.query,422)
      return
    else next()

  checkApp: (req,res,next) ->
    application=applications[req.query.a]
    if application is undefined
      methods.setErrorCode(res, ErrorCodes.application, 403)
      return
    else
      req.application=application
      next()
  checkToken:(req,res,next) -> req.application.controlClient req.query.t, res, next
}

if not configuration.serv.disableAuth

  security.authWithCredentials = (req,res)=>
    application=applications[req.params.application]
    if application is undefined
      methods.setErrorCode(res,ErrorCodes.application,403)
      return
    application.authClient(req.body,res)

  security.authWithToken = (req,res) ->
    application=applications[req.params.application]
    if application is undefined
      methods.setErrorCode(res,ErrorCodes.application,403)
      return
    if req.body.token is undefined
      methods.setErrorCode(res,ErrorCodes.query,422)
      return
    application.controlClient(req.body.token, res)







module.exports=security