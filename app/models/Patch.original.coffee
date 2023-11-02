CocoModel = require './CocoModel'

module.exports = class PatchModel extends CocoModel
  @className: 'Patch'
  @schema: require 'schemas/models/patch'
  urlRoot: '/db/patch'

  setStatus: (status, options={}) ->
    options.url = "/db/patch/#{@id}/status"
    options.type = 'PUT'
    @save({status}, options)

  @setStatus: (id, status) ->
    $.ajax("/db/patch/#{id}/status", {type: 'PUT', data: {status: status}})
