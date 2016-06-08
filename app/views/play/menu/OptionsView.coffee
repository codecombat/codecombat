CocoView = require 'views/core/CocoView'
template = require 'templates/play/menu/options-view'
{me} = require 'core/auth'
ThangType = require 'models/ThangType'
User = require 'models/User'
forms = require 'core/forms'

module.exports = class OptionsView extends CocoView
  id: 'options-view'
  className: 'tab-pane'
  template: template
  aceConfig: {}
  defaultConfig:
    language: 'python'
    keyBindings: 'default'
    invisibles: false
    indentGuides: false
    behaviors: false
    liveCompletion: true

  events:
    'change #option-music': 'updateMusic'
    'change #option-invisibles': 'updateInvisibles'
    'change #option-indent-guides': 'updateIndentGuides'
    'change #option-behaviors': 'updateBehaviors'
    'change #option-live-completion': 'updateLiveCompletion'
    'click .profile-photo': 'onEditProfilePhoto'
    'click .editable-icon': 'onEditProfilePhoto'
    'keyup #player-name': -> @trigger 'nameChanged'

  constructor: (options) ->
    @uploadFilePath = "db/user/#{me.id}"
    @onNameChange = _.debounce(@checkNameExists, 500)
    @on 'nameChanged', @onNameChange
    @playerName = me.get 'name'
    require('core/services/filepicker')() unless window.application.isIPadApp  # Initialize if needed
    super options

  getRenderData: (c={}) ->
    c = super(c)
    @aceConfig = _.cloneDeep me.get('aceConfig') ? {}
    @aceConfig = _.defaults @aceConfig, @defaultConfig
    c.aceConfig = @aceConfig
    c.music = me.get('music', true)
    c

  afterRender: ->
    super()
    @volumeSlider = @$el.find('#option-volume').slider(animate: 'fast', min: 0, max: 1, step: 0.05)
    @volumeSlider.slider('value', me.get('volume'))
    @volumeSlider.on('slide', @onVolumeSliderChange)
    @volumeSlider.on('slidechange', @onVolumeSliderChange)

  destroy: ->
    @volumeSlider?.slider?('destroy')
    super()

  onVolumeSliderChange: (e) =>
    volume = @volumeSlider.slider('value')
    me.set 'volume', volume
    @$el.find('#option-volume-value').text (volume * 100).toFixed(0) + '%'
    Backbone.Mediator.publish 'level:set-volume', volume: volume
    @playSound 'menu-button-click'  # Could have another volume-indicating noise

  onHidden: ->
    if @playerName and @playerName isnt me.get('name')
      me.set 'name', @playerName
    @aceConfig.invisibles = @$el.find('#option-invisibles').prop('checked')
    @aceConfig.keyBindings = 'default'  # We used to give them the option, but we took it away.
    @aceConfig.indentGuides = @$el.find('#option-indent-guides').prop('checked')
    @aceConfig.behaviors = @$el.find('#option-behaviors').prop('checked')
    @aceConfig.liveCompletion = @$el.find('#option-live-completion').prop('checked')
    me.set 'aceConfig', @aceConfig
    me.patch()
    Backbone.Mediator.publish 'tome:change-config', {}

  updateMusic: ->
    me.set 'music', @$el.find('#option-music').prop('checked')

  updateInvisibles: ->
    @aceConfig.invisibles = @$el.find('#option-invisibles').prop('checked')

  updateKeyBindings: ->
    @aceConfig.keyBindings = @$el.find('#option-key-bindings').val()

  updateIndentGuides: ->
    @aceConfig.indentGuides = @$el.find('#option-indent-guides').prop('checked')

  updateBehaviors: ->
    @aceConfig.behaviors = @$el.find('#option-behaviors').prop('checked')

  updateLiveCompletion: ->
    @aceConfig.liveCompletion = @$el.find('#option-live-completion').prop('checked')

  checkNameExists: =>
    forms.clearFormAlerts(@$el)
    name = $('#player-name').val()
    User.getUnconflictedName name, (newName) =>
      forms.clearFormAlerts(@$el)
      if name isnt newName
        forms.setErrorToProperty @$el, 'playerName', 'This name is already taken so you won\'t be able to keep it.', true
      else
        @playerName = newName

  onEditProfilePhoto: (e) ->
    return if window.application.isIPadApp  # TODO: have an iPad-native way of uploading a photo, since we don't want to load FilePicker on iPad (memory)
    @playSound 'menu-button-click'
    photoContainer = @$el.find('.profile-photo')
    onSaving = =>
      photoContainer.addClass('saving')
    onSaved = (uploadingPath) =>
      me.set('photoURL', uploadingPath)
      photoContainer.removeClass('saving').attr('src', me.getPhotoURL(photoContainer.width()))
    filepicker.pick {mimetypes: 'image/*'}, @onImageChosen(onSaving, onSaved)

  formatImagePostData: (inkBlob) ->
    url: inkBlob.url, filename: inkBlob.filename, mimetype: inkBlob.mimetype, path: @uploadFilePath, force: true

  onImageChosen: (onSaving, onSaved) ->
    (inkBlob) =>
      onSaving()
      uploadingPath = [@uploadFilePath, inkBlob.filename].join('/')
      $.ajax '/file', type: 'POST', data: @formatImagePostData(inkBlob), success: @onImageUploaded(onSaved, uploadingPath)

  onImageUploaded: (onSaved, uploadingPath) ->
    (e) =>
      onSaved uploadingPath
