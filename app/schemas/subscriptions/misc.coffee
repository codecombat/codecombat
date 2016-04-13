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
    delay: {type: 'integer', minimum: 0, format: 'milliseconds'}

  'music-player:enter-menu': c.object {required: []},
    terrain: {type: 'string'}

  'music-player:exit-menu': c.object {}

  'modal:opened': c.object {}

  'modal:closed': c.object {}

  'modal:open-modal-view': c.object {required: ['modalPath']},
    modalPath: {type: 'string'}

  'router:navigate': c.object {required: ['route']},
    route: {type: 'string'}
    view: {type: 'object'}
    viewClass: {type: ['function', 'string']}
    viewArgs: {type: 'array'}

  'router:navigated': c.object {required: ['route']},
    route: {type: 'string'}

  'achievements:new': c.object {required: ['earnedAchievements']},
    earnedAchievements: {type: 'object'}

  'ladder:game-submitted': c.object {required: ['session', 'level']},
    session: {type: 'object'}
    level: {type: 'object'}

  'buy-gems-modal:update-products': { }

  'buy-gems-modal:purchase-initiated': c.object {required: ['productID']},
    productID: { type: 'string' }

  'subscribe-modal:subscribed': c.object {}

  'stripe:received-token': c.object { required: ['token'] },
    token: { type: 'object', properties: {
      id: {type: 'string'}
    }}

  'store:item-purchased': c.object {required: ['item', 'itemSlug']},
    item: {type: 'object'}
    itemSlug: {type: 'string'}

  'store:hero-purchased': c.object {required: ['hero', 'heroSlug']},
    hero: {type: 'object'}
    heroSlug: {type: 'string'}

  'application:service-loaded': c.object {required: ['service']},
    service: {type: 'string'}  # 'segment'

  'test:update': c.object {},
     state: {type: 'string'}
