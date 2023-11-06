/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let HintsView;
const CocoView = require('views/core/CocoView');
const State = require('models/State');
const ace = require('lib/aceContainer');
const utils = require('core/utils');
const aceUtils = require('core/aceUtils');
const aetherUtils = require('lib/aether_utils');

module.exports = (HintsView = (function() {
  HintsView = class HintsView extends CocoView {
    constructor(...args) {
      super(...args);
      this.incrementHintViewTime = this.incrementHintViewTime.bind(this);
    }

    static initClass() {
      this.prototype.template = require('templates/play/level/hints-view');
      this.prototype.className = 'hints-view';
      this.prototype.hintUsedThresholdSeconds = 10;

      this.prototype.events = {
        'click .next-btn': 'onClickNextButton',
        'click .previous-btn': 'onClickPreviousButton',
        'click .close-hint-btn': 'hideView'
      };

      this.prototype.subscriptions = {
        'level:show-victory': 'hideView',
        'tome:manual-cast': 'hideView'
      };
    }

    initialize(options) {
      ({level: this.level, session: this.session, hintsState: this.hintsState} = options);
      this.state = new State({
        hintIndex: 0,
        hintsViewTime: {},
        hintsUsed: {}
      });
      this.updateHint();

      const debouncedRender = _.debounce(this.render);
      this.listenTo(this.state, 'change', debouncedRender);
      this.listenTo(this.hintsState, 'change', debouncedRender);
      this.listenTo(this.state, 'change:hintIndex', this.updateHint);
      return this.listenTo(this.hintsState, 'change:hidden', this.visibilityChanged);
    }

    destroy() {
      clearInterval(this.timerIntervalID);
      return super.destroy();
    }

    afterRender() {
      this.$el.toggleClass('hide', this.hintsState.get('hidden'));
      super.afterRender();
      this.playSound('game-menu-open');
      this.$('a').attr('target', '_blank');
      const codeLanguage = this.options.session.get('codeLanguage') || __guard__(me.get('aceConfig'), x => x.language) || 'python';

      for (var oldEditor of Array.from(this.aceEditors != null ? this.aceEditors : [])) { oldEditor.destroy(); }
      this.aceEditors = [];
      const {
        aceEditors
      } = this;
      return this.$el.find('pre:has(code[class*="lang-"])').each(function() {
        const aceEditor = aceUtils.initializeACE(this, codeLanguage);
        return aceEditors.push(aceEditor);
      });
    }

    getProcessedHint() {
      const language = this.session.get('codeLanguage');
      const hint = this.state.get('hint');
      if (!hint) { return; }

      // process
      const translated = utils.i18n(hint, 'body');
      const filtered = aetherUtils.filterMarkdownCodeLanguages(translated, language);
      const markedUp = marked(filtered);

      return markedUp;
    }

    updateHint() {
      const index = this.state.get('hintIndex');
      const hintsTitle = $.i18n.t('play_level.hints_title').replace('{{number}}', index + 1);
      return this.state.set({ hintsTitle, hint: this.hintsState.getHint(index) });
    }

    onClickNextButton() {
      if (window.tracker != null) {
        let left;
        window.tracker.trackEvent('Hints Next Clicked', {category: 'Students', levelSlug: this.level.get('slug'), hintCount: (left = __guard__(this.hintsState.get('hints'), x => x.length)) != null ? left : 0, hintCurrent: this.state.get('hintIndex')}, []);
      }
      const max = this.hintsState.get('total') - 1;
      this.state.set('hintIndex', Math.min(this.state.get('hintIndex') + 1, max));
      this.playSound('menu-button-click');
      return this.updateHintTimer();
    }

    onClickPreviousButton() {
      if (window.tracker != null) {
        let left;
        window.tracker.trackEvent('Hints Previous Clicked', {category: 'Students', levelSlug: this.level.get('slug'), hintCount: (left = __guard__(this.hintsState.get('hints'), x => x.length)) != null ? left : 0, hintCurrent: this.state.get('hintIndex')}, []);
      }
      this.state.set('hintIndex', Math.max(this.state.get('hintIndex') - 1, 0));
      this.playSound('menu-button-click');
      return this.updateHintTimer();
    }

    hideView() {
      if (this.hintsState != null) {
        this.hintsState.set('hidden', true);
      }
      return this.playSound('game-menu-close');
    }

    visibilityChanged(e) {
      return this.updateHintTimer();
    }

    updateHintTimer() {
      clearInterval(this.timerIntervalID);
      if (!this.hintsState.get('hidden') && !__guard__(this.state.get('hintsUsed'), x => x[this.state.get('hintIndex')])) {
        return this.timerIntervalID = setInterval(this.incrementHintViewTime, 1000);
      }
    }

    incrementHintViewTime() {
      const hintIndex = this.state.get('hintIndex');
      const hintsViewTime = this.state.get('hintsViewTime');
      if (hintsViewTime[hintIndex] == null) { hintsViewTime[hintIndex] = 0; }
      hintsViewTime[hintIndex]++;
      const hintsUsed = this.state.get('hintsUsed');
      if ((hintsViewTime[hintIndex] > this.hintUsedThresholdSeconds) && !hintsUsed[hintIndex]) {
        if (window.tracker != null) {
          let left;
          window.tracker.trackEvent('Hint Used', {category: 'Students', levelSlug: this.level.get('slug'), hintCount: (left = __guard__(this.hintsState.get('hints'), x => x.length)) != null ? left : 0, hintCurrent: hintIndex}, []);
        }
        hintsUsed[hintIndex] = true;
        this.state.set('hintsUsed', hintsUsed);
        clearInterval(this.timerIntervalID);
      }
      return this.state.set('hintsViewTime', hintsViewTime);
    }
  };
  HintsView.initClass();
  return HintsView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}