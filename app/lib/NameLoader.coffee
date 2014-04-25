CocoClass = require 'lib/CocoClass'

namesCache = {}

class NameLoader extends CocoClass
  loadNames: (ids) ->
    toLoad = (id for id in ids when not namesCache[id])
    return false unless toLoad.length
    jqxhrOptions = {
      url: '/db/user/x/names', 
      type:'POST', 
      data:{ids:toLoad}, 
      success: @loadedNames
    }

    return jqxhrOptions

  loadedNames: (newNames) =>
    _.extend namesCache, newNames
    
  getName: (id) -> namesCache[id].name

module.exports = new NameLoader()
