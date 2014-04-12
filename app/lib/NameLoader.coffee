CocoClass = require 'lib/CocoClass'

namesCache = {}

class NameLoader extends CocoClass
  loadNames: (ids) ->
    toLoad = (id for id in ids when not namesCache[id])
    return false unless toLoad.length
    jqxhr = $.ajax('/db/user/x/names', {type:'POST', data:{ids:toLoad}})
    jqxhr.done @loadedNames
      
  loadedNames: (newNames) =>
    _.extend namesCache, newNames
    
  getName: (id) -> namesCache[id]

module.exports = new NameLoader()
