require('app/styles/admin/codelogs-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/admin/codelogs-view'
CodeLogCollection = require 'collections/CodeLogs'
CodeLog = require 'models/CodeLog'
utils = require 'core/utils'

CodePlaybackView = require './CodePlaybackView'

module.exports = class CodeLogsView extends RootView
  template: template
  id: 'codelogs-view'
  tooltip: null
  events:
    'click .playback': 'onClickPlayback'
    'input #userid-search': 'onUserIDInput'
    'input #levelslug-search': 'onLevelSlugInput'

  initialize: ->
    #@spade = new Spade()
    @codelogs = new CodeLogCollection()
    @supermodel.trackRequest(@codelogs.fetchLatest())
    @onUserIDInput = _.debounce(@onUserIDInput, 300)
    @onLevelSlugInput = _.debounce(@onLevelSlugInput, 300)
    #@supermodel.trackRequest(@codelogs.fetch())

  onUserIDInput: (e) ->
    userID = $('#userid-search')[0].value
    unless userID is ''
      Promise.resolve(@codelogs.fetchByUserID(userID))
      .then (e) =>
        @renderSelectors '#codelogtable'
    else
      Promise.resolve(@codelogs.fetchLatest())
      .then (e) =>
        @renderSelectors '#codelogtable'

  onLevelSlugInput: (e) ->
    slug = $('#levelslug-search')[0].value
    unless slug is ''
      Promise.resolve(@codelogs.fetchBySlug(slug))
      .then (e) =>
        @renderSelectors '#codelogtable'
    else
      Promise.resolve(@codelogs.fetchLatest())
      .then (e) =>
        @renderSelectors '#codelogtable'

  onClickPlayback: (e) ->
    @insertSubView @codePlaybackView = new CodePlaybackView rawLog:$(e.target).data('codelog')

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
