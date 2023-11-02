require('app/styles/editor/ai-scenario/edit.sass')
RootView = require 'views/core/RootView'
template = require 'app/templates/editor/ai-scenario/edit'
AIScenario = require 'models/AIScenario'
ConfirmModal = require 'views/core/ConfirmModal'
PatchesView = require 'views/editor/PatchesView'
errors = require 'core/errors'

nodes = require 'views/editor/level/treema_nodes'

require 'lib/game-libraries'
require('lib/setupTreema')
treemaExt = require 'core/treema-ext'

module.exports = class AIScenarioEditView extends RootView
  id: 'editor-ai-scenario-edit-view'
  template: template

  events:
    'click #save-button': 'onClickSaveButton'
    'click #i18n-button': 'onPopulateI18N'
    'click #delete-button': 'confirmDeletion'
    'click #fix-button': 'onFix'
    'click #diff-button': 'onAddDiff'

  constructor: (options, @scenarioID) ->
    super options
    @scenario = new AIScenario(_id: @scenarioID)
    @scenario.saveBackups = true
    @supermodel.loadModel @scenario

  onLoaded: ->
    super()
    @buildTreema()
    @listenTo @scenario, 'change', =>
      @scenario.updateI18NCoverage()
      @treema.set('/', @scenario.attributes)

  buildTreema: ->
    return if @treema? or (not @scenario.loaded)
    data = $.extend(true, {}, @scenario.attributes)
    options =
      data: data
      filePath: "db/ai_scenario/#{@scenario.get('_id')}"
      schema: AIScenario.schema
      readOnly: me.get('anonymous')
      supermodel: @supermodel
      nodeClasses:
        'chat-message-link': nodes.ChatMessageLinkNode
    @treema = @$el.find('#ai-scenario-treema').treema(options)
    @treema.build()
    @treema.open(5)

  afterRender: ->
    super()
    return unless @supermodel.finished()

  onPopulateI18N: ->
    @scenario.populateI18N()

  onClickSaveButton: (e) ->
    @treema.endExistingEdits()
    for key, value of @treema.data
      @scenario.set(key, value)
    @scenario.updateI18NCoverage()

    res = @scenario.save()

    res.error (collection, response, options) =>
      console.error response

    res.success =>
      url = "/editor/ai-scenario/#{@scenario.get('slug') or @scenario.id}"
      document.location.href = url

  confirmDeletion: ->
    renderData =
      title: 'Are you really sure?'
      body: 'This will completely delete the scenario.'
      decline: 'Not really'
      confirm: 'Definitely'

    confirmModal = new ConfirmModal renderData
    confirmModal.on 'confirm', @deleteAIScenario
    @openModalView confirmModal

  deleteAIScenario: =>
    $.ajax
      type: 'DELETE'
      success: ->
        noty
          timeout: 5000
          text: 'Aaaand it\'s gone.'
          type: 'success'
          layout: 'topCenter'
        _.delay ->
          application.router.navigate '/editor/ai-scenario', trigger: true
        , 500
      error: (jqXHR, status, error) ->
        console.error jqXHR
        timeout: 5000
        text: "Deleting scenario message failed with error code #{jqXHR.status}"
        type: 'error'
        layout: 'topCenter'
      url: "/db/ai_scenario/#{@scenario.id}"
