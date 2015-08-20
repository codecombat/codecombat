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
    #'surface:gold-changed': 'onGoldChanged'
    'god:new-world-created': 'onNewWorld'
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
    #@teamGold = {}
    #@teamGoldEarned = {}

  getRenderData: (c) ->
    c = super c
    c.players = @players = (@formatPlayer team for team in ['humans', 'ogres'])
    c

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

  buildAvatar: (heroID, team) ->
    @avatars ?= {}
    return if @avatars[team]
    thang = _.find @options.thangs, id: heroID
    @avatars[team] = avatar = new ThangAvatarView thang: thang, includeName: false, supermodel: @supermodel
    @$find(team, '.thang-avatar-placeholder').replaceWith avatar.$el
    avatar.render()

  onNewWorld: (e) ->
    @thangs = _.filter e.world.thangs, 'inThangList'

  onFrameChanged: (e) ->
    @update()

  update: ->
    for player in @players
      # etc.
      thang = @avatars[player.team].thang
      @updateHealth thang

  updateHealth: (thang) ->
    $health = @$find thang.team, '.player-health'
    console.log 'updating health for', thang.id, thang.health, thang.maxHealth, 'with el', $health
    $health.find('.health-bar').css 'width', Math.max(0, Math.min(100, 100 * thang.health / thang.maxHealth)) + '%'
    utils.replaceText $health.find('.health-value'), Math.round thang.health

  $find: (team, selector) ->
    @$el.find(".player-container.team-#{team} " + selector)

  destroy: ->
    avatar.destroy() for team, avatar of @avatars ? {}
    super()

  #onGoldChanged: (e) ->
  #  return if @teamGold[e.team] is e.gold and @teamGoldEarned[e.team] is e.goldEarned
  #  @teamGold[e.team] = e.gold
  #  @teamGoldEarned[e.team] = e.goldEarned
  #  goldEl = @$find e.team, '.gold-amount'
  #  text = '' + e.gold
  #  if e.goldEarned and e.goldEarned > e.gold
  #    text += " (#{e.goldEarned})"
  #  goldEl.text text
  #  @updateTitle()
  #
  #updateTitle: ->
  #  for team, gold of @teamGold
  #    if @teamGoldEarned[team]
  #      title = "Team '#{team}' has #{gold} now of #{@teamGoldEarned[team]} gold earned."
  #    else
  #      title = "Team '#{team}' has #{gold} gold."
  #    @$find(team, '.player-gold').attr 'title', title
