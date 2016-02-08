errors = require '../commons/errors'
wrap = require 'co-express'
database = require '../commons/database'

mongoose = require 'mongoose'
CodeLog = require '../models/CodeLog'
LevelSession = require '../models/LevelSession'

module.exports =
  post: wrap (req, res) ->
    codeLog = database.initDoc(req, CodeLog)
    database.assignBody(req, codeLog)
    database.validateDoc(codeLog)
    codeLog = yield codeLog.save()

    # Update the level session with sessionID to include the new codelog.
    yield LevelSession.update(
      {_id: mongoose.Types.ObjectId(req.body.sessionID)},
      {$push:{codeLogs: codeLog._id}}
    )

    res.status(201).send(codeLog.toObject())
