require('app/styles/account/account-settings-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/account/account-settings-view'
forms = require 'core/forms'
User = require 'models/User'
ConfirmModal = require 'views/core/ConfirmModal'
{logoutUser, me} = require('core/auth')

module.exports = class AccountSettingsView extends CocoView
  id: 'account-settings-view'
  template: template
  className: 'countainer-fluid'

  events:
    'change .panel input': 'onChangePanelInput'
    'change #name-input': 'onChangeNameInput'
    'click #toggle-all-btn': 'onClickToggleAllButton'
    'click #delete-account-btn': 'onClickDeleteAccountButton'
    'click #reset-progress-btn': 'onClickResetProgressButton'
    'click .resend-verification-email': 'onClickResendVerificationEmail'

  initialize: ->
    @uploadFilePath = "db/user/#{me.id}"
    @user = new User({_id: me.id})
    @supermodel.trackRequest(@user.fetch()) # use separate, fresh User object instead of `me`

  getEmailSubsDict: ->
    subs = {}
    subs[sub] = 1 for sub in @user.getEnabledEmails()
    return subs

  #- Form input callbacks
  onChangePanelInput: (e) ->
    return if $(e.target).closest('.form').attr('id') in ['reset-progress-form', 'delete-account-form']
    $(e.target).addClass 'changed'
    @trigger 'input-changed'

  onClickToggleAllButton: ->
    subs = @getSubscriptions()
    $('#email-panel input[type="checkbox"]', @$el).prop('checked', not _.any(_.values(subs))).addClass('changed')
    @trigger 'input-changed'

  onChangeNameInput: ->
    name = $('#name-input', @$el).val()
    return if name is @user.get 'name'
    User.getUnconflictedName name, (newName) =>
      forms.clearFormAlerts(@$el)
      if name is newName
        @suggestedName = undefined
      else
        @suggestedName = newName
        forms.setErrorToProperty @$el, 'name', "That name is taken! How about #{newName}?", true

  onClickDeleteAccountButton: (e) ->
    @validateCredentialsForDestruction @$el.find('#delete-account-form'), =>
      renderData =
        title: 'Are you really sure?'
        body: 'This will completely delete your account. This action CANNOT be undone. Are you entirely sure?'
        decline: 'Cancel'
        confirm: 'DELETE Your Account'
      confirmModal = new ConfirmModal renderData
      confirmModal.on 'confirm', @deleteAccount, @
      @openModalView confirmModal

  onClickResetProgressButton: ->
    @validateCredentialsForDestruction @$el.find('#reset-progress-form'), =>
      renderData =
        title: 'Are you really sure?'
        body: 'This will completely erase your progress: code, levels, achievements, earned gems, and course work. This action CANNOT be undone. Are you entirely sure?'
        decline: 'Cancel'
        confirm: 'Erase ALL Progress'
      confirmModal = new ConfirmModal renderData
      confirmModal.on 'confirm', @resetProgress, @
      @openModalView confirmModal

  onClickResendVerificationEmail: (e) ->
    $.post @user.getRequestVerificationEmailURL(), ->
      link = $(e.currentTarget)
      link.find('.resend-text').addClass('hide')
      link.find('.sent-text').removeClass('hide')

  validateCredentialsForDestruction: ($form, onSuccess) ->
    forms.clearFormAlerts($form)
    enteredEmailOrUsername = $form.find('input[name="emailOrUsername"]').val()
    enteredPassword = $form.find('input[name="password"]').val()
    if enteredEmailOrUsername and enteredEmailOrUsername in [@user.get('email'), @user.get('name')]
      isPasswordCorrect = false
      toBeDelayed = true
      $.ajax
        url: '/auth/login'
        type: 'POST'
        data:
          username: enteredEmailOrUsername
          password: enteredPassword
        parse: true
        error: (error) ->
          toBeDelayed = false
          'Bad Error. Can\'t connect to server or something. ' + error
        success: (response, textStatus, jqXHR) ->
          toBeDelayed = false
          return unless jqXHR.status is 200
          isPasswordCorrect = true
      callback = =>
        if toBeDelayed
          setTimeout callback, 100
        else
          if isPasswordCorrect
            onSuccess()
          else
            message = $.i18n.t('account_settings.wrong_password', defaultValue: 'Wrong Password.')
            err = [message: message, property: 'password', formatted: true]
            forms.applyErrorsToForm($form, err)
            $('.nano').nanoScroller({scrollTo: @$el.find('.has-error')})
      setTimeout callback, 100
    else
      message = $.i18n.t('account_settings.wrong_email', defaultValue: 'Wrong Email or Username.')
      err = [message: message, property: 'emailOrUsername', formatted: true]
      forms.applyErrorsToForm($form, err)
      $('.nano').nanoScroller({scrollTo: @$el.find('.has-error')})

  deleteAccount: ->
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
          logoutUser()
        , 500
      error: (jqXHR, status, error) ->
        console.error jqXHR
        noty
          timeout: 5000
          text: "Deleting account failed with error code #{jqXHR.status}"
          type: 'error'
          layout: 'topCenter'
      url: "/db/user/#{@user.id}"

  resetProgress: ->
    $.ajax
      type: 'POST'
      success: =>
        noty
          timeout: 5000
          text: 'Your progress is gone.'
          type: 'success'
          layout: 'topCenter'
        localStorage.clear()
        @user.fetch cache: false
        _.delay (-> window.location.reload()), 1000
      error: (jqXHR, status, error) ->
        console.error jqXHR
        noty
          timeout: 5000
          text: "Resetting progress failed with error code #{jqXHR.status}"
          type: 'error'
          layout: 'topCenter'
      url: "/db/user/#{@user.id}/reset_progress"


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
    res = @user.validate()
    if res?
      console.error 'Couldn\'t save because of validation errors:', res
      forms.applyErrorsToForm(@$el, res)
      $('.nano').nanoScroller({scrollTo: @$el.find('.has-error')})
      return

    return unless @user.hasLocalChanges()

    res = @user.patch()
    return unless res

    res.error =>
      if res.responseJSON?.property
        errors = res.responseJSON
        forms.applyErrorsToForm(@$el, errors)
        $('.nano').nanoScroller({scrollTo: @$el.find('.has-error')})
      else
        noty
          text: res.responseJSON?.message or res.responseText
          type: 'error'
          layout: 'topCenter'
          timeout: 5000
      @trigger 'save-user-error'
    res.success (model, response, options) =>
      me.set(model) # save changes to me
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
      @user.set('password', password1)
    else if password1
      message = $.i18n.t('account_settings.password_repeat', defaultValue: 'Please repeat your password.')
      err = [message: message, property: 'password2', formatted: true]
      forms.applyErrorsToForm(@$el, err)
      $('.nano').nanoScroller({scrollTo: @$el.find('.has-error')})

  grabOtherData: ->
    @$el.find('#name-input').val @suggestedName if @suggestedName
    @user.set 'name', @$el.find('#name-input').val()
    @user.set 'firstName', @$el.find('#first-name-input').val()
    @user.set 'lastName', @$el.find('#last-name-input').val()
    @user.set 'email', @$el.find('#email').val()
    for emailName, enabled of @getSubscriptions()
      @user.setEmailSubscription emailName, enabled

    permissions = []

    unless application.isProduction()
      adminCheckbox = @$el.find('#admin')
      if adminCheckbox.length
        permissions.push 'admin' if adminCheckbox.prop('checked')
      godmodeCheckbox = @$el.find('#godmode')
      if godmodeCheckbox.length
        permissions.push 'godmode' if godmodeCheckbox.prop('checked')
      @user.set('permissions', permissions)
