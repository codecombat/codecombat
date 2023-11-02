const CocoModel = require('./CocoModel')

class File extends CocoModel {
  constructor () {
    super()
    this.className = 'File'
    this.schema = {}
    this.urlRoot = '/db/file'
  }
}

module.exports = File
