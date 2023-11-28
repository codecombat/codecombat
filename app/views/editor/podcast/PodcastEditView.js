const EditView = require('views/common/EditView')
const Podcast = require('models/Podcast')
const PodcastSchema = require('schemas/models/podcast.schema')

class PodcastEditView extends EditView {
  resource = null
  schema = PodcastSchema
  redirectPathOnSuccess = '/editor/podcast'
  filePath = 'podcast'
  resourceName = 'Podcast'

  constructor (options = {}, resourceId) {
    super({})
    this.resource = new Podcast({ _id: resourceId })
    this.supermodel.loadModel(this.resource)
  }
}

module.exports = PodcastEditView
