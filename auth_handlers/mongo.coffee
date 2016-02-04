_  = require "lodash"
MClient = require("mongodb").MongoClient
module.exports = (uri, options) ->

  assertCredentials: (credentials) ->
    areCredentialsWellFormatted = _.isString(credentials.user) and _.isString(credentials.hash)
    @logger.debug "asserting credentials : #{areCredentialsWellFormatted}"
    areCredentialsWellFormatted

  authClientASync: (credentials) ->
    MClient.connect(uri).then (db)=>
      users=db.collection 'users'
      user=users.findOne username:credentials.user, 'services.password.bcryp':credentials.hash
      @logger.trace "authenticated client #{credentials.user} : #{!!user}"
      return !!user



