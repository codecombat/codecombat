/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let PlayWebDevLevelView;
require('app/styles/play/level/play-web-dev-level-view.sass');
const RootView = require('views/core/RootView');

const Level = require('models/Level');
const LevelSession = require('models/LevelSession');
const WebSurfaceView = require('./WebSurfaceView');
const api = require('core/api');

require('lib/game-libraries');
const utils = require('core/utils');

module.exports = (PlayWebDevLevelView = (function() {
  PlayWebDevLevelView = class PlayWebDevLevelView extends RootView {
    static initClass() {
      this.prototype.id = 'play-web-dev-level-view';
      this.prototype.template = require('app/templates/play/level/play-web-dev-level-view');
    }

    initialize(options, sessionID) {
      this.options = options;
      this.sessionID = sessionID;
      super.initialize(this.options);

      this.courseID = utils.getQueryVariable('course');
      this.session = this.supermodel.loadModel(new LevelSession({_id: this.sessionID})).model;
      this.level = new Level();
      return this.session.once('sync', () => {
        const levelResource = this.supermodel.addSomethingResource('level');
        return api.levels.getByOriginal(this.session.get('level').original).then(levelData => {
          this.levelID = levelData.slug;
          this.level.set({ _id: this.levelID });
          this.level.fetch();
          return this.level.once('sync', () => {
            levelResource.markLoaded();

            return this.setMeta({
              title: $.i18n.t('play.web_development_title', { level: this.level.get('name') })
            });
          });
        });
      });
    }

    getMeta() {
      return {
        links: [
          { vmid: 'rel-canonical', rel: 'canonical', href: '/play'}
        ]
      };
    }

    onLoaded() {
      let left;
      super.onLoaded();
      this.insertSubView(this.webSurface = new WebSurfaceView({level: this.level}));
      Backbone.Mediator.publish('tome:html-updated', {html: (left = this.getHTML()) != null ? left : '<h1>Player has no HTML</h1>', create: true});
      this.$el.find('#info-bar').delay(4000).fadeOut(2000);
      $('body').css('overflow', 'hidden');  // Don't show tiny scroll bar from our minimal additions to the iframe
      this.eventProperties = {
        category: 'Play WebDev Level',
        courseID: this.courseID,
        sessionID: this.session.id,
        levelID: this.level.id,
        levelSlug: this.level.get('slug')
      };
      return (window.tracker != null ? window.tracker.trackEvent('Play WebDev Level - Load', this.eventProperties) : undefined);
    }


    showError(jqxhr) {
      return $('h1').text(jqxhr.statusText);
    }

    getHTML() {
      let hero, programmableConfig;
      const playerHTML = __guard__(__guard__(this.session.get('code'), x1 => x1['hero-placeholder']), x => x.plan);
      if (!(hero = _.find(this.level.get('thangs'), {id: 'Hero Placeholder'}))) { return playerHTML; }
      if (!(programmableConfig = _.find(hero.components, component => component.config != null ? component.config.programmableMethods : undefined).config)) { return playerHTML; }
      return programmableConfig.programmableMethods.plan.languages.html.replace(/<playercode>[\s\S]*<\/playercode>/, playerHTML);
    }

    destroy() {
      if (this.webSurface != null) {
        this.webSurface.destroy();
      }
      $('body').css('overflow', 'initial');  // Recover from our modifications to body overflow before we leave
      return super.destroy();
    }
  };
  PlayWebDevLevelView.initClass();
  return PlayWebDevLevelView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}