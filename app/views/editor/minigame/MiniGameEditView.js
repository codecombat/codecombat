const EditView = require('views/common/EditView')
const RootView = require('views/core/RootView')
const DocumentFiles = require('collections/DocumentFiles')
const MiniGame = require('models/MiniGame')
const MiniGameSchema = require('schemas/models/mini_game.schema')

class MiniGameEditView extends EditView {
  resource = null
  schema = MiniGameSchema
  redirectPathOnSuccess = '/editor/minigame'
  filePath = 'db/mini_game'
  resourceName = 'MiniGame'

  constructor (options = {}, resourceId) {
    super({})
    this.resource = new MiniGame({ _id: resourceId })
    this.supermodel.loadModel(this.resource)
    // Loaded via supermodel so buildTreema (fired from onLoaded) sees a synced collection —
    // SoundFileTreema reads its pick-existing dropdown once, at render time.
    this.files = this.supermodel.loadCollection(new DocumentFiles(this.resource), 'files').model
  }

  buildTreema () {
    if (!this.treemaOptions) { this.treemaOptions = { files: this.files } }
    return super.buildTreema()
  }

  // EditView.afterRender minus PatchesView: mini_game registers no /patches routes.
  afterRender () {
    RootView.prototype.afterRender.call(this)
    if (!this.supermodel.finished()) { return }
    if (me.get('anonymous')) { this.showReadOnly() }
    // The shared template renders a Patches section we don't populate — drop it.
    this.$el.find('.patches-view').prev('h3').remove()
    this.$el.find('.patches-view').remove()
    this.addPlayButton()
  }

  addPlayButton () {
    const slug = this.resource.get('slug') || this.resource.id
    if (!slug || this.$el.find('#play-minigame-button').length) { return }
    // Test = play the CURRENT editor state without saving: stash Treema data in
    // localStorage, and the play page reads it back under ?dev=true.
    $('<button type="button" id="test-minigame-button" class="btn btn-primary resource-tool-button">Test unsaved</button>')
      .on('click', () => {
        this.treema?.endExistingEdits()
        const data = $.extend(true, {}, this.resource.attributes, this.treema?.data || {})
        window.localStorage.setItem(`minigame-dev-doc:${slug}`, JSON.stringify({ data, stashedAt: Date.now() }))
        window.open(`/play/minigame/${slug}?dev=true`, '_blank')
      })
      .insertBefore(this.$el.find('#save-button'))
    $(`<a id="play-minigame-button" class="btn btn-primary resource-tool-button" href="/play/minigame/${slug}" target="_blank">Play</a>`)
      .insertBefore(this.$el.find('#save-button'))
    // Refetching triggers the resource 'change' listener EditView already wires,
    // which resets the Treema to the saved state.
    $('<button type="button" id="revert-minigame-button" class="btn btn-warning resource-tool-button">Revert</button>')
      .on('click', () => {
        if (!window.confirm('Discard unsaved changes and reload the saved state?')) { return }
        this.treema?.endExistingEdits()
        this.resource.fetch()
      })
      .insertBefore(this.$el.find('#test-minigame-button'))
  }
}

module.exports = MiniGameEditView
