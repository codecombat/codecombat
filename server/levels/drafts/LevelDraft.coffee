mongoose = require('mongoose')
Level = require('../Level')

LevelDraftSchema = new mongoose.Schema(
  user: {type: mongoose.Schema.ObjectId, ref: 'User'}
  level: {}
)

module.exports = LevelDraft = mongoose.model('level.draft', LevelDraftSchema)