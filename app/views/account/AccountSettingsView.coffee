CocoView = require 'views/core/CocoView'
template = require 'templates/account/account-settings-view'
{me} = require 'core/auth'
forms = require 'core/forms'
User = require 'models/User'
AuthModal = require 'views/core/AuthModal'
ConfirmModal = require 'views/editor/modal/ConfirmModal'
{logoutUser, me} = require('core/auth')

module.exports = class AccountSettingsView extends CocoView
  id: 'account-settings-view'
  template: template
  className: 'countainer-fluid'

  events:
    'change .panel input': 'onChangePanelInput'
    'change #name-input': 'onChangeNameInput'
    'click #toggle-all-btn': 'onClickToggleAllButton'
    'click #profile-photo-panel-body': 'onClickProfilePhotoPanelBody'
    'click #delete-account-btn': 'onClickDeleteAccountButton'

  constructor: (options) ->
    super options
    require('core/services/filepicker')() unless window.application.isIPadApp  # Initialize if needed
    @uploadFilePath = "db/user/#{me.id}"

  afterInsert: ->
    super()
    @openModalView new AuthModal() if me.get('anonymous')

  getEmailSubsDict: ->
    subs = {}
    return subs unless me
    subs[sub] = 1 for sub in me.getEnabledEmails()
    return subs

  #- Form input callbacks
  onChangePanelInput: (e) ->
    $(e.target).addClass 'changed'
    if (JSON.stringify(document.getElementById('email1').className)).indexOf("changed") > -1 or (JSON.stringify(document.getElementById('password1').className)).indexOf("changed") > -1
      $(e.target).removeClass 'changed'
    else
      @trigger 'input-changed'

  onClickToggleAllButton: ->
    subs = @getSubscriptions()
    $('#email-panel input[type="checkbox"]', @$el).prop('checked', not _.any(_.values(subs))).addClass('changed')
    @trigger 'input-changed'

  onChangeNameInput: ->
    name = $('#name-input', @$el).val()
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
  onClickDeleteAccountButton: ->
    forms.clearFormAlerts(@$el)
    myEmail = me.get 'email'
    email1 = document.getElementById('email1').value
    password1 = document.getElementById('password1').value
    if Boolean(email1) and email1 is myEmail
      isPasswordCorrect = false
      toBeDelayed = true
      $.ajax
        url: '/auth/login'
        type: 'POST'
        data:
          {
            username: email1,
            password: password1
          }
        parse: true
        error: (error) ->
          toBeDelayed = false
          'Bad Error. Can\'t connect to server or something. ' + error
        success: (response, textStatus, jqXHR) ->
          toBeDelayed = false
          unless jqXHR.status is 200
            return
          isPasswordCorrect = true
      callback = =>
        if toBeDelayed
          setTimeout callback, 100
        else
          if isPasswordCorrect
            renderData =
              'confirmTitle': 'Are you really sure?'
              'confirmBody': 'This will completely delete your account. This action CANNOT be undone. Are you entirely sure?'
              'confirmDecline': 'Not really'
              'confirmConfirm': 'Definitely'
            confirmModal = new ConfirmModal renderData
            confirmModal.on 'confirm', @deleteAccount
            @openModalView confirmModal
          else
            message = $.i18n.t('account_settings.wrong_password', defaultValue: 'Wrong Password.')
            err = [message: message, property: 'password1', formatted: true]
            forms.applyErrorsToForm(@$el, err)
            $('.nano').nanoScroller({scrollTo: @$el.find('.has-error')})
      setTimeout callback, 100
    else
      message = $.i18n.t('account_settings.wrong_email', defaultValue: 'Wrong Email.')
      err = [message: message, property: 'email1', formatted: true]
      forms.applyErrorsToForm(@$el, err)
      $('.nano').nanoScroller({scrollTo: @$el.find('.has-error')})


  deleteAccount: ->
    myID = me.id
    $.ajax
      type: 'DELETE'
      success: ->
        noty
          timeout: 5000
          text: 'Your account is gone.'
          type: 'success'
          layout: 'topCenter'
        _.delay ->
          window?.webkit?.messageHandlers?.notification?.postMessage(name: "signOut") if window.application.isIPadApp
          Backbone.Mediator.publish("auth:logging-out", {})
          window.tracker?.trackEvent 'Log Out', category:'Homepage' if @id is 'home-view'
          logoutUser($('#login-email').val())
        , 500
      error: (jqXHR, status, error) ->
        console.error jqXHR
        timeout: 5000
        text: "Deleting account failed with error code #{jqXHR.status}"
        type: 'error'
        layout: 'topCenter'
      url: "/db/user/#{myID}"

  onClickProfilePhotoPanelBody: (e) ->
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
    @$el.find('#name-input').val @suggestedName if @suggestedName
    me.set 'name', @$el.find('#name-input').val()
    me.set 'email', @$el.find('#email').val()
    for emailName, enabled of @getSubscriptions()
      me.setEmailSubscription emailName, enabled

    me.set('photoURL', @$el.find('#photoURL').val())

    permissions = []

    adminCheckbox = @$el.find('#admin')
    if adminCheckbox.length
      permissions.push 'admin' if adminCheckbox.prop('checked')

    godmodeCheckbox = @$el.find('#godmode')
    if godmodeCheckbox.length
      permissions.push 'godmode' if godmodeCheckbox.prop('checked')

    me.set('permissions', permissions)
