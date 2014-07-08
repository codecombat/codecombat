View = require 'views/kinds/RootView'
template = require 'templates/account/settings'
{me} = require 'lib/auth'
forms = require 'lib/forms'
User = require 'models/User'
AuthModalView = require 'views/modal/auth_modal'

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
    @listenTo(me, 'invalid', (errors) -> forms.applyErrorsToForm(@$el, me.validationError))

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

    @chooseTab(location.hash.replace('#', ''))

    wizardSettingsView = new WizardSettingsView()
    @listenTo wizardSettingsView, 'change', @save
    @insertSubView wizardSettingsView

    @jobProfileView = new JobProfileView()
    @listenTo @jobProfileView, 'change', @save
    @insertSubView @jobProfileView
    _.defer => @buildPictureTreema()  # Not sure why, but the Treemas don't fully build without this if you reload the page.

  afterInsert: ->
    super()
    if me.get('anonymous')
      @openModalView new AuthModalView()

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
    c.subs = {}
    c.subs[sub] = 1 for sub in c.me.getEnabledEmails()
    c.showsJobProfileTab = me.isAdmin() or me.get('jobProfile') or location.hash.search('job-profile-') isnt -1
    c

  getSubscriptions: ->
    inputs = ($(i) for i in $('#email-pane input[type="checkbox"].changed', @$el))
    emailNames = (i.attr('name').replace('email_', '') for i in inputs)
    enableds = (i.prop('checked') for i in inputs)
    _.zipObject emailNames, enableds

  toggleEmailSubscriptions: =>
    subs = @getSubscriptions()
    $('#email-pane input[type="checkbox"]', @$el).prop('checked', not _.any(_.values(subs))).addClass('changed')
    @save()

  buildPictureTreema: ->
    data = photoURL: me.get('photoURL')
    data.photoURL = null if data.photoURL?.search('gravatar') isnt -1  # Old style
    schema = $.extend true, {}, me.schema()
    schema.properties = _.pick me.schema().properties, 'photoURL'
    schema.required = ['photoURL']
    treemaOptions =
      filePath: "db/user/#{me.id}"
      schema: schema
      data: data
      callbacks: {change: @onPictureChanged}

    @pictureTreema = @$el.find('#picture-treema').treema treemaOptions
    @pictureTreema?.build()
    @pictureTreema?.open()
    @$el.find('.gravatar-fallback').toggle not me.get 'photoURL'

  onPictureChanged: (e) =>
    @trigger 'change'
    @$el.find('.gravatar-fallback').toggle not me.get 'photoURL'

  save: (e) ->
    $(e.target).addClass('changed') if e
    forms.clearFormAlerts(@$el)
    @grabData()
    res = me.validate()
    if res?
      console.error 'Couldn\'t save because of validation errors:', res
      forms.applyErrorsToForm(@$el, res)
      return

    return unless me.hasLocalChanges()

    res = me.patch()
    return unless res
    save = $('#save-button', @$el).text($.i18n.t('common.saving', defaultValue: 'Saving...'))
      .removeClass('btn-danger').addClass('btn-success').show()

    res.error ->
      errors = JSON.parse(res.responseText)
      forms.applyErrorsToForm(@$el, errors)
      save.text($.i18n.t('account_settings.error_saving', defaultValue: 'Error Saving')).removeClass('btn-success').addClass('btn-danger', 500)
    res.success (model, response, options) ->
      save.text($.i18n.t('account_settings.saved', defaultValue: 'Changes Saved')).removeClass('btn-success', 500)

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
      return
    if bothThere
      me.set('password', password1)

  grabOtherData: ->
    me.set 'name', $('#name', @$el).val()
    me.set 'email', $('#email', @$el).val()
    for emailName, enabled of @getSubscriptions()
      me.setEmailSubscription emailName, enabled
    me.set 'photoURL', @pictureTreema.get('/photoURL')

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
      jobProfile.updated = (new Date()).toISOString()
      me.set 'jobProfile', jobProfile
