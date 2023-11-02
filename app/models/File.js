const CocoModel = require('./CocoModel')

class File extends CocoModel {
  constructor () {
    super()
  }
}

File.className = 'File'
File.schema = {}
File.prototype.urlRoot = '/db/file'

module.exports = File
