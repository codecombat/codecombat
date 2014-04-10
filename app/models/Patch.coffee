CocoModel = require('./CocoModel')

module.exports = class PatchModel extends CocoModel
  @className: "Patch"
  urlRoot: "/db/patch" 