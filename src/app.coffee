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


HttpError=(msg,status)->
  err=Error.call(this,msg)
  err.stack=""
  err.status=status
  err.name="HttpError"
  err

UnreachableResource=(msg)->
  err=HttpError.call(this,msg)
  err.status=404
  err.name="Unreachable Resource"
  err

if not configuration? then console.error "Missing config.json file" and exit 1

base=configuration.baseDir

if not base then console.error "Missing baseDir property in config.json file" and exit 1
if not base.substr(base.length-1) is "/" then base="#{base}/"

logUnauthorized=(req,msg)->
  console.warn msg
  console.warn "HEADERS:"
  console.warn req.headers
  console.warn "REMOTE IP: #{req.headers['x-forwarded-for'] or
      req.connection.remoteAddress or
      req.socket.remoteAddress or
      req.connection.socket.remoteAddress}"

crossDomainOriginPolicy=(req,res,next) ->
  ref =  req.headers.referer
  match = (_.find configuration.crossOriginDomains, (domain)-> ref.match("#{domain}*")) if ref
  if match
    res.setHeader "Access-Control-Allow-Origin", match
    res.setHeader "Access-Control-Allow-Methods", "GET, POST"
    next()
  else
    if ref then logUnauthorized req, "UNAUTHORIZED REFERER : #{ref} ATTEMPTED TO CONNECT"
    else logUnauthorized req,"NON-ORIGINATED ATTEMPT TO CONNECT FROM CLIENT :"
    next new HttpError("Acces forbidden.",403)

router=Router()

router.use(crossDomainOriginPolicy)

router.get('/status',(req,res)->
  file=path.join(process.cwd(),'public/status-ok.svg')
  res.setHeader 'Content-Type','image/svg+xml'
  fs.createReadStream(file).pipe(res)
)

findVideo=(req,res,next)->
  opts=req.params
  projectConf=configuration.projects[opts.project_acronym]
  if projectConf is undefined then next new HttpError("Project #{opts.project_acronym} is not registered",500)
  if projectConf.rootDir is undefined then next new HttpError("missing rootDir property for project #{opts.project_acronym}",500)
  root="#{base}#{projectConf.rootDir}"
  expDir= Finder.from(root).findDirectory("#{projectConf.expRegex or ''}#{opts.exp_name}")
  if expDir is null then next new UnreachableResource("Exp #{opts.exp_name} associated directory was not found.")
  else
    videoDir=Finder.from(expDir).findDirectory("video/#{opts.place.toLowerCase()}")
    if videoDir is null then next new UnreachableResource("In exp #{opts.exp_name}, #{opts.place} is not a valid place.")
    videoFile=Finder.from(videoDir).findFile(projectConf.videoRegex or '')
    console.log projectConf.videoRegex
    if videoFile is null then next new UnreachableResource("In exp #{opts.exp_name}, #{opts.place} associated video was not found.")
    else
      console.log "video file found : #{videoFile}"
      req.videoPath=videoFile.replace(root,"vid/")
      next()


router.get('/v/:project_acronym/:exp_name/:place',findVideo,(req,res,next)->
  vidStreamer req, res, req.videoPath
)

router.get('/i/',(req,res)->
  res.setHeader "Content-Type","text/plain; charset=utf-8"
  res.end("Salut connard!"))


router.post('/auth/',bodyParser.urlencoded({extended:false,parameterLimit:2}) ,(req,res)->
  console.log("AUTH REQUEST")
  console.log req.body
  res.end()
)
server=http.createServer (req,res)-> router(req,res,finalhandler(req,res,{
  message:true
}))

server.listen(5000)