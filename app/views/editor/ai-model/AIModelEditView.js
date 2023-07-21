require('app/styles/editor/ai-model/edit.sass')
const RootView = require('views/core/RootView')
const template = require('app/templates/editor/ai-model/edit')
const AIModel = require('models/AIModel')
const ConfirmModal = require('views/core/ConfirmModal')
// const PatchesView = require('views/editor/PatchesView')
// const errors = require('core/errors')

require('lib/game-libraries')
require('lib/setupTreema')
// const treemaExt = require('core/treema-ext')

class AIModelEditView extends RootView {
  id = 'editor-ai-model-edit-view'
  template = template
  events = {
    'click #save-button': 'onClickSaveButton',
    'click #i18n-button': 'onPopulateI18N',
    'click #delete-button': 'confirmDeletion',
    'click #fix-button': 'onFix',
    'click #diff-button': 'onAddDiff'
  }

  constructor(options, modelID) {
    super(options)
    this.deleteAIModel = this.deleteAIModel.bind(this)
    this.aiModelID = modelID
    this.aiModel = new AIModel({ _id: this.aiModelID })
    this.aiModel.saveBackups = true
    this.supermodel.loadModel(this.aiModel)
  }

  onLoaded() {
    super.onLoaded()
    this.buildTreema()
    return this.listenTo(this.aiModel, 'change', () => {
      this.aiModel.updateI18NCoverage()
      return this.treema.set('/', this.aiModel.attributes)
    })
  }

  buildTreema() {
    if ((this.treema != null) || (!this.aiModel.loaded)) { return }
    const data = $.extend(true, {}, this.aiModel.attributes)
    const options = {
      data,
      filePath: `db/ai_model/${this.aiModel.get('_id')}`,
      schema: AIModel.schema,
      readOnly: me.get('anonymous'),
      supermodel: this.supermodel
    }
    this.treema = this.$el.find('#ai-model-treema').treema(options)
    this.treema.build()
    return this.treema.open(5)
  }

  afterRender() {
    super.afterRender()
    // if (!this.supermodel.finished()) { return }
  }

  onPopulateI18N() {
    return this.aiModel.populateI18N()
  }

  onClickSaveButton(e) {
    this.treema.endExistingEdits()
    for (const key in this.treema.data) {
      const value = this.treema.data[key]
      this.aiModel.set(key, value)
    }
    this.aiModel.updateI18NCoverage()

    const res = this.aiModel.save()
    if (!res) throw new Error(this.aiModel.validationError)

    res.error((collection, response, options) => {
      return console.error(response)
    })

    return res.success(() => {
      const url = `/editor/ai-model/${this.aiModel.get('slug') || this.aiModel.id}`
      document.location.href = url
    })
  }

  confirmDeletion() {
    const renderData = {
      title: 'Are you really sure?',
      body: 'This will completely delete the model.',
      decline: 'Not really',
      confirm: 'Definitely'
    }

    const confirmModal = new ConfirmModal(renderData)
    confirmModal.on('confirm', this.deleteAIModel)
    return this.openModalView(confirmModal)
  }

  deleteAIModel() {
    return $.ajax({
      type: 'DELETE',
      success() {
        noty({
          timeout: 5000,
          text: 'Aaaand it\'s gone.',
          type: 'success',
          layout: 'topCenter'
        })
        return _.delay(() => application.router.navigate('/editor/ai-model', { trigger: true })
          , 500)
      },
      error(jqXHR, status, error) {
        console.error(jqXHR)
        return {
          timeout: 5000,
          text: `Deleting model message failed with error code ${jqXHR.status}`,
          type: 'error',
          layout: 'topCenter'
        }
      },
      url: `/db/ai_model/${this.aiModel.id}`
    })
  }
}
module.exports = AIModelEditView
