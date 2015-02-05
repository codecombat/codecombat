CocoView = require 'views/core/CocoView'
template = require 'templates/account/account-settings-view'
{me} = require 'core/auth'
forms = require 'core/forms'
User = require 'models/User'
AuthModal = require 'views/core/AuthModal'

module.exports = class AccountSettingsView extends CocoView
  id: 'account-settings-view'
  template: template
  className: 'countainer-fluid'

  events:
    'change .panel input': 'onInputChanged'
    'change #name': 'checkNameExists'
    'click #toggle-all-button': 'toggleEmailSubscriptions'
    'click .profile-photo': 'onEditProfilePhoto'
    'click #upload-photo-button': 'onEditProfilePhoto'
    
  constructor: (options) ->
    super options
    require('core/services/filepicker')() unless window.application.isIPadApp  # Initialize if needed
    @uploadFilePath = "db/user/#{me.id}"

  afterInsert: ->
    super()
    @openModalView new AuthModal() if me.get('anonymous')

  getRenderData: ->
    c = super()
    return c unless me
    c.subs = {}
    c.subs[sub] = 1 for sub in me.getEnabledEmails()
    c

    
  #- Form input callbacks
  
  onInputChanged: (e) ->
    $(e.target).addClass 'changed'
    @trigger 'input-changed'

  toggleEmailSubscriptions: =>
    subs = @getSubscriptions()
    $('#email-panel input[type="checkbox"]', @$el).prop('checked', not _.any(_.values(subs))).addClass('changed')

  checkNameExists: =>
    name = $('#name', @$el).val()
    return if name is me.get 'name'
    User.getUnconflictedName name, (newName) =>
      forms.clearFormAlerts(@$el)
      if name is newName
        @suggestedName = undefined
      else
        @suggestedName = newName
        forms.setErrorToProperty @$el, 'name', "That name is taken! How about #{newName}?", true

  onPictureChanged: (e) =>
    @trigger 'inputChanged', e
    @$el.find('.gravatar-fallback').toggle not me.get 'photoURL'

    
  #- Just copied from OptionsView, TODO refactor
    
  onEditProfilePhoto: (e) ->
    return if window.application.isIPadApp  # TODO: have an iPad-native way of uploading a photo, since we don't want to load FilePicker on iPad (memory)
    photoContainer = @$el.find('.profile-photo')
    onSaving = =>
      photoContainer.addClass('saving')
    onSaved = (uploadingPath) =>
      @$el.find('#photoURL').val(uploadingPath)
      @$el.find('#photoURL').trigger('change') # cause for some reason editing the value doesn't trigger the jquery event
      me.set('photoURL', uploadingPath)
      photoContainer.removeClass('saving').attr('src', me.getPhotoURL(photoContainer.width()))
    filepicker.pick {mimetypes: 'image/*'}, @onImageChosen(onSaving, onSaved)

  formatImagePostData: (inkBlob) ->
    url: inkBlob.url, filename: inkBlob.filename, mimetype: inkBlob.mimetype, path: @uploadFilePath, force: true

  onImageChosen: (onSaving, onSaved) ->
    (inkBlob) =>
      onSaving()
      uploadingPath = [@uploadFilePath, inkBlob.filename].join('/')
      data = @formatImagePostData(inkBlob)
      success = @onImageUploaded(onSaved, uploadingPath)
      $.ajax '/file', type: 'POST', data: data, success: success

  onImageUploaded: (onSaved, uploadingPath) ->
    (e) =>
      onSaved uploadingPath
    
    
  #- Misc

  getSubscriptions: ->
    inputs = ($(i) for i in $('#email-panel input[type="checkbox"].changed', @$el))
    emailNames = (i.attr('name').replace('email_', '') for i in inputs)
    enableds = (i.prop('checked') for i in inputs)
    _.zipObject emailNames, enableds

    
  #- Saving changes
    
  save: ->
    $('#settings-tabs input').removeClass 'changed'
    forms.clearFormAlerts(@$el)
    @grabData()
    res = me.validate()
    if res?
      console.error 'Couldn\'t save because of validation errors:', res
      forms.applyErrorsToForm(@$el, res)
      $('.nano').nanoScroller({scrollTo: @$el.find('.has-error')})
      return

    return unless me.hasLocalChanges()

    res = me.patch()
    return unless res

    res.error =>
      errors = JSON.parse(res.responseText)
      forms.applyErrorsToForm(@$el, errors)
      $('.nano').nanoScroller({scrollTo: @$el.find('.has-error')})
      @trigger 'save-user-error'
    res.success (model, response, options) =>
      @trigger 'save-user-success'

    @trigger 'save-user-began'

  grabData: ->
    @grabPasswordData()
    @grabOtherData()

  grabPasswordData: ->
    password1 = $('#password', @$el).val()
    password2 = $('#password2', @$el).val()
    bothThere = Boolean(password1) and Boolean(password2)
    if bothThere and password1 isnt password2
      message = $.i18n.t('account_settings.password_mismatch', defaultValue: 'Password does not match.')
      err = [message: message, property: 'password2', formatted: true]
      forms.applyErrorsToForm(@$el, err)
      $('.nano').nanoScroller({scrollTo: @$el.find('.has-error')})
      return
    if bothThere
      me.set('password', password1)
    else if password1
      message = $.i18n.t('account_settings.password_repeat', defaultValue: 'Please repeat your password.')
      err = [message: message, property: 'password2', formatted: true]
      forms.applyErrorsToForm(@$el, err)
      $('.nano').nanoScroller({scrollTo: @$el.find('.has-error')})

  grabOtherData: ->
    @$el.find('#name').val @suggestedName if @suggestedName
    me.set 'name', @$el.find('#name').val()
    me.set 'email', @$el.find('#email').val()
    for emailName, enabled of @getSubscriptions()
      me.setEmailSubscription emailName, enabled

    me.set('photoURL', @$el.find('#photoURL').val())

    adminCheckbox = @$el.find('#admin')
    if adminCheckbox.length
      permissions = []
      permissions.push 'admin' if adminCheckbox.prop('checked')
      me.set('permissions', permissions)
