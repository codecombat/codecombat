const c = require('./../schemas')

const ReadAnnouncementSchema = {
  type: 'object',

  properties: {
    owner: c.objectId({
      links:
      [
        {
          rel: 'extra',
          href: '/db/user/{($)}'
        }
      ]
    }),
    announcement: c.objectId({
      links:
      [
        {
          rel: 'extra',
          href: '/db/announcement/{($)}'
        }
      ]
    }),
    read: {
      type: 'boolean',
      default: false
    },
    readDate: c.date,
    created: c.date({
      title: 'Created',
      readOnly: true
    }),
    announcementCreated: c.date({ readOnly: true })
  }
}

module.exports = ReadAnnouncementSchema
