c = require 'schemas/schemas'

module.exports =
  'real-time-multiplayer:created-game': c.object {title: 'Multiplayer created game', required: ['realTimeSessionID']},
    realTimeSessionID: {type: 'string'}

  'real-time-multiplayer:joined-game': c.object {title: 'Multiplayer joined game', required: ['realTimeSessionID']},
    realTimeSessionID: {type: 'string'}

  'real-time-multiplayer:left-game': c.object {title: 'Multiplayer left game'},
    userID: {type: 'string'}

  'real-time-multiplayer:manual-cast': c.object {title: 'Multiplayer manual cast'}

  'real-time-multiplayer:new-opponent-code': c.object {title: 'Multiplayer new opponent code', required: ['code', 'codeLanguage']},
    code: {type: 'object'}
    codeLanguage: {type: 'string'}
    team: {type: 'string'}

  'real-time-multiplayer:player-status': c.object {title: 'Multiplayer player status', required: ['status']},
    status: {type: 'string'}
