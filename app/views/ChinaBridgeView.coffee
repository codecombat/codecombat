require('app/styles/china-bridge.sass')
RootView = require 'views/core/RootView'
template = require 'templates/china-bridge-view'
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
    if @history
      setTimeout @goRedirect, 5000

  goRedirect: (value) =>
    redirectURL = utils.getQueryVariable 'redirect'
    url = if (value or @history) == 'koudashijie' then 'https://koudashijie.com' else 'https://codecombat.163.com'
    if redirectURL
      url += redirectURL
    window.location.href = url

  setRedirect: (redirect) -> storage.save('redirect', redirect)
  getRedirect: -> storage.load('redirect')

  onClickOne: (e) ->
    @setRedirect("koudashijie");
    @goRedirect("koudashijie")

  onClickTwo: (e) ->
    @setRedirect("netease");
    @goRedirect("netease")
