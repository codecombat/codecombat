require('app/styles/contact-geek.sass')
RootView = require 'views/core/RootView'
template = require 'templates/contact-geek-view'
utils = require 'core/utils'
storage = require 'core/storage'


module.exports = class ContactGEEKView extends RootView
  id: 'contact-geek-view'
  template: template

  events:
    'click .one': 'onClickOne'
    'click .two': 'onClickTwo'

  initialize: (options) ->
    super(options)
    @history = @getRedirect()
    console.log @history
    if @history
      setTimeout @goRedirect, 5000

  goRedirect: (value) ->
    @redirect = utils.getQueryVariable 'redirect'
    url = if parseInt(value||@getRedirect) == 1 then 'https://koudashijie.com' else 'https://codecombat.163.com/#/'
    if @redirect
      url += '?redirect='+@redirect
    window.location.href = url

  setRedirect: (redirect) -> storage.save('redirect', redirect)
  getRedirect: -> storage.load('redirect')

  onClickOne: (e) ->
    @setRedirect("1");
    @goRedirect("1")

  onClickTwo: (e) ->
    @setRedirect("2");
    @goRedirect("2")
