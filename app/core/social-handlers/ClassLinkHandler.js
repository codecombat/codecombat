const EdlinkBaseHandler = require('./EdlinkBaseHandler')

module.exports = class ClassLinkHandler extends EdlinkBaseHandler {
  constructor () {
    super('classlink')
  }
}
