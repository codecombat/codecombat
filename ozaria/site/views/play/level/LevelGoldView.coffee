require('ozaria/site/styles/play/level/gold.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/play/level/gold'
teamTemplate = require 'templates/play/level/team_gold'

module.exports = class LevelGoldView extends CocoView
  id: 'gold-view'
  template: template

  subscriptions:
    'surface:gold-changed': 'onGoldChanged'
    'level:set-letterbox': 'onSetLetterbox'

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
      goldEl = @$el.find('.gold-amount.team-' + e.team)
    text = '' + e.gold
    if e.goldEarned and e.goldEarned > e.gold
      text += " (#{e.goldEarned})"
    goldEl.text text
    @updateTitle()
    @$el.show()
    @shownOnce = true

  updateTitle: ->
    strings = []
    for team, gold of @teamGold
      if @teamGoldEarned[team]
        strings.push "Team '#{team}' has #{gold} now of #{@teamGoldEarned[team]} gold earned."
      else
        strings.push "Team '#{team}' has #{gold} gold."
    @$el.attr 'title', strings.join ' '

  onSetLetterbox: (e) ->
    @$el.toggle not e.on if @shownOnce
