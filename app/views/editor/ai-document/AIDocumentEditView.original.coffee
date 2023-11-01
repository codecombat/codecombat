require('app/styles/editor/ai-document/edit.sass')
RootView = require 'views/core/RootView'
template = require 'app/templates/editor/ai-document/edit'
AIDocument = require 'models/AIDocument'
ConfirmModal = require 'views/core/ConfirmModal'
PatchesView = require 'views/editor/PatchesView'
errors = require 'core/errors'

require 'lib/game-libraries'
require('lib/setupTreema')
treemaExt = require 'core/treema-ext'

module.exports = class AIDocumentEditView extends RootView
  id: 'editor-ai-document-edit-view'
  template: template

  events:
    'click #save-button': 'onClickSaveButton'
    'click #delete-button': 'confirmDeletion'

  constructor: (options, @documentID) ->
    super options
    @document = new AIDocument(_id: @documentID)
    @document.saveBackups = true
    @supermodel.loadModel @document

  onLoaded: ->
    super()
    @buildTreema()
    @listenTo @document, 'change', =>
      @treema.set('/', @document.attributes)

  buildTreema: ->
    return if @treema? or (not @document.loaded)
    data = $.extend(true, {}, @document.attributes)
    options =
      data: data
      filePath: "db/ai_document/#{@document.get('_id')}"
      schema: AIDocument.schema
      readOnly: me.get('anonymous')
      supermodel: @supermodel
      nodeClasses:
        'document-by-type': DocumentByTypeNode
    @treema = @$el.find('#ai-document-treema').treema(options)
    @treema.build()
    @treema.open(2)

  afterRender: ->
    super()
    return unless @supermodel.finished()

  onClickSaveButton: (e) ->
    @treema.endExistingEdits()
    for key, value of @treema.data
      @document.set(key, value)

    res = @document.save()

    res.error (collection, response, options) =>
      console.error response

    res.success =>
      url = "/editor/ai-document/#{@document.get('slug') or @document.id}"
      document.location.href = url

  confirmDeletion: ->
    renderData =
      title: 'Are you really sure?'
      body: 'This will completely delete the document.'
      decline: 'Not really'
      confirm: 'Definitely'

    confirmModal = new ConfirmModal renderData
    confirmModal.on 'confirm', @deleteAIDocument
    @openModalView confirmModal

  deleteAIDocument: =>
    $.ajax
      type: 'DELETE'
      success: ->
        noty
          timeout: 5000
          text: 'Aaaand it\'s gone.'
          type: 'success'
          layout: 'topCenter'
        _.delay ->
          application.router.navigate '/editor/ai-document', trigger: true
        , 500
      error: (jqXHR, status, error) ->
        console.error jqXHR
        timeout: 5000
        text: "Deleting document message failed with error code #{jqXHR.status}"
        type: 'error'
        layout: 'topCenter'
      url: "/db/ai_document/#{@document.id}"


class DocumentByTypeNode extends TreemaNode.nodeMap.string
  buildValueForDisplay: (valEl, data) ->
    super valEl, data

    return unless data
    if @parent.data.type is 'html'
      # Create a new iframe element
      iframe = document.createElement 'iframe'

      # Set some properties for the iframe
      iframe.style.width = '200%'
      iframe.style.height = '500px'
      iframe.className = 'treema-iframe'
      iframe.style.overflow = 'scroll'
      iframe.style.transform = 'scale(0.5) translate(-50%, -50%)'
      iframe.srcdoc = data
      # Append the new iframe to the parent element
      @$el.find('.treema-iframe').remove()
      @$el.append iframe


  # limitChoices: (options) ->
  #   if @parent.keyForParent is 'concepts' and (not this.parent.parent)
  #     options = (o for o in options when _.find(concepts, (c) -> c.concept is o and not c.automatic and not c.deprecated))  # Allow manual, not automatic
  #   else
  #     options = (o for o in options when _.find(concepts, (c) -> c.concept is o and not c.deprecated))  # Allow both
  #   super options

  # onClick: (e) ->
  #   return if this.parent.keyForParent is 'concepts' and (not this.parent.parent) and @$el.hasClass('concept-automatic')  # Don't allow editing of automatic concepts
  #   super e