const schema = require('./../schemas')

const Tint = schema.object({
  title: 'Group Tint',
  description: 'A list of allowed colors for tinting a particular group'
}, {
  colorGroupName: schema.shortString({
    title: 'Color Group Name',
    description: 'Name of the group we are tinting on a ThangType.'
  }),
  allowedTints: schema.array({
    title: 'Tints',
    description: 'Legal tints for the color group'
  }, schema.colorConfig())
})

schema.extendBasicProperties(Tint, 'tint')
schema.extendNamedProperties(Tint)

module.exports = Tint
