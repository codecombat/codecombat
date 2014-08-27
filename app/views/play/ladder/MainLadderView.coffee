RootView = require 'views/kinds/RootView'
template = require 'templates/play/ladder_home'
LevelSession = require 'models/LevelSession'
CocoCollection = require 'collections/CocoCollection'

class LevelSessionsCollection extends CocoCollection
  url: ''
  model: LevelSession

  constructor: (model) ->
    super()
    @url = "/db/user/#{me.id}/level.sessions?project=state.complete,levelID"

module.exports = class LadderHomeView extends RootView
  id: 'ladder-home-view'
  template: template

  constructor: (options) ->
    super options
    @levelStatusMap = {}
    @sessions = @supermodel.loadCollection(new LevelSessionsCollection(), 'your_sessions', null, 0).model
    @listenToOnce @sessions, 'sync', @onSessionsLoaded

  onSessionsLoaded: (e) ->
    for session in @sessions.models
      @levelStatusMap[session.get('levelID')] = if session.get('state')?.complete then 'complete' else 'started'
    @render()

  getRenderData: (context={}) ->
    context = super(context)
    arenas = [
      {
        name: 'Criss-Cross'
        difficulty: 5
        id: 'criss-cross'
        image: '/file/db/level/5391f3d519dc22b8082159b2/banner2.png'
        description: 'Participate in a bidding war with opponents to reach the other side!'
      }
      {
        name: 'Greed'
        difficulty: 4
        id: 'greed'
        image: '/file/db/level/53558b5a9914f5a90d7ccddb/greed_banner.jpg'
        description: 'Liked Dungeon Arena and Gold Rush? Put them together in this economic arena!'
      }
      {
        name: 'Sky Span (Testing)'
        difficulty: 3
        id: 'sky-span'
        image: '/file/db/level/53c80fce0ddbef000084c667/sky-Span-banner.jpg'
        description: 'Preview version of an upgraded Dungeon Arena. Help us with hero balance before release!'
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
