View = require 'views/kinds/CocoView'
template = require 'templates/play/level/gold'

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
      teamEl = $("<div class='team-gold team-#{e.team}' title='Gold: #{e.team}'><img src='/images/level/prop_gold.png'> <div class='gold-amount team-#{e.team}'></div></div>")
      @$el.append(teamEl)
      goldEl = teamEl.find('.gold-amount.team-' + e.team)
    goldEl.text(e.gold)

  onSetLetterbox: (e) ->
    @$el.toggle not e.on
