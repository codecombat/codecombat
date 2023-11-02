require('app/styles/play/level/duel-stats-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/play/level/duel-stats-view'
ThangAvatarView = require 'views/play/level/ThangAvatarView'
utils = require 'core/utils'

# TODO:
# - if a hero is dead, a big indication that they are dead
# - each hero's current action?
# - if one player is you, an indicator that it's you?
# - indication of which team won (not always hero dead--ties and other victory conditions)
# - army composition or power or attack/defense (for certain levels): experiment with something simple, not like the previous unit list thing

module.exports = class DuelStatsView extends CocoView
  id: 'duel-stats-view'
  template: template

  subscriptions:
    'surface:gold-changed': 'onGoldChanged'
    'god:new-world-created': 'onNewWorld'
    'god:streaming-world-updated': 'onNewWorld'
    'surface:frame-changed': 'onFrameChanged'

  constructor: (options) ->
    super options
    options.thangs = _.filter options.thangs, 'inThangList'
    unless options.otherSession
      options.otherSession = get: (prop) -> {
        creatorName: $.i18n.t 'ladder.simple_ai'
        team: if options.session.get('team') is 'humans' then 'ogres' else 'humans'
        heroConfig: options.session.get('heroConfig')
      }[prop]
    @showsPower = options.level.get('slug') not in ['wakka-maul', 'cross-bones', 'dueling-grounds', 'cavern-survival', 'multiplayer-treasure-grove']
    @teamGold = {}
    @players = (@formatPlayer team for team in ['humans', 'ogres'])

  formatPlayer: (team) ->
    p = team: team
    session = _.find [@options.session, @options.otherSession], (s) -> s.get('team') is team
    p.name = session.get 'creatorName'
    p.heroThangType = (session.get('heroConfig') ? {}).thangType or '529ffbf1cf1818f2be000001'
    p.heroID = if team is 'ogres' then 'Hero Placeholder 1' else 'Hero Placeholder'
    p

  afterRender: ->
    super()
    for player in @players
      @buildAvatar player.heroID, player.team
    @$el.css 'display', 'flex'  # Show it

  buildAvatar: (heroID, team) ->
    @avatars ?= {}
    return if @avatars[team]
    thang = _.find @options.thangs, id: heroID
    @avatars[team] = avatar = new ThangAvatarView thang: thang, includeName: false, supermodel: @supermodel
    @$find(team, '.thang-avatar-placeholder').replaceWith avatar.$el
    avatar.render()

  onNewWorld: (e) ->
    @options.thangs = _.filter e.world.thangs, 'inThangList'

  onFrameChanged: (e) ->
    @update()

  update: ->
    for player in @players
      thang = _.find @options.thangs, id: @avatars[player.team].thang.id
      @updateHealth thang
    @updatePower() if @showsPower

  updateHealth: (thang) ->
    $health = @$find thang.team, '.player-health'
    $health.find('.health-bar').css 'width', Math.max(0, Math.min(100, 100 * thang.health / thang.maxHealth)) + '%'
    utils.replaceText $health.find('.health-value'), Math.round thang.health

  updatePower: ->
    # Right now we just display the army cost of all living units as opposed to doing something more sophisticate to measure power.
    @costTable ?=
      soldier: 20
      archer: 25
      decoy: 25
      'griffin-rider': 50
      paladin: 80
      artillery: 75
      'arrow-tower': 100
      palisade: 10
      peasant: 50
      thrower: 9
      scout: 18
    powers = humans: 0, ogres: 0
    setPowerTeams = []
    for player in @players
      hero = _.find @options.thangs, id: @avatars[player.team].thang.id
      if hero.teamPower? and powers[hero.team]?
        powers[hero.team] = hero.teamPower
        setPowerTeams.push hero.team
    # Count only thangs from teams which heroes doesn't have teamPower
    for thang in @options.thangs when thang.team not in setPowerTeams and thang.health > 0 and thang.exists
      powers[thang.team] += @costTable[thang.type] or 0 if powers[thang.team]?
    for player in @players
      utils.replaceText @$find(player.team, '.power-value'), powers[player.team]

  $find: (team, selector) ->
    @$el.find(".player-container.team-#{team} " + selector)

  destroy: ->
    avatar.destroy() for team, avatar of @avatars ? {}
    super()

  onGoldChanged: (e) ->
    return unless @options.showsGold
    return if @teamGold[e.team] is e.gold
    @teamGold[e.team] = e.gold
    utils.replaceText @$find(e.team, '.gold-value'), '' + e.gold
