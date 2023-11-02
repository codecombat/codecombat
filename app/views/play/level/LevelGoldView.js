/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LevelGoldView;
require('app/styles/play/level/gold.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/level/gold');
const teamTemplate = require('app/templates/play/level/team_gold');

module.exports = (LevelGoldView = (function() {
  LevelGoldView = class LevelGoldView extends CocoView {
    static initClass() {
      this.prototype.id = 'gold-view';
      this.prototype.template = template;
  
      this.prototype.subscriptions = {
        'surface:gold-changed': 'onGoldChanged',
        'level:set-letterbox': 'onSetLetterbox'
      };
    }

    constructor(options) {
      super(options);
      this.teamGold = {};
      this.teamGoldEarned = {};
      this.shownOnce = false;
    }

    onGoldChanged(e) {
      if ((this.teamGold[e.team] === e.gold) && (this.teamGoldEarned[e.team] === e.goldEarned)) { return; }
      this.teamGold[e.team] = e.gold;
      this.teamGoldEarned[e.team] = e.goldEarned;
      let goldEl = this.$el.find('.gold-amount.team-' + e.team);
      if (!goldEl.length) {
        const teamEl = teamTemplate({team: e.team});
        this.$el[e.team === 'humans' ? 'prepend' : 'append'](teamEl);
        goldEl = this.$el.find('.gold-amount.team-' + e.team);
      }
      let text = '' + e.gold;
      if (e.goldEarned && (e.goldEarned > e.gold)) {
        text += ` (${e.goldEarned})`;
      }
      goldEl.text(text);
      this.updateTitle();
      this.$el.show();
      return this.shownOnce = true;
    }

    updateTitle() {
      const strings = [];
      for (var team in this.teamGold) {
        var gold = this.teamGold[team];
        if (this.teamGoldEarned[team]) {
          strings.push(`Team '${team}' has ${gold} now of ${this.teamGoldEarned[team]} gold earned.`);
        } else {
          strings.push(`Team '${team}' has ${gold} gold.`);
        }
      }
      return this.$el.attr('title', strings.join(' '));
    }

    onSetLetterbox(e) {
      if (this.shownOnce) { return this.$el.toggle(!e.on); }
    }
  };
  LevelGoldView.initClass();
  return LevelGoldView;
})());
