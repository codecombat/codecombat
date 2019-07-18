require 'ozaria/site/styles/play/level/tome/spell_toolbar.sass'
CocoView = require 'views/core/CocoView'
template = require 'ozaria/site/templates/play/level/tome/spell_toolbar'

module.exports = class SpellToolbarView extends CocoView
  className: 'spell-toolbar-view'
  template: template
  progressHoverDelay: 500

  subscriptions:
    'tome:spell-step-backward': 'onStepBackward'
    'tome:spell-step-forward': 'onStepForward'

  events:
    'mousedown .spell-progress': 'onProgressMouseDown'
    'mouseup .spell-progress': 'onProgressMouseUp'
    'mousemove .spell-progress': 'onProgressMouseMove'
    'tapstart .spell-progress': 'onProgressTapStart'
    'tapend .spell-progress': 'onProgressTapEnd'
    'tapmove .spell-progress': 'onProgressTapMove'
    'click .step-backward': 'onStepBackward'
    'click .step-forward': 'onStepForward'

  constructor: (options) ->
    super options
    @ace = options.ace

  afterRender: ->
    super()

  toggleFlow: (to) ->
    @$el.find('.flow').toggle to

  setStatementIndex: (statementIndex) ->
    return unless total = @callState?.statementsExecuted
    @statementIndex = Math.min(total - 1, Math.max(0, statementIndex))
    @statementRatio = @statementIndex / (total - 1)
    @statementTime = @callState.statements[@statementIndex]?.userInfo.time ? 0
    @$el.find('.progress-bar').css('width', 100 * @statementRatio + '%')
    @$el.find('.step-backward').prop('disabled', @statementIndex is 0)
    @$el.find('.step-forward').prop('disabled', @statementIndex is total - 1)
    @updateMetrics()
    _.defer =>
      Backbone.Mediator.publish 'tome:spell-statement-index-updated', statementIndex: @statementIndex, ace: @ace

  updateMetrics: ->
    statementsExecuted = @callState.statementsExecuted
    $metrics = @$el.find('.metrics')
    return $metrics.hide() if @suppressMetricsUpdates or not (statementsExecuted or @metrics.statementsExecuted)
    if @metrics.callsExecuted > 1
      $metrics.find('.call-index').text @callIndex + 1
      $metrics.find('.calls-executed').text @metrics.callsExecuted
      $metrics.find('.calls-metric').show().attr('title', "Method call #{@callIndex + 1} of #{@metrics.callsExecuted} calls")
    else
      $metrics.find('.calls-metric').hide()
    if @metrics.statementsExecuted
      $metrics.find('.statement-index').text @statementIndex + 1
      $metrics.find('.statements-executed').text statementsExecuted
      if @metrics.statementsExecuted > statementsExecuted
        $metrics.find('.statements-executed-total').text " (#{@metrics.statementsExecuted})"
        titleSuffix = " (#{@metrics.statementsExecuted} statements total)"
      else
        $metrics.find('.statements-executed-total').text ''
        titleSuffix = ''
      $metrics.find('.statements-metric').show().attr('title', "Statement #{@statementIndex + 1} of #{statementsExecuted} this call#{titleSuffix}")
    else
      $metrics.find('.statements-metric').hide()
    left = @$el.find('.scrubber-handle').position().left + @$el.find('.spell-progress').position().left
    $metrics.finish().show().css({left: left - $metrics.width() / 2}).delay(2000).fadeOut('fast')

  setStatementRatio: (ratio) ->
    return unless total = @callState?.statementsExecuted
    statementIndex = Math.floor ratio * total
    @setStatementIndex statementIndex unless statementIndex is @statementIndex

  onProgressMouseDown: (e) ->
    @dragging = true
    @scrubProgress e
    Backbone.Mediator.publish 'level:set-playing', playing: false

  onProgressMouseUp: (e) ->
    @dragging = false

  onProgressMouseMove: (e) ->
    return unless @dragging
    @scrubProgress e

  onProgressTapStart: (e, touchData) ->
    # Haven't tested tap versions, don't even need them for iPad app, but hey, it worked for the playback scrubber.
    @dragging = true
    @scrubProgress e, touchData

  onProgressTapEnd: (e, touchData) ->
    @dragging = false

  onProgressTapMove: (e, touchData) ->
    return unless @dragging
    @scrubProgress e, touchData

  scrubProgress: (e, touchData) ->
    screenOffsetX = e.clientX ? touchData?.position.x ? 0
    offsetX = screenOffsetX - @$el.find('.spell-progress').offset().left
    offsetX = Math.max offsetX, 0
    @setStatementRatio offsetX / @$el.find('.spell-progress').width()
    @updateTime()
    @updateScroll()

  onStepBackward: (e) -> @step -1
  onStepForward: (e) -> @step 1
  step: (delta) ->
    lastTime = @statementTime
    @setStatementIndex @statementIndex + delta
    @updateTime() if @statementTime isnt lastTime
    @updateScroll()
    Backbone.Mediator.publish 'level:set-playing', playing: false

  updateTime: ->
    @maintainIndexScrub = true
    clearTimeout @maintainIndexScrubTimeout if @maintainIndexScrubTimeout
    @maintainIndexScrubTimeout = _.delay (=> @maintainIndexScrub = false), 500
    Backbone.Mediator.publish 'level:set-time', time: @statementTime, scrubDuration: 500

  updateScroll: ->
    return unless statementStart = @callState?.statements?[@statementIndex]?.range[0]
    text = @ace.getValue() # code in editor
    currentLine = statementStart.row
    @ace.scrollToLine currentLine, true, true

  setCallState: (callState, statementIndex, @callIndex, @metrics) ->
    return if callState is @callState and statementIndex is @statementIndex
    return unless @callState = callState
    @suppressMetricsUpdates = true
    if not @maintainIndexScrub and not @dragging and statementIndex? and callState.statements[statementIndex]?.userInfo.time isnt @statementTime
      @setStatementIndex statementIndex
    else
      @setStatementRatio @statementRatio
    @suppressMetricsUpdates = false
