View = require 'views/kinds/CocoView'
template = require 'templates/play/level/gold'
teamTemplate = require 'templates/play/level/team_gold'

module.exports = class GoldView extends View
  id: "gold-view"
  template: template

  subscriptions:
    'surface:gold-changed': 'onGoldChanged'
    'level-set-letterbox': 'onSetLetterbox'

  onGoldChanged: (e) ->
    @$el.show()
    goldEl = @$el.find('.gold-amount.team-' + e.team)
    unless goldEl.length
      teamEl = teamTemplate team: e.team
      @$el.append(teamEl)
      goldEl = $('.gold-amount.team-' + e.team, teamEl)
    text = '' + e.gold
    if e.goldEarned and e.goldEarned > e.gold
      text += " (#{e.goldEarned})"
    goldEl.text text

  onSetLetterbox: (e) ->
    @$el.toggle not e.on
