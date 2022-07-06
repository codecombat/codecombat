const EditView = require('views/common/EditView')
const Announcement = require('models/Announcement')
const AnnouncementSchema = require('schemas/models/announcement.schema')

class AnnouncementEditView extends EditView{
  resource = null
  schema = AnnouncementSchema
  redirectPathOnSuccess = '/editor/announcement'
  filePath = 'announcement'
  resourceName = 'Announcement'

  constructor(options = {}, resourceId) {
    super({})
    this.resource = new Announcement({_id: resourceId })
    this.supermodel.loadModel(this.resource)
  }
}

module.exports = AnnouncementEditView