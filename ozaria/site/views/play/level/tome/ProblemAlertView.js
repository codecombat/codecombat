/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ProblemAlertView;
require('ozaria/site/styles/play/level/tome/problem_alert.sass');
const CocoView = require('views/core/CocoView');
const GameMenuModal = require('views/play/menu/GameMenuModal');
const template = require('ozaria/site/templates/play/level/tome/problem_alert');
const {me} = require('core/auth');

module.exports = (ProblemAlertView = (function() {
  ProblemAlertView = class ProblemAlertView extends CocoView {
    static initClass() {
      this.prototype.id = 'problem-alert-view';
      this.prototype.className = 'problem-alert';
      this.prototype.template = template;
      this.prototype.duckImages = [
        '/images/pages/play/duck_alejandro.png',
        '/images/pages/play/duck_anya2.png',
        '/images/pages/play/duck_ida.png',
        '/images/pages/play/duck_okar.png',
        '/images/pages/play/duck_tharin2.png'
      ];

      this.prototype.subscriptions = {
        'tome:show-problem-alert': 'onShowProblemAlert',
        'tome:hide-problem-alert': 'onHideProblemAlert',
        'level:restart': 'onHideProblemAlert',
        'tome:jiggle-problem-alert': 'onJiggleProblemAlert',
        'tome:manual-cast': 'onHideProblemAlert'
      };

      this.prototype.events = {
        'click .close': 'onRemoveClicked',
        'click'() { return Backbone.Mediator.publish('tome:focus-editor', {}); }
      };
    }

    constructor(options) {
      super(options);
      this.onWindowResize = this.onWindowResize.bind(this);
      // this.supermodel = options.supermodel; // Has to go before super so events are hooked up
      this.level = options.level;
      this.session = options.session;
      if (options.problem != null) {
        this.problem = options.problem;
        this.onWindowResize();
      } else {
        this.$el.hide();
      }
      this.duckImg = _.sample(this.duckImages);
      $(window).on('resize', this.onWindowResize);
    }

    destroy() {
      $(window).off('resize', this.onWindowResize);
      return super.destroy();
    }

    afterRender() {
      super.afterRender();
      if (this.problem != null) {
        this.$el.addClass(`alert-${this.problem.level}`).hide().fadeIn('slow');
        if (!this.problem.hint) { this.$el.addClass('no-hint'); }
        return this.playSound('error_appear');
      }
    }

    setProblemMessage() {
      if (this.problem != null) {
        const format = function(s) { if (s != null) { return marked(s); } };
        let {
          message
        } = this.problem;
        // Add time to problem message if hint is for a missing null check
        // NOTE: This may need to be updated with Aether error hint changes
        if ((this.problem.hint != null) && /(?:null|undefined)/.test(this.problem.hint)) {
          const age = this.problem.userInfo != null ? this.problem.userInfo.age : undefined;
          if (age != null) {
            if (/^Line \d+:/.test(message)) {
              message = message.replace(/^(Line \d+)/, `$1, time ${age.toFixed(1)}`);
            } else {
              message = `Time ${age.toFixed(1)}: ${message}`;
            }
          }
        }
        if (this.problem.hint && /TypeError: .*? is not a function/.test(message)) {
          // This is not useful to add on, so suppress it and just show the hint.
          this.message = null;
        } else {
          this.message = format(message);
        }
        return this.hint = format(this.problem.hint);
      }
    }

    onShowProblemAlert(data) {
      if (!$('#code-area').is(":visible") && !this.level.isType('game-dev')) { return; }
      if (this.problem != null) {
        if (this.$el.hasClass(`alert-${this.problem.level}`)) {
          this.$el.removeClass(`alert-${this.problem.level}`);
        }
        if (this.$el.hasClass("no-hint")) {
          this.$el.removeClass("no-hint");
        }
      }
      this.problem = data.problem;
      this.lineOffsetPx = data.lineOffsetPx || 0;
      this.$el.show();
      this.onWindowResize();
      this.setProblemMessage();
      this.render();
      this.onJiggleProblemAlert();
      if (application.tracker != null) {
        application.tracker.trackEvent('Show problem alert', {levelID: this.level.get('slug'), ls: (this.session != null ? this.session.get('_id') : undefined)});
      }
      return this.announceToScreenReader();
    }

    onJiggleProblemAlert() {
      if (this.problem == null) { return; }
      if (!this.$el.is(":visible")) { this.$el.show(); }
      this.$el.addClass('jiggling');
      this.playSound('error_appear');
      const pauseJiggle = () => {
        return (this.$el != null ? this.$el.removeClass('jiggling') : undefined);
      };
      return _.delay(pauseJiggle, 1000);
    }

    onHideProblemAlert() {
      if (!this.$el.is(':visible')) { return; }
      return this.onRemoveClicked();
    }

    onRemoveClicked() {
      this.playSound('menu-button-click');
      this.$el.hide();
      return Backbone.Mediator.publish('tome:focus-editor', {});
    }

    onWindowResize(e) {
      // TODO: This all seems a little hacky
      if (this.problem != null) {
        const codeAreaWidth = $('#code-area').outerWidth(true);
        this.$el.css('right', codeAreaWidth + 20 + 'px');

        // TODO: calculate this in a more dynamic, less sketchy way
        const spellViewTop = $("#spell-view").position().top - 30; // roughly aligns top of alert with top of first code line
        return this.$el.css('top', (spellViewTop + this.lineOffsetPx) + 'px');
      }
    }

    announceToScreenReader() {
      let update;
      const message = this.hint || this.message;
      if (this.problem.row != null) {
        if (/Error/.test(message)) {
          update = `Line ${this.problem.row + 1}: ${message.replace(/^Line \d+:? ?/, '')}`;
        } else {
          update = `Error on line ${this.problem.row + 1}: ${message.replace(/^Line \d+:? ?/, '')}`;
        }
      } else {
        if (/Error/.test(message)) {
          update = message;
        } else {
          update = `Error: ${message}`;
        }
      }
      return $('#screen-reader-live-updates').append($(`<div>${update}</div>`));
    }
  };
  ProblemAlertView.initClass();
  return ProblemAlertView;  // TODO: move this to a store or lib? Limit how many lines?
})());
