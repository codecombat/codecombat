RootView = require 'views/core/RootView'
template = require 'templates/home-view'

module.exports = class HomeView extends RootView
  id: 'home-view'
  template: template

  events:
    'click #play-button': 'onClickPlayButton'

  constructor: ->
    super()
    window.tracker?.trackEvent 'Homepage Loaded', category: 'Homepage'
    if @getQueryVariable 'hour_of_code'
      application.router.navigate "/hoc", trigger: true

  onClickPlayButton: (e) ->
    @playSound 'menu-button-click'
    e.preventDefault()
    e.stopImmediatePropagation()
    window.tracker?.trackEvent 'Click Play', category: 'Homepage'
    window.open '/play', '_blank'

  afterInsert: ->
    super(arguments...)

  isOldBrowser: ->
    if $.browser
      majorVersion = $.browser.versionNumber
      return true if $.browser.mozilla && majorVersion < 25
      return true if $.browser.chrome && majorVersion < 31  # Noticed Gems in the Deep not loading with 30
      return true if $.browser.safari && majorVersion < 6  # 6 might have problems with Aether, or maybe just old minors of 6: https://errorception.com/projects/51a79585ee207206390002a2/errors/547a202e1ead63ba4e4ac9fd
    else
      console.warn 'no more jquery browser version...'
    return false
