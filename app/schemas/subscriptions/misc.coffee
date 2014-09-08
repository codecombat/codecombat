c = require 'schemas/schemas'

module.exports =
  'application:idle-changed': c.object {},
    idle: {type: 'boolean'}

  'application:error': c.object {},
    message: {type: 'string'}
    stack: {type: 'string'}

  'audio-player:loaded': c.object {required: ['sender']},
    sender: {type: 'object'}

  'audio-player:play-sound': c.object {required: ['trigger']},
    trigger: {type: 'string'}
    volume: {type: 'number', minimum: 0, maximum: 1}

  'music-player:play-music': c.object {required: ['play']},
    play: {type: 'boolean'}
    file: {type: 'string'}

  'modal:opened': c.object {}

  'modal:closed': c.object {}

  'router:navigate': c.object {required: ['route']},
    route: {type: 'string'}
    view: {type: 'object'}
    viewClass: {type: 'function'}
    viewArgs: {type: 'array'}

  'achievements:new': c.object {required: ['earnedAchievements']},
    earnedAchievements: {type: 'object'}

  'ladder:game-submitted': c.object {required: ['session', 'level']},
    session: {type: 'object'}
    level: {type: 'object'}

  'supermodel:load-progress-changed': c.object {required: ['progress']},
    progress: {type: 'number', minimum: 0, maximum: 1}
