finalhandler = require('finalhandler')
http         = require('http')
Router       = require('router')
crypto       = require('crypto')
fs           = require("fs")
vidStreamer  = require("../lib/vidStreamer")
configuration= require("../config.json")

Finder = require('fs-finder')

if not configuration? then console.error "Missing config.json file" and exit 1

base=configuration.baseDir

if not base then console.error "Missing baseDir property in config.json file" and exit 1
if not base.substr(base.length-1) is "/" then base="#{base}/"

handleMissingResource=(res,reason)->
  res.statusCode = 404
  res.setHeader "Content-Type","text/plain; charset=utf-8"
  res.end(reason)

router=Router()
router.get('/v/:project_acronym/:exp_name/:place',(req,res)->
  opts=req.params
  projectConf=configuration.projects[opts.project_acronym]
  if projectConf is undefined then handleMissingResource res, "Project #{opts.project_acronym} is not registered"
  if projectConf.rootDir is undefined then console.error "missing rootDir property for project #{opts.project_acronym}"
  root="#{base}#{projectConf.rootDir}"
  expDir= Finder.from(root).findDirectory("#{projectConf.expRegex or ''}#{opts.exp_name}")
  if expDir is null then handleMissingResource res, "Exp #{opts.exp_name} associated directory was not found."
  else
    videoDir=Finder.from(expDir).findDirectory("video/#{opts.place.toLowerCase()}")
    if videoDir is null then handleMissingResource res, "In exp #{opts.exp_name}, #{opts.place} does not exists."
    videoFile=Finder.from(videoDir).findFile(projectConf.videoRegex or '')
    console.log projectConf.videoRegex
    if videoFile is null then handleMissingResource res, "In exp #{opts.exp_name}, #{opts.place} associated video was not found."
    else
      console.log "video file found : #{videoFile}"
      vidStreamer req, res, videoFile.replace(root,"vid/")
)

router.get('/v/:project_acronym/:exp_name/:place',(req,res)->
)

server=http.createServer (req,res)-> router(req,res,finalhandler(req,res))

server.listen(5000)