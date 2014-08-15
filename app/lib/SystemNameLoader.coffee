CocoClass = require './CocoClass'

namesCache = {}

class SystemNameLoader extends CocoClass
  getName: (id) -> namesCache[id]?.name

  setName: (system) -> namesCache[system.get('original')] = {name: system.get('name')}

module.exports = new SystemNameLoader()
