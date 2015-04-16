c = require './../schemas'

module.exports = ThangComponentSchema = c.object {
  title: 'Component'
  description: 'Configuration for a Component that this Thang uses.'
  format: 'component-reference'
  required: ['original', 'majorVersion']
  default:
    majorVersion: 0
    config: {}
  links: [{rel: 'db', href: '/db/level.component/{(original)}/version/{(majorVersion)}'}]
},
  original: c.objectId(title: 'Original', description: 'A reference to the original Component being configured.', format: 'hidden')
  config: c.object {title: 'Configuration', description: 'Component-specific configuration properties.', additionalProperties: true, format: 'thang-component-configuration'}
  majorVersion:
    title: 'Major Version'
    description: 'Which major version of the Component is being used.'
    type: 'integer'
    minimum: 0
    format: 'hidden'
