View = require 'views/kinds/RootView'
template = require 'templates/play/ladder_home'
LevelSession = require 'models/LevelSession'
CocoCollection = require 'collections/CocoCollection'

class LevelSessionsCollection extends CocoCollection
  url: ''
  model: LevelSession

  constructor: (model) ->
    super()
    @url = "/db/user/#{me.id}/level.sessions?project=state.complete,levelID"

module.exports = class LadderHomeView extends View
  id: 'ladder-home-view'
  template: template

  constructor: (options) ->
    super options
    @levelStatusMap = {}
    @sessions = new LevelSessionsCollection()
    @sessions.fetch()
    @listenToOnce @sessions, 'sync', @onSessionsLoaded

  onSessionsLoaded: (e) ->
    for session in @sessions.models
      @levelStatusMap[session.get('levelID')] = if session.get('state')?.complete then 'complete' else 'started'
    @render()

  getRenderData: (context={}) ->
    context = super(context)
    arenas = [
      {
        name: 'Greed'
        difficulty: 4
        id: 'greed'
        image: '/file/db/level/53558b5a9914f5a90d7ccddb/greed_banner.jpg'
        description: 'Liked Dungeon Arena and Gold Rush? Put them together in this economic arena!'
      }
      {
        name: 'Dungeon Arena'
        difficulty: 3
        id: 'dungeon-arena'
        image: '/file/db/level/53173f76c269d400000543c2/Level%20Banner%20Dungeon%20Arena.jpg'
        description: 'Play head-to-head against fellow Wizards in a dungeon melee!'
      }
      {
        name: 'Gold Rush'
        difficulty: 3
        id: 'gold-rush'
        image: '/file/db/level/533353722a61b7ca6832840c/Gold-Rush.png'
        description: 'Prove you are better at collecting gold than your opponent!'
      }
      {
        name: 'Brawlwood'
        difficulty: 4
        id: 'brawlwood'
        image: '/file/db/level/52d97ecd32362bc86e004e87/Level%20Banner%20Brawlwood.jpg'
        description: 'Combat the armies of other Wizards in a strategic forest arena! (Fast computer required.)'
      }
    ]

    context.campaigns = [
      {id: 'multiplayer', name: 'Multiplayer Arenas', description: '... in which you code head-to-head against other players.', levels: arenas}
    ]
    context.levelStatusMap = @levelStatusMap
    context

  afterRender: ->
    super()
    @$el.find('.modal').on 'shown.bs.modal', ->
      $('input:visible:first', @).focus()
