View = require 'views/kinds/CocoView'
template = require 'templates/play/level/gold'
teamTemplate = require 'templates/play/level/team_gold'

module.exports = class GoldView extends View
  id: 'gold-view'
  template: template

  subscriptions:
    'surface:gold-changed': 'onGoldChanged'
    'level-set-letterbox': 'onSetLetterbox'

  constructor: (options) ->
    super options
    @teamGold = {}
    @teamGoldEarned = {}
    @shownOnce = false

  onGoldChanged: (e) ->
    return if @teamGold[e.team] is e.gold and @teamGoldEarned[e.team] is e.goldEarned
    @teamGold[e.team] = e.gold
    @teamGoldEarned[e.team] = e.goldEarned
    goldEl = @$el.find('.gold-amount.team-' + e.team)
    unless goldEl.length
      teamEl = teamTemplate team: e.team
      @$el[if e.team is 'humans' then 'prepend' else 'append'](teamEl)
      goldEl = $('.gold-amount.team-' + e.team, teamEl)
    text = '' + e.gold
    if e.goldEarned and e.goldEarned > e.gold
      text += " (#{e.goldEarned})"
    goldEl.text text
    @updateTitle()
    @$el.show()
    @shownOnce = true

  updateTitle: ->
    @$el.attr 'title', ("Team '#{team}' has #{gold} now of #{@teamGoldEarned[team]} gold earned." for team, gold of @teamGold).join ' '

  onSetLetterbox: (e) ->
    @$el.toggle not e.on if @shownOnce
