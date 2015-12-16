c = require './../schemas'

module.exports = MandateSchema = {
  type: 'object'
  additionalProperties: false
  default:
    simulationThroughputRatio: 1
  properties: {
    simulationThroughputRatio:
      name: 'Simulation Throughput Ratio'
      description: '0-1 fraction of requests for a match to simulate that should be granted.'
      type: 'number'
      minimum: 0
      maximum: 1
  }
}

c.extendBasicProperties MandateSchema, 'Mandate'
