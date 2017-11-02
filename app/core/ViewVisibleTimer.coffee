CocoClass = require 'core/CocoClass'

idleTracker = new Idle
  onAway: ->
    Backbone.Mediator.publish 'view-visibility:away', {}
  onAwayBack: ->
    Backbone.Mediator.publish 'view-visibility:away-back', {}
  onHidden: ->
    Backbone.Mediator.publish 'view-visibility:hidden', {}
  onVisible: ->
    Backbone.Mediator.publish 'view-visibility:visible', {}
  awayTimeout: 1000

idleTracker.start()

###
This adds analytics events for when premium features are viewed.

Notes about the structure:

CocoView will trigger an update to the timer, if it exists, any time the view
is hidden/reappears/is inserted.

Any view inheriting from CocoView can call @trackTimeVisible(), which creates
the viewVisibleTimer which CocoView will manage automatically.

Calling @trackTimeVisible({ trackViewLifecycle: true }) will treat the view
being open as the only feature being tracked for that view.

If trackViewLifecycle is not set, the view must implement currentVisiblePremiumFeature
which should return an object describing the premium feature currently in view, or null if none are visible.
CocoView's updateViewVisibleTimer will call this function and update the timer if necessary.

The view should also call updateViewVisibleTimer after any time the visible premium feature may have changed. This function is idempotent.
###
class ViewVisibleTimer extends CocoClass
  subscriptions:
    'view-visibility:away': 'onAway'
    'view-visibility:away-back': 'onAwayBack'
    'view-visibility:hidden': 'onHidden'
    'view-visibility:visible': 'onVisible'
  
  constructor: () ->
    @running = false
    # If the user is inactive for this many seconds, stop the timer and
    #   record the time they were active (NOT including this timeout)
    # If they come back before this timeout, include the time they were "away"
    #   in the timer
    @awayTimeoutLimit = 5 * 1000
    @awayTimeoutId = null
    @throttleRate = 50
    super()

  startTimer: (@featureData) ->
    { viewName, featureName, premiumThang } = @featureData
    if not viewName
      throw new Error('No view name!')
    if @running and window.performance.now() - @startTime > @throttleRate
      throw(new Error('Starting a timer over another one!'))
    if not @running and (not @startTime or window.performance.now() - @startTime > @throttleRate)
      @running = true
      @startTime = window.performance.now()

  stopTimer: ({ subtractTimeout, clearName } = { })->
    subtractTimeout ?= false
    clearName ?= false
    clearTimeout(@awayTimeoutId)
    if @running
      @running = false
      @endTime = if subtractTimeout then @lastActive else window.performance.now()
      timeViewed = @endTime - @startTime
      if timeViewed > @throttleRate # Prevent event spam when triggered in rapid succession
        window.tracker.trackEvent 'Premium Feature Viewed', { @featureData, timeViewed }
    @featureData = null if clearName
    
  markLastActive: ->
    @lastActive = window.performance.now()

  onAway: ->
    @markLastActive()
    e = new Error()
    if @running
      @awayTimeoutId = setTimeout(( =>
        @stopTimer({ subtractTimeout: true })
      ), @awayTimeoutLimit)
    
  onAwayBack: ->
    clearTimeout(@awayTimeoutId)
    @startTimer(@featureData) if not @running and @featureData
    
  onHidden: ->
    @stopTimer({ subtractTimeout: false })
    
  onVisible: ->
    @startTimer(@featureData) if @featureData
    
  destroy: ->
    @stopTimer()
    super()

module.exports = ViewVisibleTimer
