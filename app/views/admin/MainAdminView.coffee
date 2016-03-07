{backboneFailure, genericFailure} = require 'core/errors'
errors = require 'core/errors'
RootView = require 'views/core/RootView'
template = require 'templates/admin'
AdministerUserModal = require 'views/admin/AdministerUserModal'
forms = require 'core/forms'
User = require 'models/User'

module.exports = class MainAdminView extends RootView
  id: 'admin-view'
  template: template
  lastUserSearchValue: ''

  events:
    'submit #espionage-form': 'onSubmitEspionageForm'
    'submit #user-search-form': 'onSubmitUserSearchForm'
    'click #stop-spying-btn': 'onClickStopSpyingButton'
    'click #increment-button': 'incrementUserAttribute'
    'click #user-search-result': 'onClickUserSearchResult'
    'click #create-free-sub-btn': 'onClickFreeSubLink'
    'click #terminal-create': 'onClickTerminalSubLink'
    
  initialize: ->
    if window.amActually
      @amActually = new User({_id: window.amActually})
      @amActually.fetch()
      @supermodel.trackModel(@amActually)

  onClickStopSpyingButton: ->
    button = @$('#stop-spying-btn')
    forms.disableSubmit(button)
    me.stopSpying({
      success: -> document.location.reload()
      error: ->
        forms.enableSubmit(button)
        errors.showNotyNetworkError(arguments...)
    })

  onSubmitEspionageForm: (e) ->
    e.preventDefault()
    button = @$('#enter-espionage-mode')
    userNameOrEmail = @$el.find('#espionage-name-or-email').val().toLowerCase()
    forms.disableSubmit(button)
    me.spy(userNameOrEmail, {
      success: -> window.location.reload()
      error: ->
        forms.enableSubmit(button)
        errors.showNotyNetworkError(arguments...)
    })

  onSubmitUserSearchForm: (e) ->
    e.preventDefault()
    searchValue = @$el.find('#user-search').val()
    return if searchValue is @lastUserSearchValue
    return @onSearchRequestSuccess [] unless @lastUserSearchValue = searchValue.toLowerCase()
    forms.disableSubmit(@$('#user-search-button'))
    $.ajax
      type: 'POST',
      url: '/db/user/-/admin_search'
      data: {search: @lastUserSearchValue}
      success: @onSearchRequestSuccess
      error: @onSearchRequestFailure

  onSearchRequestSuccess: (users) =>
    forms.enableSubmit(@$('#user-search-button'))
    result = ''
    if users.length
      result = ("<tr data-user-id='#{user._id}'><td><code>#{user._id}</code></td><td>#{_.escape(user.name or 'Anoner')}</td><td>#{_.escape(user.email)}</td></tr>" for user in users)
      result = "<table class=\"table\">#{result.join('\n')}</table>"
    @$el.find('#user-search-result').html(result)

  onSearchRequestFailure: (jqxhr, status, error) =>
    return if @destroyed
    forms.enableSubmit(@$('#user-search-button'))
    console.warn "There was an error looking up #{@lastUserSearchValue}:", error

  incrementUserAttribute: (e) ->
    val = $('#increment-field').val()
    me.set(val, me.get(val) + 1)
    me.save()

  onClickUserSearchResult: (e) ->
    userID = $(e.target).closest('tr').data('user-id')
    @openModalView new AdministerUserModal({}, userID) if userID

  onClickFreeSubLink: (e) =>
    delete @freeSubLink
    return unless me.isAdmin()
    options =
      url: '/db/prepaid/-/create'
      data: {type: 'subscription', maxRedeemers: 1}
      method: 'POST'
    options.success = (model, response, options) =>
      # TODO: Don't hardcode domain.
      if application.isProduction()
        @freeSubLink = "https://codecombat.com/account/subscription?_ppc=#{model.code}"
      else
        @freeSubLink = "http://localhost:3000/account/subscription?_ppc=#{model.code}"
      @render?()
    options.error = (model, response, options) =>
      console.error 'Failed to create prepaid', response
    @supermodel.addRequestResource('create_prepaid', options, 0).load()

  onClickTerminalSubLink: (e) =>
    @freeSubLink = ''
    return unless me.isAdmin()

    options =
      url: '/db/prepaid/-/create'
      method: 'POST'
      data:
        type: 'terminal_subscription'
        maxRedeemers: parseInt($("#users").val())
        months: parseInt($("#months").val())

    options.success = (model, response, options) =>
      # TODO: Don't hardcode domain.
      if application.isProduction()
        @freeSubLink = "https://codecombat.com/account/prepaid?_ppc=#{model.code}"
      else
        @freeSubLink = "http://localhost:3000/account/prepaid?_ppc=#{model.code}"
      @render?()
    options.error = (model, response, options) =>
      console.error 'Failed to create prepaid', response
    @supermodel.addRequestResource('create_prepaid', options, 0).load()

