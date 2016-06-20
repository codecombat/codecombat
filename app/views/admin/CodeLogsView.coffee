RootView = require 'views/core/RootView'
template = require 'templates/admin/codelogs-view'
CodeLogCollection = require 'collections/CodeLogs'
CodeLog = require 'models/CodeLog'
utils = require 'core/utils'

module.exports = class CodeLogsView extends RootView
  template: template
  id: 'codelogs-view'
  tooltip: null
  events:
    'click .playback': 'onClickPlayback'

  initialize: ->
    @spade = new Spade()
    @codelogs = new CodeLogCollection()
    @supermodel.trackRequest(@codelogs.fetch())

  onClickPlayback: (e) ->
    @deleteTooltip()
    events = LZString.decompressFromUTF16($(e.target).data('codelog'))
    events = @spade.expand(JSON.parse(events))

    @tooltip = $(document.createElement('textarea'))
    @tooltip.attr('id', "codelogs-tooltip")
    @tooltip.css({left: e.pageX + 20, top: e.pageY}) # Position near the cursor
    @tooltip.blur @onBlurTooltip
    @$('#codelogs-view').append @tooltip
    @tooltip.focus()
    @spade.play(events, @tooltip.context)

  deleteTooltip: ->
    if @tooltip?
      @tooltip.off 'blur'
      @tooltip.remove()
      @tooltip = null

  onBlurTooltip: (e) =>
    @deleteTooltip()

  destroy: ->
    @deleteTooltip()
    super()
