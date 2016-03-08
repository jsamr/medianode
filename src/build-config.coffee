path       = require 'path'
Logger     = require 'pince'
config     = require '../config.json'
yamlLoader = require './yaml-loader'
_          = require 'lodash'

logger     = new Logger 'media-node:config-builder'


_.each config.projects, (prj,name)->
  if prj.supportsMeta
    prj.defaultMeta=yamlLoader path.join config.serv.baseDir, prj.rootDir, 'meta.yml'
    if prj.defaultMeta then logger.info "Default meta file loaded for project #{name}"
    else logger.warn "Could not load default meta file for project #{name}"

module.exports=config