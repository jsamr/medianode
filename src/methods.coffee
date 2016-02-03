ErrorCodes    = require "./error-codes"
configuration = require "../config.json"
Finder        = require 'fs-finder'
fs            = require "fs"
_             = require "lodash"
vidStreamer   = require "../lib/vidStreamer"
path          = require "path"
pathStore     = require "./path-store"
Logger        = require "pince"

prefix          = "media-node:methods"
logger          = new Logger prefix
loaderLogger = new Logger "#{prefix}:loader"
projectChLogger = new Logger "#{prefix}:project-check"
expChLogger     = new Logger "#{prefix}:exp-check"
mediaLogger     = new Logger "#{prefix}:media-finder"

getClientIp=(req)->req.headers['x-forwarded-for'] || req.connection.remoteAddress

setErrorCode=(res,msg,code=200,req,log=logger)->
  res.setHeader 'Content-Type','application/json'
  res.setHeader "Access-Control-Allow-Origin", '*'
  res.setHeader "Access-Control-Allow-Methods", "GET, POST"
  res.status=code
  client=""
  if req then client=", CLIENT:#{getClientIp(req)}"
  log.warn("#{msg}, HTTP status : #{code}#{client}")
  res.end(JSON.stringify(msg))
  true


  
base=configuration.serv.baseDir

if not base
  loaderLogger.error "Missing baseDir property in config.json file"
  process.exit 1
if not base.substr(base.length-1) is "/" then base="#{base}/"

methods = {

  checkProject:(req,res,next)->
    opts=req.params
    projectConf=configuration.projects[opts.project_acronym]
    if projectConf is undefined
      setErrorCode res, ErrorCodes.project, 500, req, projectChLogger
      return
    if projectConf.rootDir is undefined
      setErrorCode res, ErrorCodes.rootNotConfigured, 500, req, projectChLogger
      return
    if not req.application.hasPrerogativeForProject opts.project_acronym
      setErrorCode res, ErrorCodes.app_prerogatives, 403, req, projectChLogger
      return
    req.projectConfig=projectConf
    next()
  checkExp:(req,res,next)->
    projectConf=req.projectConfig
    rootPath=Finder.from(base).findDirectory(projectConf.rootDir)
    if not rootPath?
      setErrorCode res, ErrorCodes.root, req, expChLogger
      return
    opts=req.params
    expDir= Finder.from(rootPath).findDirectory("#{projectConf.expRegex or ''}#{opts.exp_name}")
    if not expDir?
      setErrorCode res, ErrorCodes.exp, req, expChLogger
      return
    mediaDir= if projectConf.mediaDir not in ["",undefined,null] then "#{projectConf.mediaDir}/" else ""
    req.appPaths={
      exp : expDir
      media : mediaDir
    }
    next()
  findMedia:(req,res)->
    projectConf=req.projectConfig
    #retrive from redis if exists
    pathStore.fetch req.path, (err,lookupPath)->
      mediaLogger.error JSON.stringify error if err
      if lookupPath and not req.fsErrorCallback
        req.videoPath=lookupPath
        #Upon errors, bypass lookup
        req.fsErrorCallback= -> methods.findMedia(req,res)
        vidStreamer req, res, req.videoPath, req.fsErrorCallback
      else
        rootPath=Finder.from(base).findDirectory(projectConf.rootDir)
        if not rootPath? then setErrorCode res, ErrorCodes.root, 404, req, mediaLogger
        else
          mediaLogger.debug "Found root : #{rootPath}"
          opts=req.params
          projectConf=req.projectConfig
          expDir= Finder.from(rootPath).findDirectory("#{projectConf.expRegex or ''}#{opts.exp_name}")
          if not expDir? then setErrorCode res, ErrorCodes.exp, 404, req, mediaLogger
          else
            mediaLogger.debug "Found exp dir : #{expDir}"
            mediaDir= if projectConf.mediaDir not in ["",undefined,null] then "#{projectConf.mediaDir}/" else ""
            placeDir=Finder.from(expDir).findDirectory("#{mediaDir}#{opts.place}")
            if not placeDir? then setErrorCode res, ErrorCodes.place, 404, req, mediaLogger
            else
              mediaLogger.debug "Found place dir : #{placeDir}"
              mediaFile=Finder.from(placeDir).findFile(projectConf.mediaRegex or '')
              if not mediaFile? then setErrorCode res, ErrorCodes.media, 404, req, mediaLogger
              else
                mediaLogger.debug "Found media file : #{mediaFile}"
                req.videoPath=mediaFile.replace(base,"vid/")
                mediaLogger.info req.path
                pathStore.save req.path, req.videoPath
                vidStreamer req, res, req.videoPath, req.fsErrorCallback

  flushProject:(req,res)-> res.end()
  flushPlaces:(req,res)->
    #Just send 200 status
    paths=req.appPaths
    projectConf=req.projectConfig
    places = req.application.retrievePlaces paths.exp, paths.media, projectConf
    res.setHeader 'Content-Type', 'application/json; charset=utf-8'
    res.end(JSON.stringify({places:places}))
  flushSvgStatus:(req,res)->
    file=path.join(process.cwd(),'../public/status-ok.svg')
    res.setHeader 'Content-Type','image/svg+xml'
    fs.createReadStream(file).pipe(res)
  setErrorCode:setErrorCode
}

module.exports=methods