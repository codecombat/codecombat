CocoView = require 'views/core/CocoView'
State = require 'models/State'
utils = require 'core/utils'

module.exports = class HintsView extends CocoView
  template: require('templates/play/level/hints-view')
  className: 'hints-view'
  hintUsedThresholdSeconds: 10

  events:
    'click .next-btn': 'onClickNextButton'
    'click .previous-btn': 'onClickPreviousButton'
    'click .close-hint-btn': 'hideView'

  subscriptions:
    'level:show-victory': 'hideView'
    'tome:manual-cast': 'hideView'

  initialize: (options) ->
    {@level, @session, @hintsState} = options
    @state = new State({
      hintIndex: 0
      hintsViewTime: {}
      hintsUsed: {}
    })
    @updateHint()
    
    debouncedRender = _.debounce(@render)
    @listenTo(@state, 'change', debouncedRender)
    @listenTo(@hintsState, 'change', debouncedRender)
    @listenTo(@state, 'change:hintIndex', @updateHint)
    @listenTo(@hintsState, 'change:hidden', @visibilityChanged)

  destroy: ->
    clearInterval(@timerIntervalID)
    super()

  afterRender: ->
    @$el.toggleClass('hide', @hintsState.get('hidden'))
    super()

  getProcessedHint: ->
    language = @session.get('codeLanguage')
    hint = @state.get('hint')
    return unless hint

    # process
    translated = utils.i18n(hint, 'body')
    filtered = utils.filterMarkdownCodeLanguages(translated, language)
    markedUp = marked(filtered)
    
    return markedUp
  
  updateHint: ->
    index = @state.get('hintIndex')
    hintsTitle = $.i18n.t('play_level.hints_title').replace('{{number}}', index + 1)
    @state.set({ hintsTitle, hint: @hintsState.getHint(index) })

  onClickNextButton: ->
    window.tracker?.trackEvent 'Hints Next Clicked', category: 'Students', levelSlug: @level.get('slug'), hintCount: @hintsState.get('hints')?.length ? 0, hintCurrent: @state.get('hintIndex'), ['Mixpanel']
    max = @hintsState.get('total') - 1
    @state.set('hintIndex', Math.min(@state.get('hintIndex') + 1, max))
    @playSound 'menu-button-click'
    @updateHintTimer()

  onClickPreviousButton: ->
    window.tracker?.trackEvent 'Hints Previous Clicked', category: 'Students', levelSlug: @level.get('slug'), hintCount: @hintsState.get('hints')?.length ? 0, hintCurrent: @state.get('hintIndex'), ['Mixpanel']
    @state.set('hintIndex', Math.max(@state.get('hintIndex') - 1, 0))
    @playSound 'menu-button-click'
    @updateHintTimer()

  hideView: -> @hintsState?.set('hidden', true)

  visibilityChanged: (e) ->
    @updateHintTimer()

  updateHintTimer: ->
    clearInterval(@timerIntervalID)
    unless @hintsState.get('hidden') or @state.get('hintsUsed')?[@state.get('hintIndex')]
      @timerIntervalID = setInterval(@incrementHintViewTime, 1000)

  incrementHintViewTime: =>
    hintIndex = @state.get('hintIndex')
    hintsViewTime = @state.get('hintsViewTime')
    hintsViewTime[hintIndex] ?= 0
    hintsViewTime[hintIndex]++
    hintsUsed = @state.get('hintsUsed')
    if hintsViewTime[hintIndex] > @hintUsedThresholdSeconds and not hintsUsed[hintIndex] 
      window.tracker?.trackEvent 'Hint Used', category: 'Students', levelSlug: @level.get('slug'), hintCount: @hintsState.get('hints')?.length ? 0, hintCurrent: hintIndex, ['Mixpanel']
      hintsUsed[hintIndex] = true
      @state.set('hintsUsed', hintsUsed)
      clearInterval(@timerIntervalID)
    @state.set('hintsViewTime', hintsViewTime)

