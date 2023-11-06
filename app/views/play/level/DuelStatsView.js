/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let DuelStatsView;
require('app/styles/play/level/duel-stats-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/play/level/duel-stats-view');
const ThangAvatarView = require('views/play/level/ThangAvatarView');
const utils = require('core/utils');

// TODO:
// - if a hero is dead, a big indication that they are dead
// - each hero's current action?
// - if one player is you, an indicator that it's you?
// - indication of which team won (not always hero dead--ties and other victory conditions)
// - army composition or power or attack/defense (for certain levels): experiment with something simple, not like the previous unit list thing

module.exports = (DuelStatsView = (function() {
  DuelStatsView = class DuelStatsView extends CocoView {
    static initClass() {
      this.prototype.id = 'duel-stats-view';
      this.prototype.template = template;

      this.prototype.subscriptions = {
        'surface:gold-changed': 'onGoldChanged',
        'god:new-world-created': 'onNewWorld',
        'god:streaming-world-updated': 'onNewWorld',
        'surface:frame-changed': 'onFrameChanged',
        'sprite:speech-updated': 'onSpriteDialogue',
        'level:sprite-clear-dialogue': 'onSpriteClearDialogue'
      };
    }

    constructor(options) {
      super(options);
      let needle;
      options.thangs = _.filter(options.thangs, 'inThangList');
      if (!options.otherSession) {
        options.otherSession = { get: prop => ({
          creatorName: $.i18n.t('ladder.simple_ai'),
          creator: me.get('_id'), // fake a creator to make sure we don't anonymize ai names
          team: options.session.get('team') === 'humans' ? 'ogres' : 'humans',
          heroConfig: options.session.get('heroConfig')
        }[prop])
      };
      }
      this.showsPower = (needle = options.level.get('slug'), !['wakka-maul', 'cross-bones', 'dueling-grounds', 'cavern-survival', 'multiplayer-treasure-grove'].includes(needle));
      this.teamGold = {};
      this.players = (['humans', 'ogres'].map((team) => this.formatPlayer(team)));
    }

    formatPlayer(team) {
      let left;
      const p = {team};
      const session = _.find([this.options.session, this.options.otherSession], s => s.get('team') === team);
      p.name = utils.getCorrectName(session);
      p.heroThangType = ((left = session.get('heroConfig')) != null ? left : {}).thangType || '529ffbf1cf1818f2be000001';
      p.heroID = team === 'ogres' ? 'Hero Placeholder 1' : 'Hero Placeholder';
      return p;
    }

    afterRender() {
      super.afterRender();
      for (var player of Array.from(this.players)) {
        this.buildAvatar(player.heroID, player.team);
      }
      return this.$el.css('display', 'flex');  // Show it
    }

    buildAvatar(heroID, team) {
      let avatar;
      if (this.avatars == null) { this.avatars = {}; }
      if (this.avatars[team]) { return; }
      const thang = _.find(this.options.thangs, {id: heroID});
      if (!thang) { return; }
      this.avatars[team] = (avatar = new ThangAvatarView({thang, includeName: false, supermodel: this.supermodel}));
      this.$find(team, '.thang-avatar-placeholder').replaceWith(avatar.$el);
      return avatar.render();
    }

    onNewWorld(e) {
      return this.options.thangs = _.filter(e.world.thangs, 'inThangList');
    }

    onFrameChanged(e) {
      return this.update();
    }

    update() {
      for (var player of Array.from(this.players)) {
        var thang;
        if (thang = (_.find(this.options.thangs, {id: __guard__(__guard__(this.avatars != null ? this.avatars[player.team] : undefined, x1 => x1.thang), x => x.id)}))) {
          this.updateHealth(thang);
        }
      }
      if (this.showsPower) { return this.updatePower(); }
    }

    updateHealth(thang) {
      const $health = this.$find(thang.team, '.player-health');
      $health.find('.health-bar').css('width', Math.max(0, Math.min(100, (100 * thang.health) / thang.maxHealth)) + '%');
      return utils.replaceText($health.find('.health-value'), Math.round(thang.health));
    }

    updatePower() {
      // Right now we just display the army cost of all living units as opposed to doing something more sophisticate to measure power.
      let player;
      if (this.costTable == null) { this.costTable = {
        soldier: 20,
        archer: 25,
        decoy: 25,
        'griffin-rider': 50,
        paladin: 80,
        artillery: 75,
        'arrow-tower': 100,
        palisade: 10,
        peasant: 50,
        thrower: 9,
        scout: 18
      }; }
      const powers = {humans: 0, ogres: 0};
      const setPowerTeams = [];
      for (player of Array.from(this.players)) {
        var hero = _.find(this.options.thangs, {id: __guard__(__guard__(this.avatars != null ? this.avatars[player.team] : undefined, x1 => x1.thang), x => x.id)});
        if (!hero) { continue; }
        if ((hero.teamPower != null) && (powers[hero.team] != null)) {
          powers[hero.team] = hero.teamPower;
          setPowerTeams.push(hero.team);
        }
      }
      // Count only thangs from teams which heroes doesn't have teamPower
      for (var thang of Array.from(this.options.thangs)) {
        if (!Array.from(setPowerTeams).includes(thang.team) && (thang.health > 0) && thang.exists) {
          if (powers[thang.team] != null) { powers[thang.team] += this.costTable[thang.type] || 0; }
        }
      }
      return (() => {
        const result = [];
        for (player of Array.from(this.players)) {
          result.push(utils.replaceText(this.$find(player.team, '.power-value'), powers[player.team]));
        }
        return result;
      })();
    }

    $find(team, selector) {
      return this.$el.find(`.player-container.team-${team} ` + selector);
    }

    destroy() {
      const object = this.avatars != null ? this.avatars : {};
      for (var team in object) { var avatar = object[team]; avatar.destroy(); }
      return super.destroy();
    }

    onGoldChanged(e) {
      if (!this.options.showsGold) { return; }
      if (this.teamGold[e.team] === e.gold) { return; }
      this.teamGold[e.team] = e.gold;
      return utils.replaceText(this.$find(e.team, '.gold-value'), '' + e.gold);
    }

    onSpriteDialogue(e) {
      if (!e.message) { return; }
      return this.$el.css('display', 'none');  // Hide it while a blue message is showing
    }

    onSpriteClearDialogue() {
      return this.$el.css('display', 'flex');
    }
  };
  DuelStatsView.initClass();
  return DuelStatsView;  // Show it
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}