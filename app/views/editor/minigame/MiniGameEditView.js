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
  }

  buildTreema () {
    // Feed already-uploaded files into SoundFileTreema's pick-existing dropdown.
    if (this.resource.loaded && !this.treemaOptions) {
      const files = new DocumentFiles(this.resource)
      files.fetch()
      this.treemaOptions = { files }
    }
    return super.buildTreema()
  }

  // EditView.afterRender minus PatchesView: mini_game registers no /patches routes.
  afterRender () {
    RootView.prototype.afterRender.call(this)
    if (!this.supermodel.finished()) { return }
    if (me.get('anonymous')) { this.showReadOnly() }
  }
}

module.exports = MiniGameEditView
