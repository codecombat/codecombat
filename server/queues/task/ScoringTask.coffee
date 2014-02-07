mongoose = require('mongoose')

ScoringTaskSchema = new mongoose.Schema(
  calculator: {type:mongoose.Schema.Types.ObjectId}
  sentDate: {type: Date}
  messageIdentifierString: {type: String}
  calculationTimeMS: {type: Number, default: 0}
  sessions: {type: Array, default: []}
)

ScoringTaskSchema.set 'capped', 104857600 #100MB capped collection
module.exports = mongoose.model('scoringTask', ScoringTaskSchema)
