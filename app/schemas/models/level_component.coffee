c = require './../schemas'
metaschema = require './../metaschema'

attackSelfCode = """
class AttacksSelf extends Component
  @className: "AttacksSelf"
  chooseAction: ->
    @attack @
"""
systems = [
  'action', 'ai', 'alliance', 'collision', 'combat', 'display', 'event', 'existence', 'hearing'
  'inventory', 'movement', 'programming', 'targeting', 'ui', 'vision', 'misc', 'physics', 'effect',
  'magic'
]

PropertyDocumentationSchema = c.object {
  title: "Property Documentation"
  description: "Documentation entry for a property this Component will add to its Thang which other Components might
 want to also use."
  "default":
    name: "foo"
    type: "object"
    description: 'The `foo` property can satisfy all the #{spriteName}\'s foobar needs. Use it wisely.'
  required: ['name', 'type', 'description']
},
  name: {type: 'string', title: "Name", description: "Name of the property."}
  # not actual JS types, just whatever they describe...
  type: c.shortString(title: "Type", description: "Intended type of the property.")
  description: {title: "Description", type: 'string', description: "Description of the property.", format: 'markdown', maxLength: 1000}
  args: c.array {title: "Arguments", description: "If this property has type 'function', then provide documentation for any function arguments."}, c.FunctionArgumentSchema
  owner: {title: "Owner", type: 'string', description: 'Owner of the property, like "this" or "Math".'}
  example: {title: "Example", type: 'string', description: 'An optional example code block.', format: 'javascript'}
  returns: c.object {
    title: "Return Value"
    description: 'Optional documentation of any return value.'
    required: ['type']
    default: {type: 'null'}
  },
    type: c.shortString(title: "Type", description: "Type of the return value")
    example: c.shortString(title: "Example", description: "Example return value")
    description: {title: "Description", type: 'string', description: "Description of the return value.", maxLength: 1000}

DependencySchema = c.object {
  title: "Component Dependency"
  description: "A Component upon which this Component depends."
  "default":
    #original: ?
    majorVersion: 0
  required: ["original", "majorVersion"]
  format: 'latest-version-reference'
  links: [{rel: "db", href: "/db/level.component/{(original)}/version/{(majorVersion)}"}]
},
  original: c.objectId(title: "Original", description: "A reference to another Component upon which this Component depends.")
  majorVersion:
    title: "Major Version"
    description: "Which major version of the Component this Component needs."
    type: 'integer'
    minimum: 0

LevelComponentSchema = c.object {
  title: "Component"
  description: "A Component which can affect Thang behavior."
  required: ["system", "name", "description", "code", "dependencies", "propertyDocumentation", "codeLanguage"]
  "default":
    system: "ai"
    name: "AttacksSelf"
    description: "This Component makes the Thang attack itself."
    code: attackSelfCode
    codeLanguage: "coffeescript"
    dependencies: []  # TODO: should depend on something by default
    propertyDocumentation: []
}
c.extendNamedProperties LevelComponentSchema  # let's have the name be the first property
LevelComponentSchema.properties.name.pattern = c.classNamePattern
_.extend LevelComponentSchema.properties,
  system:
    title: "System"
    description: "The short name of the System this Component belongs to, like \"ai\"."
    type: "string"
    "enum": systems
    "default": "ai"
  description:
    title: "Description"
    description: "A short explanation of what this Component does."
    type: "string"
    maxLength: 2000
    "default": "This Component makes the Thang attack itself."
  codeLanguage:
    type: "string"
    title: "Language"
    description: "Which programming language this Component is written in."
    "enum": ["coffeescript"]
  code:
    title: "Code"
    description: "The code for this Component, as a CoffeeScript class. TODO: add link to documentation for
 how to write these."
    "default": attackSelfCode
    type: "string"
    format: "coffee"
  js:
    title: "JavaScript"
    description: "The transpiled JavaScript code for this Component"
    type: "string"
    format: "hidden"
  dependencies: c.array {title: "Dependencies", description: "An array of Components upon which this Component depends.", "default": [], uniqueItems: true}, DependencySchema
  propertyDocumentation: c.array {title: "Property Documentation", description: "An array of documentation entries for each notable property this Component will add to its Thang which other Components might want to also use.", "default": []}, PropertyDocumentationSchema
  configSchema: _.extend metaschema, {title: "Configuration Schema", description: "A schema for validating the arguments that can be passed to this Component as configuration.", default: {type: 'object', additionalProperties: false}}
  official:
    type: "boolean"
    title: "Official"
    description: "Whether this is an official CodeCombat Component."
    "default": false

c.extendBasicProperties LevelComponentSchema, 'level.component'
c.extendSearchableProperties LevelComponentSchema
c.extendVersionedProperties LevelComponentSchema, 'level.component'
c.extendPermissionsProperties LevelComponentSchema, 'level.component'
c.extendPatchableProperties LevelComponentSchema

module.exports = LevelComponentSchema
