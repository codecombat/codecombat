import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/resource_hub_resource.schema'

class ResourceHubResource extends CocoModel { }

ResourceHubResource.className = 'ResourceHubResource'
ResourceHubResource.schema = schema
ResourceHubResource.urlRoot = '/db/resource_hub_resource'
ResourceHubResource.prototype.urlRoot = '/db/resource_hub_resource'

module.exports = ResourceHubResource
