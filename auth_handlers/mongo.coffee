_  = require "lodash"
Promise = require "promise"
MClient = require("mongodb").MongoClient


module.exports = (uri, options) ->

  assertCredentials: (credentials) ->
    areCredentialsWellFormatted = _.isString(credentials.user) and _.isString(credentials.hash)
    @logger.trace "asserting credentials : #{areCredentialsWellFormatted}"
    areCredentialsWellFormatted

  isUserInProject:(userId,projectAcronym)->
    promise = new Promise (accept,reject)->
      MClient.connect(uri).then (db)=>
        users=db.collection 'users'
        projects=db.collection "projects"
        projects.findOne(acronym:projectAcronym,_id:1)
        .then (prj)-> users.findOne {_id:userId,'roles':{_id:"project.member",partition:"projects.#{prj.acronym}"}}
        .then (user)->
          db.close()
          accept user isnt null
    promise

  authClientASync: (credentials) ->
    promise = new Promise (accept)->
      MClient.connect(uri).then (db)=>
        selector=
          _id:credentials.user
          "services.password.bcrypt":credentials.hash
        users=db.collection 'users'
        users.findOne(selector).then (user)->
          db.close()
          accept user isnt null
    promise



