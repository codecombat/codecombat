{downTheChain} = require './world_utils'

module.exports.scriptMatchesEventPrereqs = scriptMatchesEventPrereqs = (script, event) ->
  return true unless script.eventPrereqs
  for ap in script.eventPrereqs
    v = downTheChain(event, ap.eventProps)
    return false if ap.equalTo? and v isnt ap.equalTo
    return false if ap.notEqualTo? and v is ap.notEqualTo
    return false if ap.greaterThan? and not (v > ap.greaterThan)
    return false if ap.greaterThanOrEqualTo? and not (v >= ap.greaterThanOrEqualTo)
    return false if ap.lessThan? and not (v < ap.lessThan)
    return false if ap.lessThanOrEqualTo? and not (v <= ap.lessThanOrEqualTo)
    return false if ap.containingString? and v?.search(ap.containingString) == -1
    return false if ap.notContainingString? and v?.search(ap.containingString) != -1

  return true
