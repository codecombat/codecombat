c = require './../schemas'

BranchSchema = {
  type: 'object'
  properties: {
    patches: {
      type: 'array'
      items: {
        type: 'object'
        # TODO: Link to Patch schema
      }
    }
    updated: c.stringDate()
    updatedBy: c.objectId()
    updatedByName: { type: 'string' }
  }
}

c.extendBasicProperties(BranchSchema, 'branches')
c.extendNamedProperties(BranchSchema)

module.exports = BranchSchema
