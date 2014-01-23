LevelDraft = require('./LevelDraft')
Handler = require('../../commons/Handler')

LevelDraftHandler = class LevelDraftHandler extends Handler
  modelClass: LevelDraft
  editableProperties: ['level']
  postEditableProperties: ['user']

  post: (req, res) ->
    req.body.user = req.user._id
    super(req, res)

module.exports = new LevelDraftHandler()