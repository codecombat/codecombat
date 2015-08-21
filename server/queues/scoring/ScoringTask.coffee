mongoose = require 'mongoose'

ScoringTaskSchema = new mongoose.Schema(
  createdAt: {type: Date, expires: 3600} #expire document 1 hour after they are created
  calculator: {type: mongoose.Schema.Types.ObjectId}
  sentDate: {type: Number}
  messageIdentifierString: {type: String}
  calculationTimeMS: {type: Number, default: 0}
  sessions: {type: Array, default: []}
)

ScoringTaskSchema.index({createdAt: 1}, {expireAfterSeconds: 3600})

module.exports = mongoose.model('scoringTask', ScoringTaskSchema)
