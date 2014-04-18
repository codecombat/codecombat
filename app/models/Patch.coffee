CocoModel = require('./CocoModel')

module.exports = class PatchModel extends CocoModel
  @className: "Patch"
  urlRoot: "/db/patch" 
  
  setStatus: (status) ->
    PatchModel.setStatus @id, status
    
  @setStatus: (id, status) ->
    $.ajax("/db/patch/#{id}/status", {type:"PUT", data: {status:status}})