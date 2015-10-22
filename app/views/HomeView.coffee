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
    if not me.get('hourOfCode') and @getQueryVariable 'hour_of_code'
      @setUpHourOfCode()
    elapsed = (new Date() - new Date(me.get('dateCreated')))
    if me.get('hourOfCode') and elapsed < 86400 * 1000 and me.get('preferredLanguage', true) is 'en-US'
      # Show the Hour of Code footer explanation in English until it's been more than a day
      @explainsHourOfCode = true

  onClickPlayButton: (e) ->
    @playSound 'menu-button-click'
    e.preventDefault()
    e.stopImmediatePropagation()
    window.tracker?.trackEvent 'Click Play', category: 'Homepage'
    window.open '/play', '_blank'

  afterInsert: ->
    super(arguments...)
    @$el.addClass 'hour-of-code' if @explainsHourOfCode

  isOldBrowser: ->
    if $.browser
      majorVersion = $.browser.versionNumber
      return true if $.browser.mozilla && majorVersion < 25
      return true if $.browser.chrome && majorVersion < 31  # Noticed Gems in the Deep not loading with 30
      return true if $.browser.safari && majorVersion < 6  # 6 might have problems with Aether, or maybe just old minors of 6: https://errorception.com/projects/51a79585ee207206390002a2/errors/547a202e1ead63ba4e4ac9fd
    else
      console.warn 'no more jquery browser version...'
    return false

  setUpHourOfCode: ->
    # All this HoC stuff is for the 2014-2015 year. 2015-2016 year lands at /hoc instead (the courses view).
    # TODO: get rid of all this sometime in November 2015 when code.org/learn updates to the new version for Hour of Code tutorials.
    elapsed = (new Date() - new Date(me.get('dateCreated')))
    if elapsed < 5 * 60 * 1000
      me.set 'hourOfCode', true
      me.patch()
    # We may also insert the tracking pixel for everyone on the CampaignView so as to count directly-linked visitors.
    $('body').append($('<img src="https://code.org/api/hour/begin_codecombat.png" style="visibility: hidden;">'))
    application.tracker?.trackEvent 'Hour of Code Begin'
