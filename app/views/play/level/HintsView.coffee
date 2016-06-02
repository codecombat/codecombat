CocoView = require 'views/core/CocoView'
State = require 'models/State'
utils = require 'core/utils'

module.exports = class HintsView extends CocoView
  
  template: require('templates/play/level/hints-view')
  className: 'hints-view'
  
  events:
    'click .next-btn': 'onClickNextButton'
    'click .previous-btn': 'onClickPreviousButton'
    'click .close-hint-btn': 'toggleVisibility'
  
  initialize: (options) ->
    {@level, @session, @hintsState} = options
    @hints = @level.get('documentation')?.hints or []
    @state = new State({
      hintIndex: 0
    })
    @updateHint()
    
    debouncedRender = _.debounce(@render)
    @listenTo(@state, 'change', debouncedRender)
    @listenTo(@hintsState, 'change', debouncedRender)
    @listenTo(@state, 'change:hintIndex', @updateHint)
    
  afterRender: ->
    @$el.toggleClass('hide', @hintsState.get('hidden'))
    super()

  getProcessedHint: ->
    language = @session.get('codeLanguage')
    hint = @state.get('hint')
    
    # process
    translated = utils.i18n(hint, 'body')
    filtered = utils.filterMarkdownCodeLanguages(translated, language)
    markedUp = marked(filtered)
    
    return markedUp
  
  updateHint: ->
    index = @state.get('hintIndex')
    hintsTitle = $.i18n.t('play_level.hints_title').replace('{{number}}', index + 1)
    @state.set({ hintsTitle, hint: @hints[index] })

  onClickNextButton: ->
    max = @hintsState.get('total') - 1
    @state.set('hintIndex', Math.min(@state.get('hintIndex') + 1, max))
    @playSound 'menu-button-click'

  onClickPreviousButton: ->
    @state.set('hintIndex', Math.max(@state.get('hintIndex') - 1, 0))
    @playSound 'menu-button-click'

  toggleVisibility: -> @hintsState.set('hidden', not @hintsState.get('hidden'))
