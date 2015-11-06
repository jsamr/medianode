m            = require('./methods')
sec          = require("./security")
Router       = require('router')
bodyParser   = require("body-parser")
configuration   = require("../config.json")
express        = require("express")

expressRouter=express()

appRouter=Router()

dummyMiddleware=(req,res,next) -> next()

checkToken=dummyMiddleware

if not (configuration.disableAuth and configuration.debug)
  expressRouter.post('/auth/:application',bodyParser.urlencoded({extended:false,parameterLimit:3}) , sec.auth)
  checkToken=sec.allow

expressRouter.all('*',sec.cors)
expressRouter.all(/\/[vi]\/.*/,checkToken)

expressRouter.get('/status', m.flushSvgStatus )

expressRouter.get('/m/:project_acronym/:exp_name/:place',m.checkProject,m.findMedia  )

expressRouter.get('/i/:project_acronym/', m.checkProject, m.flushProject )

expressRouter.get('/i/:project_acronym/:exp_name',m.checkProject, m.checkExp, m.flushPlaces )



module.exports=expressRouter