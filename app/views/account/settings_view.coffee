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
  changedFields: [] # DOM input fields

  events:
    'click #save-button': 'save'
    'change #settings-panes input:checkbox': (e) -> @trigger 'checkboxToggled', e
    'keyup #settings-panes input:text, #settings-panes input:password': (e) -> @trigger 'inputChanged', e
    'keyup #name': 'onNameChange'
    'click #toggle-all-button': 'toggleEmailSubscriptions'
    'keypress #settings-panes': 'onKeyPress'

  constructor: (options) ->
    @save =  _.debounce(@save, 200)
    @onNameChange = _.debounce @checkNameExists, 500
    super options
    return unless me

    @listenTo(me, 'invalid', (errors) -> forms.applyErrorsToForm(@$el, me.validationError))
    @on 'checkboxToggled', @onToggle
    @on 'checkboxToggled', @onInputChanged
    @on 'inputChanged', @onInputChanged
    @on 'enterPressed', @onEnter

  onInputChanged: (e) ->
    return @enableSaveButton() unless e?.currentTarget
    that = e.currentTarget
    $that = $(that)
    savedValue = $that.data 'saved-value'
    currentValue = $that.val()
    if savedValue isnt currentValue
      @changedFields.push that unless that in @changedFields
      @enableSaveButton()
    else
      _.pull @changedFields, that
      @disableSaveButton() if _.isEmpty @changedFields

  onToggle: (e) ->
    $that = $(e.currentTarget)
    $that.val $that[0].checked

  onEnter: ->
    @save()

  onKeyPress: (e) ->
    @trigger 'enterPressed', e if e.which is 13

  enableSaveButton: ->
    $('#save-button', @$el).removeClass 'disabled'
    $('#save-button', @$el).removeClass 'btn-danger'
    $('#save-button', @$el).removeAttr 'disabled'
    $('#save-button', @$el).text 'Save'

  disableSaveButton: ->
    $('#save-button', @$el).addClass 'disabled'
    $('#save-button', @$el).removeClass 'btn-danger'
    $('#save-button', @$el).attr 'disabled', "true"
    $('#save-button', @$el).text 'No Changes'

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

  afterRender: ->
    super()
    $('#settings-tabs a', @$el).click((e) =>
      e.preventDefault()
      $(e.target).tab('show')

      # make sure errors show up in the general pane, but keep the password pane clean
      $('#password-pane input').val('')
      #@save() unless $(e.target).attr('href') is '#password-pane'
      forms.clearFormAlerts($('#password-pane', @$el))
    )

    @chooseTab(location.hash.replace('#', ''))

    wizardSettingsView = new WizardSettingsView()
    @listenTo wizardSettingsView, 'change', @enableSaveButton
    @insertSubView wizardSettingsView

    @jobProfileView = new JobProfileView()
    @listenTo @jobProfileView, 'change', @enableSaveButton
    @insertSubView @jobProfileView
    _.defer => @buildPictureTreema()  # Not sure why, but the Treemas don't fully build without this if you reload the page.

  afterInsert: ->
    super()
    $('#email-pane input[type="checkbox"]').on 'change', ->
      $(@).addClass 'changed'
    if me.get('anonymous')
      @openModalView new AuthModalView()
    @updateSavedValues()

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
    @trigger 'inputChanged', e
    @$el.find('.gravatar-fallback').toggle not me.get 'photoURL'

  save: (e) ->
    $('#settings-tabs input').removeClass 'changed'
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
    res.success (model, response, options) =>
      @changedFields = []
      @updateSavedValues()
      save.text($.i18n.t('account_settings.saved', defaultValue: 'Changes Saved')).removeClass('btn-success', 500).attr('disabled', 'true')

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
    else if password1
      message = $.i18n.t('account_settings.password_repeat', defaultValue: 'Please repeat your password.')
      err = [message: message, property: 'password2', formatted: true]
      forms.applyErrorsToForm(@$el, err)

  grabOtherData: ->
    $('#name', @$el).val @suggestedName if @suggestedName
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
      updated = updated or not _.isEqual jobProfile[key], val
      jobProfile[key] = val
    if updated
      jobProfile.updated = (new Date()).toISOString()
      me.set 'jobProfile', jobProfile

  updateSavedValues: ->
    $('#settings-panes input:text').each ->
      $(@).data 'saved-value', $(@).val()
    $('#settings-panes input:checkbox').each ->
      $(@).data 'saved-value', JSON.stringify $(@)[0].checked
