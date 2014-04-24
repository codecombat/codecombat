c = require './../schemas'

LevelSessionPlayerSchema = c.object
  id: c.objectId
    links: [
      {
        rel: 'extra'
        href: "/db/user/{($)}"
      }
    ]
  time:
    type: 'Number'
  changes:
    type: 'Number'


LevelSessionLevelSchema = c.object {required: ['original', 'majorVersion']},
  original: c.objectId({})
  majorVersion:
    type: 'integer'
    minimum: 0
    default: 0


LevelSessionSchema = c.object
  title: "Session"
  description: "A single session for a given level."


_.extend LevelSessionSchema.properties,
  # denormalization
  creatorName:
    type: 'string'
  levelName:
    type: 'string'
  levelID:
    type: 'string'
  multiplayer:
    type: 'boolean'
  creator: c.objectId
    links:
      [
        {
          rel: 'extra'
          href: "/db/user/{($)}"
        }
      ]
  created: c.date
    title: 'Created'
    readOnly: true

  changed: c.date
    title: 'Changed'
    readOnly: true

  team: c.shortString()
  level: LevelSessionLevelSchema

  screenshot:
    type: 'string'

  state: c.object {},
    complete:
      type: 'boolean'
    scripts: c.object {},
      ended:
        type: 'object'
        additionalProperties:
          type: 'number'
      currentScript:
        type: [
          'null'
          'string'
        ]
      currentScriptOffset:
        type: 'number'

    selected:
      type: [
        'null'
        'string'
      ]
    playing:
      type: 'boolean'
    frame:
      type: 'number'
    thangs:
      type: 'object'
      additionalProperties:
        title: 'Thang'
        type: 'object'
        properties:
          methods:
            type: 'object'
            additionalProperties:
              title: 'Thang Method'
              type: 'object'
              properties:
                metrics:
                  type: 'object'
                source:
                  type: 'string'

  code:
    type: 'object'
    additionalProperties:
      type: 'object'
      additionalProperties:
        type: 'string'
        format: 'javascript'

  teamSpells:
    type: 'object'
    additionalProperties:
      type: 'array'

  players:
    type: 'object'

  chat:
    type: 'array'

  meanStrength:
    type: 'number'

  standardDeviation:
    type:'number'
    minimum: 0

  totalScore:
    type: 'number'

  submitted:
    type: 'boolean'

  submitDate: c.date
    title: 'Submitted'

  submittedCode:
    type: 'object'
    additionalProperties:
      type: 'object'
      additionalProperties:
        type: 'string'
        format: 'javascript'

  isRanking:
    type: 'boolean'
    description: 'Whether this session is still in the first ranking chain after being submitted.'

  unsubscribed:
    type: 'boolean'
    description: 'Whether the player has opted out of receiving email updates about ladder rankings for this session.'

  numberOfWinsAndTies:
    type: 'number'

  numberOfLosses:
    type: 'number'

  scoreHistory:
    type: 'array'
    title: 'Score History'
    description: 'A list of objects representing the score history of a session'
    items:
      title: 'Score History Point'
      description: 'An array with the format [unix timestamp, totalScore]'
      type: 'array'
      items:
        type: 'number'

  matches:
    type: 'array'
    title: 'Matches'
    description: 'All of the matches a submitted session has played in its current state.'
    items:
      type: 'object'
      properties:
        date: c.date
          title: 'Date computed'
          description: 'The date a match was computed.'
        metrics:
          type: 'object'
          title: 'Metrics'
          description: 'Various information about the outcome of a match.'
          properties:
            rank:
              title: 'Rank'
              description: 'A 0-indexed ranking representing the player\'s standing in the outcome of a match'
              type: 'number'
        opponents:
          type: 'array'
          title: 'Opponents'
          description: 'An array containing information about the opponents\' sessions in a given match.'
          items:
            type: 'object'
            properties:
              sessionID:
                title: 'Opponent Session ID'
                description: 'The session ID of an opponent.'
                type: ['object', 'string']
              userID:
                title: 'Opponent User ID'
                description: 'The user ID of an opponent'
                type: ['object','string']
              metrics:
                type: 'object'
                properties:
                  rank:
                    title: 'Opponent Rank'
                    description: 'The opponent\'s ranking in a given match'
                    type: 'number'






c.extendBasicProperties LevelSessionSchema, 'level.session'
c.extendPermissionsProperties LevelSessionSchema, 'level.session'

module.exports = LevelSessionSchema
