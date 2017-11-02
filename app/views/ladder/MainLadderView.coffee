require('app/styles/play/ladder_home.sass')
RootView = require 'views/core/RootView'
template = require 'templates/play/ladder_home'
LevelSession = require 'models/LevelSession'
CocoCollection = require 'collections/CocoCollection'

class LevelSessionsCollection extends CocoCollection
  url: ''
  model: LevelSession

  constructor: (model) ->
    super()
    @url = "/db/user/#{me.id}/level.sessions?project=state.complete,levelID"

module.exports = class MainLadderView extends RootView
  id: 'main-ladder-view'
  template: template

  initialize: ->
    @levelStatusMap = []
    @levelPlayCountMap = []
    @campaigns = campaigns

    @sessions = @supermodel.loadCollection(new LevelSessionsCollection(), 'your_sessions', {cache: false}, 0).model
    @listenToOnce @sessions, 'sync', @onSessionsLoaded

    @getLevelPlayCounts()

  onSessionsLoaded: (e) ->
    for session in @sessions.models
      @levelStatusMap[session.get('levelID')] = if session.get('state')?.complete then 'complete' else 'started'
    @render()

  getLevelPlayCounts: ->
    success = (levelPlayCounts) =>
      return if @destroyed
      for level in levelPlayCounts
        @levelPlayCountMap[level._id] = playtime: level.playtime, sessions: level.sessions
      @render() if @supermodel.finished()

    levelIDs = []
    for campaign in campaigns
      for level in campaign.levels
        levelIDs.push level.id
    levelPlayCountsRequest = @supermodel.addRequestResource 'play_counts', {
      url: '/db/level/-/play_counts'
      data: {ids: levelIDs}
      method: 'POST'
      success: success
    }, 0
    levelPlayCountsRequest.load()

heroArenas = [
  {
    name: 'Ace of Coders'
    difficulty: 3
    id: 'ace-of-coders'
    image: '/file/db/level/55de80407a57948705777e89/Ace-of-Coders-banner.png'
    description: 'Battle for control over the icy treasure chests as your gigantic warrior marshals his armies against his mirror-match nemesis.'
  }
  {
    name: 'Zero Sum'
    difficulty: 3
    id: 'zero-sum'
    image: '/file/db/level/550363b4ec31df9c691ab629/MAR26-Banner_Zero%20Sum.png'
    description: 'Unleash your coding creativity in both gold gathering and battle tactics in this alpine mirror match between red sorcerer and blue sorcerer.'
  }
  {
    name: 'Cavern Survival'
    difficulty: 1
    id: 'cavern-survival'
    image: '/file/db/level/544437e0645c0c0000c3291d/OCT30-Cavern%20Survival.png'
    description: 'Stay alive longer than your multiplayer opponent amidst hordes of ogres!'
  }
  {
    name: 'Dueling Grounds'
    difficulty: 1
    id: 'dueling-grounds'
    image: '/file/db/level/5442ba0e1e835500007eb1c7/OCT27-Dueling%20Grounds.png'
    description: 'Battle head-to-head against another hero in this basic beginner combat arena.'
  }
  {
    name: 'Multiplayer Treasure Grove'
    difficulty: 2
    id: 'multiplayer-treasure-grove'
    image: '/file/db/level/5469643c37600b40e0e09c5b/OCT27-Multiplayer%20Treasure%20Grove.png'
    description: 'Mix collection, flags, and combat in this multiplayer coin-gathering arena.'
  }
  {
    name: 'Harrowland'
    difficulty: 2
    id: 'harrowland'
    image: '/file/db/level/54b83c2629843994803c838e/OCT27-Harrowland.png'
    description: 'Go head-to-head against another player in this dueling arena--but watch out for their friends!'
  }
]

campaigns = [
  {id: 'multiplayer', name: 'Multiplayer Arenas', description: '... in which you code head-to-head against other players.', levels: heroArenas}
]
