c = require './../schemas'
metaschema = require './../metaschema'

attackSelfCode = """
class AttacksSelf extends Component
  @className: 'AttacksSelf'
  chooseAction: ->
    @attack @
"""
systems = [
  'action', 'ai', 'alliance', 'collision', 'combat', 'display', 'event', 'existence', 'hearing',
  'inventory', 'movement', 'programming', 'targeting', 'ui', 'vision', 'misc', 'physics', 'effect',
  'magic'
]

PropertyDocumentationSchema = c.object {
  title: 'Property Documentation'
  description: 'Documentation entry for a property this Component will add to its Thang which other Components might want to also use.'
  default:
    name: 'foo'
    type: 'object'
    description: 'The `foo` property can satisfy all the #{spriteName}\'s foobar needs. Use it wisely.'
  required: ['name', 'type', 'description']
},
  name: {type: 'string', title: 'Name', description: 'Name of the property.'}
  i18n: { type: 'object', format: 'i18n', props: ['description', 'context'], description: 'Help translate this property'}
  context: {
    type: 'object'
    title: 'Example template context'
    additionalProperties: { type: 'string' }
  }
  codeLanguages: c.array {title: 'Specific Code Languages', description: 'If present, then only the languages specified will show this documentation. Leave unset for language-independent documentation.', format: 'code-languages-array'}, c.shortString(title: 'Code Language', description: 'A specific code language to show this documentation for.', format: 'code-language')
  # not actual JS types, just whatever they describe...
  type: c.shortString(title: 'Type', description: 'Intended type of the property.')
  description:
    oneOf: [
      {
        type: 'object',
        title: 'Language Descriptions',
        description: 'Property descriptions by code language.',
        additionalProperties: {type: 'string', description: 'Description of the property.', maxLength: 1000, format: 'markdown'}
        format: 'code-languages-object'
        default: {javascript: ''}
      }
      {title: 'Description', type: 'string', description: 'Description of the property.', maxLength: 1000, format: 'markdown'}
    ]
  args: c.array {title: 'Arguments', description: 'If this property has type "function", then provide documentation for any function arguments.'}, c.FunctionArgumentSchema
  owner: {title: 'Owner', type: 'string', description: 'Owner of the property, like "this" or "Math".'}
  example:
    oneOf: [
      {
        type: 'object',
        title: 'Language Examples',
        description: 'Examples by code language.',
        additionalProperties: {type: 'string', description: 'An example code block.', format: 'code'}
        format: 'code-languages-object'
        default: {javascript: ''}
      }
      {title: 'Example', type: 'string', description: 'An optional example code block.', format: 'javascript'}
    ]
  snippets: {type: 'object', title: 'Snippets', description: 'List of snippets for the respective programming languages', additionalProperties: c.codeSnippet, format: 'code-languages-object'}
  returns: c.object {
    title: 'Return Value'
    description: 'Optional documentation of any return value.'
    required: ['type']
    default: {type: 'null'}
  },
    type: c.shortString(title: 'Type', description: 'Type of the return value')
    example:
      oneOf: [
        {
          type: 'object',
          title: 'Language Examples',
          description: 'Example return values by code language.',
          additionalProperties: c.shortString(description: 'Example return value.', format: 'code')
          format: 'code-languages-object'
          default: {javascript: ''}
        }
        c.shortString(title: 'Example', description: 'Example return value')
      ]
    description:
      oneOf: [
        {
          type: 'object',
          title: 'Language Descriptions',
          description: 'Example return values by code language.',
          additionalProperties: {type: 'string', description: 'Description of the return value.', maxLength: 1000}
          format: 'code-languages-object'
          default: {javascript: ''}
        }
        {title: 'Description', type: 'string', description: 'Description of the return value.', maxLength: 1000}
      ]
    i18n: { type: 'object', format: 'i18n', props: ['description'], description: 'Help translate this return value'}
  autoCompletePriority:
    type: 'number'
    title: 'Autocomplete Priority'
    description: 'How important this property is to autocomplete.'
    minimum: 0
    default: 1.0
  userShouldCaptureReturn:
    type: 'object'
    title: 'User Should Capture Return'
    properties:
      variableName:
        type: 'string'
        title: 'Variable Name'
        description: 'Variable name this property is autocompleted into.'
        default: 'result'

DependencySchema = c.object {
  title: 'Component Dependency'
  description: 'A Component upon which this Component depends.'
  required: ['original', 'majorVersion']
  format: 'latest-version-reference'
  links: [{rel: 'db', href: '/db/level.component/{(original)}/version/{(majorVersion)}'}]
},
  original: c.objectId(title: 'Original', description: 'A reference to another Component upon which this Component depends.')
  majorVersion:
    title: 'Major Version'
    description: 'Which major version of the Component this Component needs.'
    type: 'integer'
    minimum: 0

LevelComponentSchema = c.object {
  title: 'Component'
  description: 'A Component which can affect Thang behavior.'
  required: ['system', 'name', 'code']
  default:
    system: 'ai'
    name: 'AttacksSelf'
    description: 'This Component makes the Thang attack itself.'
    code: attackSelfCode
    codeLanguage: 'coffeescript'
    dependencies: []  # TODO: should depend on something by default
    propertyDocumentation: []
    configSchema: {}
}
c.extendNamedProperties LevelComponentSchema  # let's have the name be the first property
LevelComponentSchema.properties.name.pattern = c.classNamePattern
_.extend LevelComponentSchema.properties,
  system:
    title: 'System'
    description: 'The short name of the System this Component belongs to, like \"ai\".'
    type: 'string'
    'enum': systems
  description:
    title: 'Description'
    description: 'A short explanation of what this Component does.'
    type: 'string'
    maxLength: 2000
  codeLanguage:
    type: 'string'
    title: 'Language'
    description: 'Which programming language this Component is written in.'
    'enum': ['coffeescript']
  code:
    title: 'Code'
    description: 'The code for this Component, as a CoffeeScript class. TODO: add link to documentation for how to write these.'
    type: 'string'
    format: 'coffee'
  js:
    title: 'JavaScript'
    description: 'The transpiled JavaScript code for this Component'
    type: 'string'
    format: 'hidden'
  dependencies: c.array {title: 'Dependencies', description: 'An array of Components upon which this Component depends.', uniqueItems: true}, DependencySchema
  propertyDocumentation: c.array {title: 'Property Documentation', description: 'An array of documentation entries for each notable property this Component will add to its Thang which other Components might want to also use.'}, PropertyDocumentationSchema
  configSchema: _.extend metaschema, {title: 'Configuration Schema', description: 'A schema for validating the arguments that can be passed to this Component as configuration.', default: {type: 'object'}}
  official:
    type: 'boolean'
    title: 'Official'
    description: 'Whether this is an official CodeCombat Component.'
  searchStrings: {type: 'string'}

c.extendBasicProperties LevelComponentSchema, 'level.component'
c.extendSearchableProperties LevelComponentSchema
c.extendVersionedProperties LevelComponentSchema, 'level.component'
c.extendPermissionsProperties LevelComponentSchema, 'level.component'
c.extendPatchableProperties LevelComponentSchema
c.extendTranslationCoverageProperties LevelComponentSchema

module.exports = LevelComponentSchema
