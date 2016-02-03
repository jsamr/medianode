yamlLoader    = require './yaml-loader'
_             = require 'lodash'
Finder        = require 'fs-finder'


singleRetriever = (expPath,mediaPath,projectConf,absolute)->
  file = Finder.from(absolute).findFile projectConf.mediaRegex or ''
  #if file then pathStore.save file.replace(base,"vid/")
  place    : absolute.replace "#{expPath}/#{mediaPath}", ""
  fileFound     : !!file

placesWithMetaRetriever = (expPath, mediaPath, projectConf)->
  _.map (Finder.from(expPath).findDirectories("#{mediaPath}*") || []), (absolute) ->
    places=singleRetriever expPath, mediaPath, projectConf, absolute
    if projectConf.supportsMeta
      meta  = Finder.from(absolute).findFile "meta.yml"
      places.meta = (yamlLoader meta if meta) || {}
    places

standardPlaceRetriever = (expPath, mediaPath, projectConf)->
  _.map (Finder.from(expPath).findDirectories("#{mediaPath}*") || []), (absolute) ->
    singleRetriever expPath, mediaPath, projectConf, absolute


module.exports=
  default:standardPlaceRetriever
  withMeta:placesWithMetaRetriever