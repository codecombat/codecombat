{backboneFailure, genericFailure} = require 'lib/errors'
RootView = require 'views/kinds/RootView'
template = require 'templates/admin'

module.exports = class MainAdminView extends RootView
  id: 'admin-view'
  template: template
  lastUserSearchValue: ''

  events:
    'keyup': 'checkForFormSubmissionEnterPress'
    'click #enter-espionage-mode': 'enterEspionageMode'
    'click #user-search-button': 'searchForUser'
    'click #increment-button': 'incrementUserAttribute'

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
      result = ("<tr><td><code>#{user._id}</code></td><td>#{_.escape(user.name or 'Anoner')}</td><td>#{_.escape(user.email)}</td></tr>" for user in users)
      result = "<table class=\"table\">#{result.join('\n')}</table>"
    @$el.find('#user-search-result').html(result)

  onSearchRequestFailure: (jqxhr, status, error) =>
    return if @destroyed
    console.warn "There was an error looking up #{@lastUserSearchValue}:", error

  incrementUserAttribute: (e) ->
    val = $('#increment-field').val()
    me.set(val, me.get(val) + 1)
    me.save()
