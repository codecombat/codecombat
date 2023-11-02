// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let HeroSelectView;
require('app/styles/core/hero-select-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/core/hero-select-view');
const State = require('models/State');
const ThangTypeConstants = require('lib/ThangTypeConstants');
const ThangTypeLib = require('lib/ThangTypeLib');
const User = require('models/User');
const api = require('core/api');
const utils = require('core/utils');

module.exports = (HeroSelectView = (function() {
  HeroSelectView = class HeroSelectView extends CocoView {
    static initClass() {
      this.prototype.id = 'hero-select-view';
      this.prototype.template = template;
  
      this.prototype.events =
        {'click .hero-option': 'onClickHeroOption'};
    }

    initialize(options) {
      let currentHeroOriginal, defaultHeroOriginal;
      if (options == null) { options = {}; }
      this.options = options;
      if (utils.isCodeCombat) {
        defaultHeroOriginal = ThangTypeConstants.heroes.captain;
        currentHeroOriginal = __guard__(me.get('heroConfig'), x => x.thangType) || defaultHeroOriginal;
      } else {
        defaultHeroOriginal = ThangTypeConstants.ozariaHeroes['hero-b'];
        currentHeroOriginal = __guard__(me.get('ozariaUserOptions'), x1 => x1.isometricThangTypeOriginal) || defaultHeroOriginal;
      }

      this.debouncedRender = _.debounce(this.render, 0);

      this.state = new State({
        currentHeroOriginal,
        selectedHeroOriginal: currentHeroOriginal
      });

      if (utils.isCodeCombat) {
        api.thangTypes.getHeroes({ project: ['original', 'name', 'shortName', 'i18n', 'heroClass', 'slug', 'ozaria', 'poseImage'] }).then(heroes => {
          if (this.destroyed) { return; }
          this.heroes = heroes.filter(function(hero) {
            let clanHero;
            if (hero.ozaria) { return false; }
            if (clanHero = _.find(utils.clanHeroes, {thangTypeOriginal: hero.original})) {
              let left, needle;
              if ((needle = clanHero.clanId, !Array.from(((left = me.get('clans')) != null ? left : [])).includes(needle))) { return false; }
            }
            if (hero.original === ThangTypeConstants.heroes['code-ninja']) {
              if (window.location.host !== 'coco.code.ninja') { return false; }
            }
            return true;
          });
          return this.debouncedRender();
        });
       } else {
        // @heroes = new ThangTypes({}, { project: ['original', 'name', 'heroClass, 'slug''] })
        // @supermodel.trackRequest @heroes.fetchHeroes()

        api.thangTypes.getHeroes({ project: ['original', 'name', 'shortName', 'heroClass', 'slug', 'ozaria'] }).then(heroes => {
          this.heroes = heroes.filter(h => !h.ozaria);
          return this.debouncedRender();
        });
      }

      return this.listenTo(this.state, 'all', function() { return this.debouncedRender(); });
    }
      // @listenTo @heroes, 'all', -> @debouncedRender()

    onClickHeroOption(e) {
      const heroOriginal = $(e.currentTarget).data('hero-original');
      this.state.set({selectedHeroOriginal: heroOriginal});
      return this.saveHeroSelection(heroOriginal);
    }

    getPortraitURL(hero) {
      return ThangTypeLib.getPortraitURL(hero);
    }

    getHeroShortName(hero) {
      return ThangTypeLib.getHeroShortName(hero);
    }

    saveHeroSelection(heroOriginal) {
      if (!me.get('heroConfig')) { me.set({heroConfig: {}}); }
      const heroConfig = _.assign({}, me.get('heroConfig'), { thangType: heroOriginal });
      me.set({ heroConfig });

      const hero = _.find(this.heroes, { original: heroOriginal });
      return me.save().then(() => {
        if (utils.isCodeCmbat && this.destroyed) { return; }
        let event = 'Hero selected';
        event += me.isStudent() ? ' student' : ' teacher';
        if (this.options.createAccount) { event += ' create account'; }
        const category = me.isStudent() ? 'Students' : 'Teachers';
        if (window.tracker != null) {
          window.tracker.trackEvent(event, {category, heroOriginal});
        }
        return this.trigger('hero-select:success', {attributes: hero});
    });
    }
  };
  HeroSelectView.initClass();
  return HeroSelectView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}