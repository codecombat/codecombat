View = require 'views/kinds/RootView'
template = require 'templates/account/settings'
{me} = require('lib/auth')
forms = require('lib/forms')
User = require('models/User')

WizardSettingsView = require './wizard_settings_view'
JobProfileView = require './job_profile_view'

module.exports = class SettingsView extends View
  id: 'account-settings-view'
  template: template

  events:
    'click #save-button': 'save'
    'change #settings-panes input': 'save'
    'click #toggle-all-button': 'toggleEmailSubscriptions'

  constructor: (options) ->
    @save =  _.debounce(@save, 200)
    super options
    return unless me
    @listenTo(me, 'change', @refreshPicturePane) # depends on gravatar load
    @listenTo(me, 'invalid', (errors) -> forms.applyErrorsToForm(@$el, me.validationError))
    window.f = @getSubscriptions

  refreshPicturePane: ->
    h = $(@template(@getRenderData()))
    newPane = $('#picture-pane', h)
    oldPane = $('#picture-pane')
    active = oldPane.hasClass('active')
    oldPane.replaceWith(newPane)
    newPane.i18n()
    newPane.addClass('active') if active

  afterRender: ->
    super()
    $('#settings-tabs a', @$el).click((e) =>
      e.preventDefault()
      $(e.target).tab('show')

      # make sure errors show up in the general pane, but keep the password pane clean
      $('#password-pane input').val('')
      @save() unless $(e.target).attr('href') is '#password-pane'
      forms.clearFormAlerts($('#password-pane', @$el))
    )

    @chooseTab(location.hash.replace('#',''))

    wizardSettingsView = new WizardSettingsView()
    @listenTo wizardSettingsView, 'change', @save
    @insertSubView wizardSettingsView

    @jobProfileView = new JobProfileView()
    @listenTo @jobProfileView, 'change', @save
    @insertSubView @jobProfileView

  chooseTab: (category) ->
    id = "##{category}-pane"
    pane = $(id, @$el)
    return @chooseTab('general') unless pane.length or category is 'general'
    loc = "a[href=#{id}]"
    $(loc, @$el).tab('show')
    $('.tab-pane').removeClass('active')
    pane.addClass('active')
    @currentTab = category

  getRenderData: ->
    c = super()
    return c unless me
    c.gravatarName = c.me?.gravatarName()
    c.photos = me.gravatarPhotoURLs()
    c.chosenPhoto = me.getPhotoURL()
    c.subs = {}
    c.subs[sub] = 1 for sub in c.me.get('emailSubscriptions') or ['announcement', 'notification', 'tester', 'level_creator', 'developer']
    c

  getSubscriptions: ->
    inputs = $('#email-pane input[type="checkbox"]', @$el)
    inputs = ($(i) for i in inputs)
    subs = (i.attr('name') for i in inputs when i.prop('checked'))
    subs = (s.replace('email_', '') for s in subs)
    subs

  toggleEmailSubscriptions: =>
    subs = @getSubscriptions()
    $('#email-pane input[type="checkbox"]', @$el).prop('checked', not Boolean(subs.length))
    @save()

  save: ->
    forms.clearFormAlerts(@$el)
    @grabData()
    res = me.validate()
    if res?
      forms.applyErrorsToForm(@$el, res)
      return

    return unless me.hasLocalChanges()

    res = me.save()
    return unless res
    save = $('#save-button', @$el).text($.i18n.t('common.saving', defaultValue: 'Saving...'))
      .addClass('btn-info').show().removeClass('btn-danger')

    res.error ->
      errors = JSON.parse(res.responseText)
      forms.applyErrorsToForm(@$el, errors)
      save.text($.i18n.t('account_settings.error_saving', defaultValue: 'Error Saving')).removeClass('btn-info').addClass('btn-danger')
    res.success (model, response, options) ->
      save.text($.i18n.t('account_settings.saved', defaultValue: 'Changes Saved')).removeClass('btn-info')

  grabData: ->
    @grabPasswordData()
    @grabOtherData()

  grabPasswordData: ->
    password1 = $('#password', @$el).val()
    password2 = $('#password2', @$el).val()
    bothThere = Boolean(password1) and Boolean(password2)
    if bothThere and password1 isnt password2
      message = $.i18n.t('account_settings.password_mismatch', defaultValue: 'Password does not match.')
      err = [message:message, property:'password2', formatted:true]
      forms.applyErrorsToForm(@$el, err)
      return
    if bothThere
      me.set('password', password1)

  grabOtherData: ->
    me.set('name', $('#name', @$el).val())
    me.set('email', $('#email', @$el).val())
    me.set('emailSubscriptions', @getSubscriptions())

    adminCheckbox = @$el.find('#admin')
    if adminCheckbox.length
      permissions = []
      permissions.push 'admin' if adminCheckbox.prop('checked')
      me.set('permissions', permissions)

    jobProfile = me.get('jobProfile') ? {}
    updated = false
    for key, val of @jobProfileView.getData()
      updated = updated or jobProfile[key] isnt val
      jobProfile[key] = val
    if updated
      #jobProfile.updated = new Date()  # doesn't work
      me.set 'jobProfile', jobProfile
