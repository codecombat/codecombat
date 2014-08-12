CocoModel = require './CocoModel'
utils = require '../lib/utils'

module.exports = class Achievement extends CocoModel
  @className: 'Achievement'
  @schema: require 'schemas/models/achievement'
  urlRoot: '/db/achievement'

  isRepeatable: ->
    @get('proportionalTo')?

  # TODO logic is duplicated in Mongoose Achievement schema
  getExpFunction: ->
    kind = @get('function')?.kind or jsonschema.properties.function.default.kind
    parameters = @get('function')?.parameters or jsonschema.properties.function.default.parameters
    return utils.functionCreators[kind](parameters) if kind of utils.functionCreators

  @styleMapping:
    1: 'achievement-wood'
    2: 'achievement-stone'
    3: 'achievement-silver'
    4: 'achievement-gold'
    5: 'achievement-diamond'

  getStyle: -> Achievement.styleMapping[@get 'difficulty']

  @defaultImageURL: '/images/achievements/default.png'

  getImageURL: ->
    if @get 'icon' then '/file/' + @get('icon') else Achievement.defaultImageURL

  hasImage: -> @get('icon')?

  # TODO Could cache the default icon separately
  cacheLockedImage: ->
    return @lockedImageURL if @lockedImageURL
    canvas = document.createElement 'canvas'
    image = new Image
    image.src = @getImageURL()
    defer = $.Deferred()
    image.onload = =>
      canvas.width = image.width
      canvas.height = image.height
      context = canvas.getContext '2d'
      context.drawImage image, 0, 0
      imgData = context.getImageData 0, 0, canvas.width, canvas.height
      imgData = utils.grayscale imgData
      context.putImageData imgData, 0, 0
      @lockedImageURL = canvas.toDataURL()
      defer.resolve @lockedImageURL
    defer

  getLockedImageURL: -> @lockedImageURL

  i18nName: -> utils.i18n @attributes, 'name'

  i18nDescription: -> utils.i18n @attributes, 'description'
