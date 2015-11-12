ErrorCodes    = require("./error-codes")
configuration = require("../config.json")
Finder        = require('fs-finder')
fs            = require("fs")
_             = require("lodash")
vidStreamer   = require("../lib/vidStreamer")
path          = require("path")
pathStore    =  require("./path-store")

setErrorCode=(res,msg,code=200)->
  res.setHeader 'Content-Type','application/json'
  res.setHeader "Access-Control-Allow-Origin", '*'
  res.setHeader "Access-Control-Allow-Methods", "GET, POST"
  res.status=code
  if configuration.serv.log then console.warn("ERROR : #{msg}, HTTP status : #{code}")
  res.end(JSON.stringify(msg))
  true

base=configuration.serv.baseDir

if not base
  console.error "Missing baseDir property in config.json file"
  process.exit 1
if not base.substr(base.length-1) is "/" then base="#{base}/"

methods = {

  checkProject:(req,res,next)->
    opts=req.params
    projectConf=configuration.projects[opts.project_acronym]
    if projectConf is undefined
      setErrorCode(res,ErrorCodes.project,500)
      return
    if projectConf.rootDir is undefined
      setErrorCode(res,ErrorCodes.rootNotConfigured,500)
      return
    if not req.application.hasPrerogativeForProject opts.project_acronym
      setErrorCode(res,ErrorCodes.app_prerogatives,403)
      return
    req.projectConfig=projectConf
    next()
  checkExp:(req,res,next)->
    projectConf=req.projectConfig
    rootPath=Finder.from(base).findDirectory(projectConf.rootDir)
    if not rootPath?
      setErrorCode res, ErrorCodes.root
      return
    opts=req.params
    expDir= Finder.from(rootPath).findDirectory("#{projectConf.expRegex or ''}#{opts.exp_name}")
    if not expDir?
      setErrorCode res, ErrorCodes.exp
      return
    mediaDir= if projectConf.mediaDir not in ["",undefined,null] then "#{projectConf.mediaDir}/" else ""
    places=Finder.from(expDir).findDirectories("#{mediaDir}*").map (absolute)->absolute.replace("#{expDir}/#{mediaDir}","")
    req.expPlaces={
      places:(places or [])
    }
    next()
  findMedia:(req,res)->
    projectConf=req.projectConfig
    #retrive from redis if exists
    pathStore.fetch req.path, (err,lookupPath)->
      console.log error if err
      if lookupPath and not req.fsErrorCallback
        req.videoPath=lookupPath
        #Upon errors, bypass lookup
        req.fsErrorCallback= -> methods.findMedia(req,res)
        vidStreamer req, res, req.videoPath, req.fsErrorCallback
      else
        rootPath=Finder.from(base).findDirectory(projectConf.rootDir)
        if not rootPath? then setErrorCode(res,ErrorCodes.root,404)
        else
          opts=req.params
          projectConf=req.projectConfig
          expDir= Finder.from(rootPath).findDirectory("#{projectConf.expRegex or ''}#{opts.exp_name}")
          if not expDir? then setErrorCode(res,ErrorCodes.exp,404)
          else
            mediaDir= if projectConf.mediaDir not in ["",undefined,null] then "#{projectConf.mediaDir}/" else ""
            placeDir=Finder.from(expDir).findDirectory("#{mediaDir}#{opts.place.toLowerCase()}")
            if not placeDir? then setErrorCode(res,ErrorCodes.place,404)
            else
              mediaFile=Finder.from(placeDir).findFile(projectConf.mediaRegex or '')
              if not mediaFile? then setErrorCode(res,ErrorCodes.media,404)
              else
                req.videoPath=mediaFile.replace(base,"vid/")
                pathStore.save req.path, req.videoPath
                vidStreamer req, res, req.videoPath, req.fsErrorCallback

  flushProject:(req,res)-> res.end()
  flushPlaces:(req,res)->
    #Just send 200 status
    res.setHeader 'Content-Type', 'application/json'
    res.end(JSON.stringify(req.expPlaces))
  flushSvgStatus:(req,res)->
    file=path.join(process.cwd(),'../public/status-ok.svg')
    res.setHeader 'Content-Type','image/svg+xml'
    fs.createReadStream(file).pipe(res)
  setErrorCode:setErrorCode
}

module.exports=methods