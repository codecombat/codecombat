GRAVATAR_URL = 'https://www.gravatar.com/'
cache = {}
CocoModel = require('./CocoModel')

module.exports = class User extends CocoModel
  @className: "User"
  urlRoot: "/db/user"

  initialize: ->
    super()
    @on 'change:emailHash', ->
      @gravatarProfile = null
      @loadGravatarProfile()

  isAdmin: ->
    permissions = @attributes['permissions'] or []
    return 'admin' in permissions

  gravatarAvatarURL: ->
    avatar_url = GRAVATAR_URL + 'avatar/'
    return avatar_url if not @emailHash
    return avatar_url + @emailHash

  loadGravatarProfile: ->
    emailHash = @get('emailHash')
    return if not emailHash
    functionName = 'gotProfile'+emailHash
    profileUrl = "#{GRAVATAR_URL}#{emailHash}.json?callback=#{functionName}"
    script = $("<script src='#{profileUrl}' type='text/javascript'></script>")
    $('head').append(script)
    $('body').on('load',(e)->console.log('we did it!', e))
    window[functionName] = (profile) =>
      @gravatarProfile = profile
      @trigger('change', @)

    func = => @gravatarProfile = null unless @gravatarProfile
    setTimeout(func, 1000)

  displayName: ->
    @get('name') or @gravatarName() or "Anoner"

  lang: ->
    @get('preferredLanguage') or "en-US"

  gravatarName: ->
    @gravatarProfile?.entry[0]?.name?.formatted or ''

  gravatarPhotoURLs: ->
    photos = @gravatarProfile?.entry[0]?.photos
    return if not photos
    (photo.value for photo in photos)

  getPhotoURL: ->
    photoURL = @get('photoURL')
    validURLs = @gravatarPhotoURLs()
    return @gravatarAvatarURL() unless validURLs and validURLs.length
    return validURLs[0] unless photoURL in validURLs
    return photoURL

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
          user.loadGravatarProfile()
      )
    cache[id] = user
    user
