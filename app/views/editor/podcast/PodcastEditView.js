import EditView from 'views/common/EditView';
import Podcast from 'models/Podcast';
import PodcastSchema from 'schemas/models/podcast.schema';

class PodcastEditView extends EditView {
  resource = null
  schema = PodcastSchema
  redirectPathOnSuccess = '/editor/podcast'
  filePath = 'podcast'
  resourceName = 'Podcast'

  constructor(options = {}, resourceId) {
    super({})
    this.resource = new Podcast({ _id: resourceId })
    this.supermodel.loadModel(this.resource)
  }
}

export default PodcastEditView;
