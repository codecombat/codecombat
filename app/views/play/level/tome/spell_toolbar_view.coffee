View = require 'views/kinds/CocoView'
template = require 'templates/play/level/tome/spell_toolbar'

module.exports = class SpellToolbarView extends View
  className: 'spell-toolbar-view'
  template: template

  subscriptions:
    'spell-step-backward': 'onStepBackward'
    'spell-step-forward': 'onStepForward'

  events:
    'mousemove .progress': 'onProgressHover'
    'mouseout .progress': 'onProgressMouseOut'
    'click .step-backward': 'onStepBackward'
    'click .step-forward': 'onStepForward'

  constructor: (options) ->
    super options
    @ace = options.ace

  afterRender: ->
    super()

  setStatementIndex: (statementIndex) ->
    return unless total = @callState?.statementsExecuted
    @statementIndex = Math.min(total - 1, Math.max(0, statementIndex))
    @statementRatio = @statementIndex / (total - 1)
    @statementTime = @callState.statements[@statementIndex].userInfo.time
    @$el.find('.bar').css('width', 100 * @statementRatio + '%')
    Backbone.Mediator.publish 'tome:spell-statement-index-updated', statementIndex: @statementIndex, ace: @ace
    @$el.find('.step-backward').prop('disabled', @statementIndex is 0)
    @$el.find('.step-forward').prop('disabled', @statementIndex is total - 1)
    @updateMetrics()

  updateMetrics: ->
    statementsExecuted = @callState.statementsExecuted
    $metrics = @$el.find('.metrics')
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
        $metrics.find('.statements-executed-total').text ""
        titleSuffix = ""
      $metrics.find('.statements-metric').show().attr('title', "Statement #{@statementIndex + 1} of #{statementsExecuted} this call#{titleSuffix}")
    else
      $metrics.find('.statements-metric').hide()

  setStatementRatio: (ratio) ->
    return unless total = @callState?.statementsExecuted
    @setStatementIndex Math.floor ratio * total

  onProgressHover: (e) ->
    @setStatementRatio e.offsetX / @$el.find('.progress').width()
    @updateTime()
    @maintainIndexHover = true

  onProgressMouseOut: (e) ->
    @maintainIndexHover = false

  onStepBackward: (e) -> @step -1
  onStepForward: (e) -> @step 1
  step: (delta) ->
    lastTime = @statementTime
    @setStatementIndex @statementIndex + delta
    @updateTime() if @statementIndex isnt lastTime

  updateTime: ->
    @maintainIndexScrub = true
    clearTimeout @maintainIndexScrubTimeout if @maintainIndexScrubTimeout
    @maintainIndexScrubTimeout = _.delay (=> @maintainIndexScrub = false), 500
    Backbone.Mediator.publish 'level-set-time', time: @statementTime, scrubDuration: 500

  setCallState: (callState, statementIndex, @callIndex, @metrics) ->
    return if callState is @callState and statementIndex is @statementIndex
    return unless @callState = callState
    if not @maintainIndexHover and not @maintainIndexScrub and statementIndex? and callState.statements[statementIndex].userInfo.time isnt @statementTime
      @setStatementIndex statementIndex
    else
      @setStatementRatio @statementRatio
    # Not sure yet whether it's better to maintain @statementIndex or @statementRatio
    #else if @statementRatio is 1 or not @statementIndex?
    #  @setStatementRatio 1
    #else
    #  @setStatementIndex @statementIndex
