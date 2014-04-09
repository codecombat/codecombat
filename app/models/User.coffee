GRAVATAR_URL = 'https://www.gravatar.com/'
cache = {}
CocoModel = require('./CocoModel')

module.exports = class User extends CocoModel
  @className: "User"
  urlRoot: "/db/user"

  initialize: ->
    super()

  isAdmin: ->
    permissions = @attributes['permissions'] or []
    return 'admin' in permissions

  displayName: ->
    @get('name') or "Anoner"

  lang: ->
    @get('preferredLanguage') or "en-US"

  getPhotoURL: (size=80) ->
    if photoURL = @get('photoURL')
      prefix = if photoURL.search(/\?/) is -1 then "?" else "&"
      return "#{photoURL}#{prefix}s=#{size}" if photoURL.search('http') isnt -1  # legacy
      return "/file/#{photoURL}#{prefix}s=#{size}"
    return "/db/user/#{@id}/avatar?s=#{size}"

  @getByID = (id, properties, force) ->
    {me} = require('lib/auth')
    return me if me.id is id
    user = cache[id] or new module.exports({_id:id})
    if force or not cache[id]
      user.loading = true
      user.fetch(
        success: ->
          user.loading = false
          Backbone.Mediator.publish('user:fetched')
          console.log 'triggering sync'
          user.trigger 'sync'
      )
    cache[id] = user
    user
