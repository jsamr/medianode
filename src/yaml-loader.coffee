yaml = require 'js-yaml'
fs   = require 'fs'
Logger = require 'pince'
logger = new Logger 'media-node:yaml-loader'

# see https://github.com/nodeca/js-yaml
module.exports= (path,encoding="utf-8")->
  try return yaml.safeLoad fs.readFileSync path, encoding
  catch e then logger.error e
