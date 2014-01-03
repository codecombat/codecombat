c = require './common'

LevelSessionPlayerSchema = c.object {
  id: c.objectId(links: [{rel: 'extra', href: "/db/user/{($)}"}])
  time: { type: 'Number' }
  changes: { type: 'Number' }
}

LevelSessionLevelSchema = c.object {required: ['original', 'majorVersion']}, {
  original: c.objectId({})
  majorVersion: {type: 'integer', minimum: 0, default: 0}}

LevelSessionSchema = c.object {
  title: "Session"
  description: "A single session for a given level."
}

_.extend LevelSessionSchema.properties,
  # denormalization
  creatorName: { type: 'string' }
  levelName: { type: 'string' }
  levelID: { type: 'string' }
  multiplayer: { type: 'boolean' }

  creator: c.objectId(links: [{rel: 'extra', href: "/db/user/{($)}"}])
  created: c.date( { title: 'Created', readOnly: true })
  changed: c.date( { title: 'Changed', readOnly: true })
  level: LevelSessionLevelSchema
  screenshot: { type: 'string' }
  state: c.object {}, {
    complete: { type: 'boolean' }
    scripts: c.object {}, {
      ended: { type: 'object', additionalProperties: { type: 'number' }}
      currentScript: { type: ['null', 'string']}
      currentScriptOffset: { type: 'number' }}
    selected: { type: ['null', 'string'] }
    playing: { type: 'boolean' }
    frame: { type: 'number' }
    thangs: { type: 'object', additionalProperties: {
      title: 'Thang'
      type: 'object'
      properties: {
        methods: { type: 'object', additionalProperties: {
          title: 'Thang Method'
          type: 'object'
          properties: {
            metrics: { type: 'object' }
            source: { type: 'string' }
          }
        }}
      }
    }}
  }
  
  # TODO: specify this more
  code: { type: 'object' }
  players: { type: 'object' }
  chat: { type: 'array' }



c.extendBasicProperties LevelSessionSchema, 'level.session'
c.extendPermissionsProperties LevelSessionSchema, 'level.session'

module.exports = LevelSessionSchema
