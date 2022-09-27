import CocoModel from 'app/models/CocoModel'
import schema from 'schemas/models/announcement.schema'

class Announcement extends CocoModel { }

Announcement.className = 'Announcement'
Announcement.schema = schema
Announcement.urlRoot = '/db/announcement'
Announcement.prototype.urlRoot = '/db/announcement'

module.exports = Announcement
