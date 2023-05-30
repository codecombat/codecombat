import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/podcast.schema'

class PodcastResource extends CocoModel { }

PodcastResource.className = 'PodcastResource'
PodcastResource.schema = schema
PodcastResource.urlRoot = '/db/podcast'
PodcastResource.prototype.urlRoot = '/db/podcast'

export default PodcastResource;
