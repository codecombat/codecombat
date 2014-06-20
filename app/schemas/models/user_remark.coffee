c = require './../schemas'

UserRemarkSchema = c.object {
  title: "Remark"
  description: "Remarks on a user, point of contact, tasks."
}

_.extend UserRemarkSchema.properties,
  user: c.objectId links: [{rel: 'extra', href: "/db/user/{($)}"}]
  contact: c.objectId links: [{rel: 'extra', href: "/db/user/{($)}"}]
  created: c.date title: 'Created', readOnly: true
  history: c.array {title: 'History', description: 'Records of our interactions with the user.'},
    c.object {title: 'Record'}, {date: c.date(title: 'Date'), content: {title: 'Content', type: 'string', format: 'markdown'}}
  tasks: c.array {title: 'Tasks', description: 'Task entries: when to email the contact about something.'},
    c.object {title: 'Task'}, {date: c.date(title: 'Date'), action: {title: 'Action', type: 'string'}}

  # denormalization
  userName: { title: "Player Name", type: 'string' }
  contactName: { title: "Contact Name", type: 'string' }  # Not actually our usernames


c.extendBasicProperties UserRemarkSchema, 'user.remark'

module.exports = UserRemarkSchema
