CocoView = require 'views/core/CocoView'
State = require 'models/State'
utils = require 'core/utils'

HINT_FREQUENCY = 2 * 60

module.exports = class HintsView extends CocoView
  
  template: require('templates/play/level/hints-view')
  className: 'hints-view'
  
  events:
    'click .next-btn': 'onClickNextButton'
    'click .previous-btn': 'onClickPreviousButton'
    'click .close-hint-btn': 'toggleVisibility'
  
  initialize: ({@level, @session}) ->
    @hints = @level.get('documentation')?.hints or []
    @state = new State({
      hintsTotal: _.size(@hints)
      hintIndex: 0
      hintsAvailable: 0
    })
    @updateHint()
    
    @listenTo(@session, 'change:playtime', @updateHintsAvailable)
    @listenTo(@state, 'change', _.debounce(@render))
    @listenTo(@state, 'change:hintIndex', @updateHint)

  getProcessedHint: ->
    language = @session.get('codeLanguage')
    hint = @state.get('hint')
    
    # process
    translated = utils.i18n(hint, 'body')
    filtered = utils.filterMarkdownCodeLanguages(translated, language)
    markedUp = marked(filtered)
    
    return markedUp
  
  updateHintsAvailable: ->
    total = _.size(@hints)
    maximum = Math.floor(@session.get('playtime') / HINT_FREQUENCY)
    @state.set({ hintsAvailable: Math.min(total, maximum) })
    
  updateHint: ->
    index = @state.get('hintIndex')
    hintsTitle = $.i18n.t('play_level.hints_title').replace('{{number}}', index + 1)
    @state.set({ hintsTitle, hint: @hints[index] })

  onClickNextButton: ->
    max = @state.get('hintsTotal') - 1
    @state.set('hintIndex', Math.min(@state.get('hintIndex') + 1, max))
    @playSound 'menu-button-click'

  onClickPreviousButton: ->
    @state.set('hintIndex', Math.max(@state.get('hintIndex') - 1, 0))
    @playSound 'menu-button-click'

  toggleVisibility: -> @$el.toggleClass('hide')
