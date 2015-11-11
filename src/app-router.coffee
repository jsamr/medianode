m              = require('./methods')
sec            = require("./security")
Router         = require('router')
bodyParser     = require("body-parser")
configuration  = require("../config.json")
express        = require("express")

expressRouter=express()

appRouter=Router()



if not (configuration.serv.disableAuth and configuration.serv.debug)
  expressRouter.post('/auth/c/:application',bodyParser.urlencoded({extended:false}) , sec.authWithCredentials)
  expressRouter.post('/auth/t/:application',bodyParser.urlencoded({extended:false})  ,  sec.authWithToken)

expressRouter.all('*',sec.cors)
expressRouter.all(/\/[mi]\/.*/,sec.checkQuery,sec.checkApp,sec.checkToken)

expressRouter.get('/status', m.flushSvgStatus )

expressRouter.get('/m/:project_acronym/:exp_name/:place',m.checkProject,m.findMedia  )

expressRouter.get('/i/:project_acronym/',m.checkProject, m.flushProject )

expressRouter.get('/i/:project_acronym/:exp_name',m.checkProject,m.checkExp, m.flushPlaces )



module.exports=expressRouter