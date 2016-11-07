CocoCollection = require 'collections/CocoCollection'
Branch = require 'models/Branch'

module.exports = class Branches extends CocoCollection
  url: '/db/branches'
  model: Branch

  comparator: (branch1, branch2) ->
    iUpdatedB1 = branch1.get('updatedBy') is me.id
    iUpdatedB2 = branch2.get('updatedBy') is me.id
    return -1 if iUpdatedB1 and not iUpdatedB2
    return 1 if iUpdatedB2 and not iUpdatedB1
    return new Date(branch2.get('updated')).getTime() - new Date(branch1.get('updated')).getTime()
