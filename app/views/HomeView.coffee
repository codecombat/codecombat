RootView = require 'views/core/RootView'
template = require 'templates/home-view'

module.exports = class HomeView extends RootView
  id: 'home-view'
  template: template

  events:
    'click #play-button': 'onClickBeginnerCampaign'

  constructor: ->
    super()
    window.tracker?.trackEvent 'Homepage Loaded', category: 'Homepage'
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
      c.isOldBrowser = true if $.browser.mozilla && majorVersion < 25
      c.isOldBrowser = true if $.browser.chrome && majorVersion < 31  # Noticed Gems in the Deep not loading with 30
      c.isOldBrowser = true if $.browser.safari && majorVersion < 6  # 6 might have problems with Aether, or maybe just old minors of 6: https://errorception.com/projects/51a79585ee207206390002a2/errors/547a202e1ead63ba4e4ac9fd
    else
      console.warn 'no more jquery browser version...'
    c.isEnglish = _.string.startsWith (me.get('preferredLanguage') or 'en'), 'en'
    c.languageName = me.get('preferredLanguage')
    c.explainsHourOfCode = @explainsHourOfCode
    c.isMobile = @isMobile()
    c.isIPadBrowser = @isIPadBrowser()
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
    # We may also insert the tracking pixel for everyone on the CampaignView so as to count directly-linked visitors.
    $('body').append($('<img src="https://code.org/api/hour/begin_codecombat.png" style="visibility: hidden;">'))
    application.tracker?.trackEvent 'Hour of Code Begin'
