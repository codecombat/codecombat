require('app/styles/editor/ai-story-world/edit.sass')
const RootView = require('views/core/RootView')
const template = require('app/templates/editor/ai-story-world/edit')
const AIStoryWorld = require('models/AIStoryWorld')
const ConfirmModal = require('views/core/ConfirmModal')

require('lib/game-libraries')
require('lib/setupTreema')

class AIStoryWorldEditView extends RootView {
  static initClass () {
    this.prototype.id = 'editor-ai-story-world-edit-view'
    this.prototype.template = template

    this.prototype.events = {
      'click #save-button': 'onClickSaveButton',
      'click #i18n-button': 'onPopulateI18N',
      'click #delete-button': 'confirmDeletion',
    }
  }

  constructor (options, worldID) {
    super(options)
    this.deleteAIStoryWorld = this.deleteAIStoryWorld.bind(this)
    this.worldID = worldID
    this.model = new AIStoryWorld({ _id: this.worldID })
    this.model.saveBackups = true
    this.supermodel.loadModel(this.model)
  }

  onLoaded () {
    super.onLoaded()
    this.buildTreema()
    this.listenTo(this.model, 'change', () => this.treema.set('/', this.model.attributes))
  }

  buildTreema () {
    if (this.treema || !this.model.loaded) { return }
    const data = $.extend(true, {}, this.model.attributes)
    const options = {
      data,
      filePath: `db/ai_story_world/${this.model.get('_id')}`,
      schema: AIStoryWorld.schema,
      readOnly: me.get('anonymous'),
      supermodel: this.supermodel,
    }
    this.treema = this.$el.find('#ai-story-world-treema').treema(options)
    this.treema.build()
    this.treema.open(3)
  }

  // Treema edits its own deep copy. Copy it into the model in one set, so the change listener in
  // onLoaded runs once with every edited value in place, and drop what the author removed.
  commitDraft () {
    this.treema.endExistingEdits()
    const draft = $.extend(true, {}, this.treema.data)
    for (const key of Object.keys(this.model.attributes)) {
      if (key !== '_id' && !(key in draft)) { this.model.unset(key, { silent: true }) }
    }
    this.model.set(draft)
  }

  onClickSaveButton () {
    this.commitDraft()
    const res = this.model.save()
    if (!res) { return }
    res.fail((jqXHR) => console.error(jqXHR))
    res.done(() => {
      document.location.href = `/editor/ai-story-world/${this.model.get('slug') || this.model.id}`
    })
  }

  onPopulateI18N () {
    if (me.get('anonymous')) { return }
    this.commitDraft()
    this.model.populateI18N()
  }

  confirmDeletion () {
    const confirmModal = new ConfirmModal({
      title: 'Are you really sure?',
      body: 'This will completely delete the story world.',
      decline: 'Not really',
      confirm: 'Definitely',
    })
    confirmModal.on('confirm', this.deleteAIStoryWorld)
    this.openModalView(confirmModal)
  }

  deleteAIStoryWorld () {
    $.ajax({
      type: 'DELETE',
      url: `/db/ai_story_world/${this.model.id}`,
      success () {
        noty({ timeout: 5000, text: 'Aaaand it\'s gone.', type: 'success', layout: 'topCenter' })
        _.delay(() => application.router.navigate('/editor/ai-story-world', { trigger: true }), 500)
      },
      error (jqXHR) {
        console.error(jqXHR)
        noty({ timeout: 5000, text: `Deleting the story world failed with error code ${jqXHR.status}`, type: 'error', layout: 'topCenter' })
      },
    })
  }
}
AIStoryWorldEditView.initClass()

module.exports = AIStoryWorldEditView
