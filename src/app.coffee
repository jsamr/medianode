finalhandler = require('finalhandler')
http         = require('http')
path         = require("path")
Router       = require('router')
crypto       = require('crypto')
fs           = require("fs")
vidStreamer  = require("../lib/vidStreamer")
configuration= require("../config.json")
bodyParser   = require("body-parser")
_            = require("lodash")
Finder       = require('fs-finder')
os           = require('os')


ErrorCodes={
  project:"PROJECT_NOT_CONFIGURED"
  rootNotConfigured:"PROJECT_ROOT_MISSING"
  unauthorized:"UNAUTHORIZED_CLIENT"
  root:"ROOT_DIR_NOT_FOUND"
  exp:"EXP_DIR_NOT_FOUND"
  place:"PLACE_DIR_NOT_FOUND"
  media:"MEDIA_NOT_FOUND"
}

checkPermission = (file, mask, cb) ->
  fs.stat file, (error, stats) ->
    if error
      cb error, false
    else
      cb null, ! !(mask & parseInt((stats.mode & parseInt('777', 8)).toString(8)[0]))


setErrorCode=(res,msg,error=false)->
  res.setHeader 'Content-Type','application/json'
  res.status=if error then error else 200
  res.end(JSON.stringify(msg))
  true

if os.platform() isnt "linux"
  console.error "Must be run on linux"
  process.exit 1
if not configuration?
  console.error "Missing config.json file"
  process.exit 1
if not _.isObject(configuration.projects)
  console.error "Missing or bad projects field in config.json file. Must an object"
  process.exit 1


base=configuration.baseDir

if not base then console.error "Missing baseDir property in config.json file" and exit 1
if not base.substr(base.length-1) is "/" then base="#{base}/"
for prjName,project of configuration.projects
  checkPermission("#{base}#{project.rootDir}",5,(error,answ)->
    if not answ
      console.error "Process #{process.id} has not read and execute file permissions for project #{prjName}, directory #{base}#{project.rootDir}."
      console.error "Execution permission are necessary to enter a directory."
      console.error error
      process.exit 1
  )

logUnauthorized=(req,msg)->
  console.warn msg
  console.warn "HEADERS:"
  console.warn req.headers
  console.warn "REMOTE IP: #{req.headers['x-forwarded-for'] or
      req.connection.remoteAddress or
      req.socket.remoteAddress or
      req.connection.socket.remoteAddress}"

crossDomainOriginPolicy=(req,res,next) ->
  console.log req.headers
  if configuration.secure
    ref =  req.headers.referer
    match = (_.find configuration.crossOriginDomains, (domain)-> ref.match("#{domain}*")) if ref
    if match
      res.setHeader "Access-Control-Allow-Origin", match
      res.setHeader "Access-Control-Allow-Methods", "GET, POST"
      next()
    else
      if ref then logUnauthorized req, "UNAUTHORIZED REFERER : #{ref} ATTEMPTED TO CONNECT"
      else logUnauthorized req,"NON-ORIGINATED ATTEMPT TO CONNECT FROM CLIENT :"
      setErrorCode(res,ErrorCodes.unauthorized,403)
  else
    res.setHeader "Access-Control-Allow-Origin", "*"
    res.setHeader "Access-Control-Allow-Methods", "GET, POST"
    next()

router=Router()

router.use(crossDomainOriginPolicy)

router.get('/status',(req,res)->
  file=path.join(process.cwd(),'public/status-ok.svg')
  res.setHeader 'Content-Type','image/svg+xml'
  fs.createReadStream(file).pipe(res)
)

checkProject=(req,res,next)->
  opts=req.params
  projectConf=configuration.projects[opts.project_acronym]
  if projectConf is undefined
    setErrorCode(res,ErrorCodes.project,500)
    return
  if projectConf.rootDir is undefined
    setErrorCode(res,ErrorCodes.rootNotConfigured,500)
    return
  if configuration.secure then console.log ""

  rootPath=Finder.from(base).findDirectory(projectConf.rootDir)
  req.projectConfig=projectConf
  req.projectDir=rootPath
  next()

scanExp=(req,res,next)->
  if req.projectDir is null
    setErrorCode res, ErrorCodes.root
    return
  opts=req.params
  projectConf=req.projectConfig
  expDir= Finder.from(req.projectDir).findDirectory("#{projectConf.expRegex or ''}#{opts.exp_name}")
  if expDir is null
    setErrorCode res, ErrorCodes.exp
    return
  mediaDir= if projectConf.mediaDir not in ["",undefined,null] then "#{projectConf.mediaDir}/" else ""
  places=Finder.from(expDir).findDirectories("#{mediaDir}*").map (absolute)->absolute.replace("#{expDir}/#{mediaDir}","")
  req.expPlaces={
    places:places
  }
  next()

findVideo=(req,res,next)->
  if req.projectDir is null
    setErrorCode(res,ErrorCodes.root,404)
    return
  opts=req.params
  projectConf=req.projectConfig
  expDir= Finder.from(req.projectDir).findDirectory("#{projectConf.expRegex or ''}#{opts.exp_name}")
  if expDir is null
    setErrorCode(res,ErrorCodes.exp,404)
    return
  else
    mediaDir= if projectConf.mediaDir not in ["",undefined,null] then "#{projectConf.mediaDir}/" else ""
    placeDir=Finder.from(expDir).findDirectory("#{mediaDir}#{opts.place.toLowerCase()}")
    if placeDir is undefined
      setErrorCode(res,ErrorCodes.place,404)
      return
    mediaFile=Finder.from(placeDir).findFile(projectConf.mediaRegex or '')
    if mediaFile is undefined
      setErrorCode(res,ErrorCodes.media,404)
      return
    else
      req.videoPath=mediaFile.replace(base,"vid/")
      console.log "VIDEO PATH : #{req.videoPath}"
      next()


router.get('/v/:project_acronym/:exp_name/:place',checkProject,findVideo,(req,res)-> vidStreamer req, res, req.videoPath )


router.get('/i/:project_acronym/',checkProject,(req,res)-> res.end()

router.get('/i/:project_acronym/:exp_name',checkProject, scanExp,(req,res)->
  #Just send 200 status
  res.setHeader 'Content-Type', 'application/json'
  res.end(JSON.stringify(req.expPlaces)))
)


router.post('/auth/',bodyParser.urlencoded({extended:false,parameterLimit:2}) ,(req,res)->
  console.log("AUTH REQUEST")
  console.log req.body
  res.end()
)
server=http.createServer (req,res)-> router(req,res,finalhandler(req,res,{
  message:true
}))

server.listen(5000)