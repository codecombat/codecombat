CocoClass = require 'core/CocoClass'

namesCache = {}

class NameLoader extends CocoClass
  loadNames: (ids) ->
    toLoad = _.uniq (id for id in ids when not namesCache[id])
    return false unless toLoad.length
    jqxhrOptions = {
      url: '/db/user/x/names',
      type: 'POST',
      data: {ids: toLoad},
      success: @loadedNames
    }

    return jqxhrOptions

  loadedNames: (newNames) =>
    _.extend namesCache, newNames

  getName: (id) ->
    if namesCache[id]?.firstName and namesCache[id]?.lastName
      return "#{namesCache[id]?.firstName} #{namesCache[id]?.lastName}"
    namesCache[id]?.firstName or namesCache[id]?.name or id

module.exports = new NameLoader()
