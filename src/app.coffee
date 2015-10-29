finalhandler = require('finalhandler')
http         = require('http')
Router       = require('router')
crypto       = require('crypto')
fs           = require("fs")
vidStreamer  = require("../lib/vidStreamer")
Finder = require('fs-finder')

base="/home/svein/Téléchargements/"
root="#{base}DEI/"

handleMissingResource=(res,reason)->
  res.statusCode = 404
  res.setHeader "Content-Type","text/plain; charset=utf-8"
  res.end(reason)

router=Router()
router.get('/v/:project_acronym/:exp_name/:place',(req,res)->
  opts=req.params
  expDir= Finder.from(root).findDirectory("*#{opts.exp_name}")
  if expDir is null then handleMissingResource res, "Exp #{opts.exp_name} associated directory was not found."
  else
    videoDir=Finder.from(expDir).findDirectory("video/#{opts.place.toLowerCase()}")
    videoFile=Finder.from(videoDir).findFile("*.mp4")
    if videoDir is null or videoFile is null then handleMissingResource res, "In exp #{opts.exp_name}, #{opts.place} associated video was not found."

    else
      vidStreamer req, res, videoFile.replace(root,"vid/")

)

server=http.createServer (req,res)-> router(req,res,finalhandler(req,res))

server.listen(5000)