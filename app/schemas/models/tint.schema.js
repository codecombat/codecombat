const schema = require('./../schemas')

const Tint = schema.object({
  title: 'Group Tint',
  description: 'A list of tint options'
}, {
  allowedTints: schema.array(
    {
      title: 'Tints',
      description: 'Legal tints for the color group'
    },
    // Property is the colorGroup name, and value is a colorConfig object.
    schema.object({ additionalProperties: schema.colorConfig() })
  )
})

schema.extendBasicProperties(Tint, 'tint')
schema.extendNamedProperties(Tint)

module.exports = Tint
