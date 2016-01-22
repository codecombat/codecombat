{backboneFailure, genericFailure} = require 'core/errors'
RootView = require 'views/core/RootView'
template = require 'templates/admin'
AdministerUserModal = require 'views/admin/AdministerUserModal'

module.exports = class MainAdminView extends RootView
  id: 'admin-view'
  template: template
  lastUserSearchValue: ''

  events:
    'keyup': 'checkForFormSubmissionEnterPress'
    'click #enter-espionage-mode': 'enterEspionageMode'
    'click #user-search-button': 'searchForUser'
    'click #increment-button': 'incrementUserAttribute'
    'click #user-search-result': 'onClickUserSearchResult'
    'click #create-free-sub-btn': 'onClickFreeSubLink'
    'click #terminal-create': 'onClickTerminalSubLink'

  checkForFormSubmissionEnterPress: (e) ->
    if e.which is 13 and @$el.find('#espionage-name-or-email').val() isnt ''
      @enterEspionageMode()
      return
    if @$el.find('#user-search').val() isnt @lastUserSearchValue
      @searchForUser()

  enterEspionageMode: ->
    userNameOrEmail = @$el.find('#espionage-name-or-email').val().toLowerCase()
    $.ajax
      type: 'POST',
      url: '/auth/spy'
      data: {nameOrEmailLower: userNameOrEmail}
      success: @espionageSuccess
      error: @espionageFailure

  espionageSuccess: (model) ->
    window.location.reload()

  espionageFailure: (jqxhr, status, error)->
    console.log "There was an error entering espionage mode: #{error}"

  searchForUser: ->
    return @onSearchRequestSuccess [] unless @lastUserSearchValue = @$el.find('#user-search').val().toLowerCase()
    $.ajax
      type: 'POST',
      url: '/db/user/-/admin_search'
      data: {search: @lastUserSearchValue}
      success: @onSearchRequestSuccess
      error: @onSearchRequestFailure

  onSearchRequestSuccess: (users) =>
    result = ''
    if users.length
      result = ("<tr data-user-id='#{user._id}'><td><code>#{user._id}</code></td><td>#{_.escape(user.name or 'Anoner')}</td><td>#{_.escape(user.email)}</td></tr>" for user in users)
      result = "<table class=\"table\">#{result.join('\n')}</table>"
    @$el.find('#user-search-result').html(result)

  onSearchRequestFailure: (jqxhr, status, error) =>
    return if @destroyed
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

