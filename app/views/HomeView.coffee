RootView = require 'views/core/RootView'
template = require 'templates/home'

module.exports = class HomeView extends RootView
  id: 'home-view'
  template: template

  events:
    'click #play-button': 'onClickBeginnerCampaign'

  constructor: ->
    super()
    window.tracker?.trackEvent 'Homepage Loaded', category: 'Homepage', ['Google Analytics']
    if not me.get('hourOfCode') and @getQueryVariable 'hour_of_code'
      @setUpHourOfCode()
    elapsed = (new Date() - new Date(me.get('dateCreated')))
    if me.get('hourOfCode') and elapsed < 86400 * 1000 and me.get('preferredLanguage', true) is 'en-US'
      # Show the Hour of Code footer explanation in English until it's been more than a day
      @explainsHourOfCode = true

  getRenderData: ->
    c = super()
    if $.browser
      majorVersion = $.browser.versionNumber
      c.isOldBrowser = true if $.browser.mozilla && majorVersion < 21
      c.isOldBrowser = true if $.browser.chrome && majorVersion < 17
      c.isOldBrowser = true if $.browser.safari && majorVersion < 6
    else
      console.warn 'no more jquery browser version...'
    c.isEnglish = (me.get('preferredLanguage') or 'en').startsWith 'en'
    c.languageName = me.get('preferredLanguage')
    c.explainsHourOfCode = @explainsHourOfCode
    c

  onClickBeginnerCampaign: (e) ->
    @playSound 'menu-button-click'
    e.preventDefault()
    e.stopImmediatePropagation()
    window.tracker?.trackEvent 'Click Play', category: 'Homepage'
    window.open '/play', '_blank'

  afterInsert: ->
    super(arguments...)
    @$el.addClass 'hour-of-code' if @explainsHourOfCode

  setUpHourOfCode: ->
    elapsed = (new Date() - new Date(me.get('dateCreated')))
    if elapsed < 5 * 60 * 1000
      me.set 'hourOfCode', true
      me.patch()
    # We may also insert the tracking pixel for everyone on the WorldMapView so as to count directly-linked visitors.
    $('body').append($('<img src="http://code.org/api/hour/begin_codecombat.png" style="visibility: hidden;">'))
    application.tracker?.trackEvent 'Hour of Code Begin', {}
