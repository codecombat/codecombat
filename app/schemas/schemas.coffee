#language imports
Language = require './languages'
# schema helper methods

me = module.exports

combine = (base, ext) ->
  return base unless ext?
  return _.extend(base, ext)

urlPattern = '^(ht|f)tp(s?)\:\/\/[0-9a-zA-Z]([-.\w]*[0-9a-zA-Z])*(:(0-9)*)*(\/?)([a-zA-Z0-9\-\.\?\,\'\/\\\+&%\$#_=]*)?$'

# Common schema properties
me.object = (ext, props) -> combine {type: 'object', additionalProperties: false, properties: props or {}}, ext
me.array = (ext, items) -> combine {type: 'array', items: items or {}}, ext
me.shortString = (ext) -> combine({type: 'string', maxLength: 100}, ext)
me.pct = (ext) -> combine({type: 'number', maximum: 1.0, minimum: 0.0}, ext)
me.date = (ext) -> combine({type: ['object', 'string'], format: 'date-time'}, ext)
# should just be string (Mongo ID), but sometimes mongoose turns them into objects representing those, so we are lenient
me.objectId = (ext) -> schema = combine({type: ['object', 'string'] }, ext)
me.url = (ext) -> combine({type: 'string', format: 'url', pattern: urlPattern}, ext)

PointSchema = me.object {title: "Point", description: "An {x, y} coordinate point.", format: "point2d", required: ["x", "y"]},
  x: {title: "x", description: "The x coordinate.", type: "number", "default": 15}
  y: {title: "y", description: "The y coordinate.", type: "number", "default": 20}

me.point2d = (ext) -> combine(_.cloneDeep(PointSchema), ext)

SoundSchema = me.object { format: 'sound' },
  mp3: { type: 'string', format: 'sound-file' }
  ogg: { type: 'string', format: 'sound-file' }

me.sound = (props) ->
  obj = _.cloneDeep(SoundSchema)
  obj.properties[prop] = props[prop] for prop of props
  obj

ColorConfigSchema = me.object { format: 'color-sound' },
  hue: { format: 'range', type: 'number', minimum: 0, maximum: 1 }
  saturation: { format: 'range', type: 'number', minimum: 0, maximum: 1 }
  lightness: { format: 'range', type: 'number', minimum: 0, maximum: 1 }

me.colorConfig = (props) ->
  obj = _.cloneDeep(ColorConfigSchema)
  obj.properties[prop] = props[prop] for prop of props
  obj

# BASICS

basicProps = (linkFragment) ->
  _id: me.objectId(links: [{rel: 'self', href: "/db/#{linkFragment}/{($)}"}], format:"hidden")
  __v: { title: 'Mongoose Version', format: 'hidden' }

me.extendBasicProperties = (schema, linkFragment) ->
  schema.properties = {} unless schema.properties?
  _.extend(schema.properties, basicProps(linkFragment))

# PATCHABLE

patchableProps = ->
  patches: me.array({title:'Patches'}, {
    _id: me.objectId(links: [{rel: "db", href: "/db/patch/{($)}"}], title: "Patch ID", description: "A reference to the patch.")
    status: { enum: ['pending', 'accepted', 'rejected', 'cancelled']}
  })
  allowPatches: { type: 'boolean' }
  watchers: me.array({title:'Watchers'},
    me.objectId(links: [{rel: 'extra', href: "/db/user/{($)}"}]))

me.extendPatchableProperties = (schema) ->
  schema.properties = {} unless schema.properties?
  _.extend(schema.properties, patchableProps())

# NAMED

namedProps = ->
  name: me.shortString({title: 'Name'})
  slug: me.shortString({title: 'Slug', format: 'hidden'})

me.extendNamedProperties = (schema) ->
  schema.properties = {} unless schema.properties?
  _.extend(schema.properties, namedProps())


# VERSIONED

