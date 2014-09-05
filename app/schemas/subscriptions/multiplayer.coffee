c = require 'schemas/schemas'

module.exports =
  'real-time-multiplayer:joined-game': c.object {title: 'Multiplayer joined game', required: ['session']},
    session: {type: 'object'}

  'real-time-multiplayer:left-game': c.object {title: 'Multiplayer left game'}

  'real-time-multiplayer:manual-cast': c.object {title: 'Multiplayer manual cast'}

  'real-time-multiplayer:new-opponent-code': c.object {title: 'Multiplayer new opponent code', required: ['code', 'codeLanguage']},
    code: {type: 'object'}
    codeLanguage: {type: 'string'}
    team: {type: 'string'}
