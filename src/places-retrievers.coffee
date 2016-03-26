yamlLoader    = require './yaml-loader'
_             = require 'lodash'
Finder        = require 'fs-finder'


singleRetriever = (mediaPath,projectConf,absolute)->
  file = Finder.from(absolute).findFile projectConf.mediaRegex or ''
  #if file then pathStore.save file.replace(base,"vid/")
  place         : absolute.replace "#{mediaPath}/", ""
  fileFound     : !!file

placesWithMetaRetriever = (mediaPath, projectConf)->
  _.map (Finder.in(mediaPath).findDirectories("*") || []), (absolute) ->
    places=singleRetriever mediaPath, projectConf, absolute
    if projectConf.supportsMeta
      metaFile  = Finder.from(absolute).findFile "meta.yml"
      metaObj = (yamlLoader metaFile if metaFile) || {}
      places.meta = _.defaultsDeep metaObj, projectConf.defaultMeta?[places.place]
    places

standardPlaceRetriever = (mediaPath, projectConf)->
  _.map (Finder.in(mediaPath).findDirectories("*") || []), (absolute) ->
    singleRetriever mediaPath, projectConf, absolute


module.exports=
  default:standardPlaceRetriever
  withMeta:placesWithMetaRetriever