versionedProps = (linkFragment) ->
  version:
    'default': { minor: 0, major: 0, isLatestMajor: true, isLatestMinor: true }
    format: 'version'
    title: 'Version'
    type: 'object'
    readOnly: true
    additionalProperties: false
    properties:
      major: { type: 'number', minimum: 0 }
      minor: { type: 'number', minimum: 0 }
      isLatestMajor: { type: 'boolean' }
      isLatestMinor: { type: 'boolean' }
  # TODO: figure out useful 'rel' values here
  original: me.objectId(links: [{rel: 'extra', href: "/db/#{linkFragment}/{($)}"}], format: 'hidden')
  parent: me.objectId(links: [{rel: 'extra', href: "/db/#{linkFragment}/{($)}"}], format: 'hidden')
  creator: me.objectId(links: [{rel: 'extra', href: "/db/user/{($)}"}], format: 'hidden')
  created: me.date( { title: 'Created', readOnly: true })
  commitMessage: { type: 'string', maxLength: 500, title: 'Commit Message', readOnly: true }

me.extendVersionedProperties = (schema, linkFragment) ->
  schema.properties = {} unless schema.properties?
  _.extend(schema.properties, versionedProps(linkFragment))


# SEARCHABLE

searchableProps = ->
  index: { format: 'hidden' }

me.extendSearchableProperties = (schema) ->
  schema.properties = {} unless schema.properties?
  _.extend(schema.properties, searchableProps())


# PERMISSIONED

permissionsProps = ->
  permissions:
    type: 'array'
    items:
      type: 'object'
      additionalProperties: false
      properties:
        target: {}
        access: {type: 'string', 'enum': ['read', 'write', 'owner']}
    format: "hidden"

me.extendPermissionsProperties = (schema) ->
  schema.properties = {} unless schema.properties?
  _.extend(schema.properties, permissionsProps())

# TRANSLATABLE

me.generateLanguageCodeArrayRegex = -> "^(" + Language.languageCodes.join("|") + ")$"

me.getLanguageCodeArray = ->
  return Language.languageCodes

me.getLanguagesObject = -> return Language

# OTHER

me.classNamePattern = "^[A-Z][A-Za-z0-9]*$"  # starts with capital letter; just letters and numbers
me.identifierPattern = "^[a-z][A-Za-z0-9]*$"  # starts with lowercase letter; just letters and numbers
me.constantPattern = "^[A-Z0-9_]+$"  # just uppercase letters, underscores, and numbers
me.identifierOrConstantPattern = "^([a-z][A-Za-z0-9]*|[A-Z0-9_]+)$"

me.FunctionArgumentSchema = me.object {
  title: "Function Argument",
  description: "Documentation entry for a function argument."
  "default":
    name: "target"
    type: "object"
    example: "this.getNearestEnemy()"
    description: "The target of this function."
  required: ['name', 'type', 'example', 'description']
},
  name: {type: 'string', pattern: me.identifierPattern, title: "Name", description: "Name of the function argument."}
  # not actual JS types, just whatever they describe...
  type: me.shortString(title: "Type", description: "Intended type of the argument.")
  example: me.shortString(title: "Example", description: "Example value for the argument.")
  description: {title: "Description", type: 'string', description: "Description of the argument.", maxLength: 1000}
  "default":
    title: "Default"
    description: "Default value of the argument. (Your code should set this.)"
    "default": null

me.codeSnippet = (mode) ->
  return snippet = 
    code: {type: 'string', title: 'Snippet', default: '', description: 'Code snippet. Use ${1:defaultValue} syntax to add flexible arguments'}
    # code: {type: 'string', format: 'ace', aceMode: 'ace/mode/'+mode, title: 'Snippet', default: '', description: 'Code snippet. Use ${1:defaultValue} syntax to add flexible arguments'}
    tab: {type: 'string', description: 'Tab completion text. Will be expanded to the snippet if typed and hit tab.'}

me.activity = me.object {description: "Stats on an activity"},
  first: me.date()
  last: me.date()
  count: {type: 'integer', minimum: 0}

