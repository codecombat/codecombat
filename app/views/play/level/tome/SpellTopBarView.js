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
let SpellTopBarView;
require('app/styles/play/level/tome/spell-top-bar-view.sass');
const template = require('app/templates/play/level/tome/spell-top-bar-view');
const ReloadLevelModal = require('views/play/level/modal/ReloadLevelModal');
const CocoView = require('views/core/CocoView');
const ImageGalleryModal = require('views/play/level/modal/ImageGalleryModal');
const utils = require('core/utils');
const CourseVideosModal = require('views/play/level/modal/CourseVideosModal');
const store = require('core/store');
const globalVar = require('core/globalVar');

module.exports = (SpellTopBarView = (function() {
  SpellTopBarView = class SpellTopBarView extends CocoView {
    static initClass() {
      this.prototype.template = template;
      this.prototype.id = 'spell-top-bar-view';
      this.prototype.controlsEnabled = true;

      this.prototype.subscriptions = {
        'level:disable-controls': 'onDisableControls',
        'level:enable-controls': 'onEnableControls',
        'tome:spell-loaded': 'onSpellLoaded',
        'tome:spell-changed': 'onSpellChanged',
        'tome:spell-changed-language': 'onSpellChangedLanguage',
        'tome:toggle-maximize': 'onToggleMaximize',
        'websocket:user-online': 'onUserOnlineChanged'
      };

      this.prototype.events = {
        'click .reload-code': 'onCodeReload',
        'click .beautify-code': 'onBeautifyClick',
        'click .fullscreen-code': 'onToggleMaximize',
        'click .hints-button': 'onClickHintsButton',
        'click .image-gallery-button': 'onClickImageGalleryButton',
        'click .videos-button': 'onClickVideosButton',
        'click #fill-solution': 'onFillSolution',
        'click #toggle-solution': 'onToggleSolution',
        'click #switch-team': 'onSwitchTeam',
        'click .toggle-blocks': 'onToggleBlocks',
        'click #ask-teacher-for-help': 'onClickHelpButton'
      };
    }

    constructor(options) {
      super(options);
      this.attachTransitionEventListener = this.attachTransitionEventListener.bind(this);
      this.otherTeam = this.otherTeam.bind(this);
      this.onSwitchTeam = this.onSwitchTeam.bind(this);
      this.hintsState = options.hintsState;
      this.spell = options.spell;
      this.courseInstanceID = options.courseInstanceID;
      this.courseID = options.courseID;
      this.blocks = options.blocks;
      this.blocksHidden = options.blocksHidden;
      this.teacherID = options.teacherID;
      this.teaching = utils.getQueryVariable('teaching');

      this.wsBus = globalVar.application.wsBus;
    }

    getRenderData(context) {
      if (context == null) { context = {}; }
      context = super.getRenderData(context);
      const ctrl = this.isMac() ? 'Cmd' : 'Ctrl';
      const shift = $.i18n.t('keyboard_shortcuts.shift');
      context.beautifyShortcutVerbose = `${ctrl}+${shift}+B: ${$.i18n.t('keyboard_shortcuts.beautify')}`;
      context.maximizeShortcutVerbose = `${ctrl}+${shift}+M: ${$.i18n.t('keyboard_shortcuts.maximize_editor')}`;
      context.codeLanguage = this.options.codeLanguage;
      context.showAmazonLogo = application.getHocCampaign() === 'game-dev-hoc';
      context.askingTeacher = me.isStudent() && this.teacherOnline() ? $.i18n.t('play_level.ask_teacher_for_help') : $.i18n.t('play_level.ask_teacher_for_help_offline');
      return context;
    }

    afterRender() {
      super.afterRender();
      this.attachTransitionEventListener();
      return this.$('[data-toggle="popover"]').popover();
    }

    showVideosButton() {
      return me.isStudent() && (this.courseID === utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE);
    }

    teacherOnline() {
      console.log("what online?", __guard__(this.wsBus.wsInfos != null ? this.wsBus.wsInfos.friends : undefined, x => x[this.teacherID]), this.teacherID);
      return __guard__(__guard__(__guard__(this.wsBus != null ? this.wsBus.wsInfos : undefined, x3 => x3.friends), x2 => x2[this.teacherID]), x1 => x1.online);
    }

    onDisableControls(e) { return this.toggleControls(e, false); }
    onEnableControls(e) { return this.toggleControls(e, true); }

    onClickImageGalleryButton(e) {
      return this.openModalView(new ImageGalleryModal());
    }

    onClickHintsButton() {
      let left;
      if (this.hintsState == null) { return; }
      Backbone.Mediator.publish('level:hints-button', {state: this.hintsState.get('hidden')});
      this.hintsState.set('hidden', !this.hintsState.get('hidden'));
      return (window.tracker != null ? window.tracker.trackEvent('Hints Clicked', {category: 'Students', levelSlug: this.options.level.get('slug'), hintCount: (left = __guard__(this.hintsState.get('hints'), x => x.length)) != null ? left : 0}) : undefined);
    }

    onClickVideosButton() {
      return this.openModalView(new CourseVideosModal({courseInstanceID: this.courseInstanceID, courseID: this.courseID}));
    }

    onFillSolution() {
      if (!me.canAutoFillCode()) { return; }
      return store.dispatch('game/autoFillSolution', this.options.codeLanguage);
    }

    onToggleSolution() {
      console.log('click toggle solution');
      return Backbone.Mediator.publish('level:toggle-solution', {});
    }

    onCodeReload(e) {
      if (key.shift) {
        return Backbone.Mediator.publish('level:restart', {});
      } else {
        return this.openModalView(new ReloadLevelModal());
      }
    }

    onBeautifyClick(e) {
      if (!this.controlsEnabled) { return; }
      return Backbone.Mediator.publish('tome:spell-beautify', {spell: this.spell});
    }

    onToggleMaximize(e) {
      const $codearea = $('html');
      if (!$codearea.hasClass('fullscreen-editor')) { $('#code-area').css('z-index', 20); }
      $('html').toggleClass('fullscreen-editor');
      $('.fullscreen-code').toggleClass('maximized');
      return Backbone.Mediator.publish('tome:maximize-toggled', {});
    }

    updateReloadButton() {
      const changed = this.spell.hasChanged(null, this.spell.getSource());
      return this.$el.find('.reload-code').css('display', changed ? 'inline-block' : 'none');
    }

    onSpellLoaded(e) {
      if (e.spell !== this.spell) { return; }
      return this.updateReloadButton();
    }

    onSpellChanged(e) {
      if (e.spell !== this.spell) { return; }
      return this.updateReloadButton();
    }

    onSpellChangedLanguage(e) {
      if (e.spell !== this.spell) { return; }
      this.options.codeLanguage = e.language;
      this.render();
      return this.updateReloadButton();
    }

    onUserOnlineChanged(e) {
      console.log('user online changed', e);
      if (e.user.toString() === (this.teacherID != null ? this.teacherID.toString() : undefined)) {
        return this.renderSelectors('#ask-teacher-for-help');
      }
    }

    toggleControls(e, enabled) {
      if (e.controls && !(Array.from(e.controls).includes('editor'))) { return; }
      if (enabled === this.controlsEnabled) { return; }
      this.controlsEnabled = enabled;
      return this.$el.toggleClass('read-only', !enabled);
    }

    attachTransitionEventListener() {
      let transitionListener = '';
      const testEl = document.createElement('fakeelement');
      const transitions = {
        'transition':'transitionend',
        'OTransition':'oTransitionEnd',
        'MozTransition':'transitionend',
        'WebkitTransition':'webkitTransitionEnd'
      };
      for (var transition in transitions) {
        var transitionEvent = transitions[transition];
        if (testEl.style[transition] !== undefined) {
          transitionListener = transitionEvent;
          break;
        }
      }
      const $codearea = $('#code-area');
      return $codearea.on(transitionListener, () => {
        if (!$('html').hasClass('fullscreen-editor')) { return $codearea.css('z-index', 2); }
      });
    }

    otherTeam() {
      const teams = _.without(['humans', 'ogres'], this.options.spell.team);
      return teams[0];
    }

    onSwitchTeam() {
      const protocol = window.location.protocol + "//";
      const {
        host
      } = window.location;
      const {
        pathname
      } = window.location;
      let query = window.location.search;
      query = query.replace(/team=[^&]*&?/, '');
      if (query) {
        if (query.endsWith('?') || query.endsWith('&')) {
          query += 'team=';
        } else {
          query += '&team=';
        }
      } else {
        query = '?team=';
      }
      return window.location.href = protocol+host+pathname+query + this.otherTeam();
    }

    onToggleBlocks() {
      this.blocks = !this.blocks;
      return Backbone.Mediator.publish('tome:toggle-blocks', { blocks: this.blocks });
    }

    onClickHelpButton() {
      return Backbone.Mediator.publish('websocket:asking-help', {
        msg: {
          to: this.teacherID.toString(),
          type: 'msg',
          info: {
            text: $.i18n.t('teacher.student_ask_for_help', {name: me.broadName()}),
            url: window.location.pathname
          }
        }
      });
    }

    destroy() {
      return super.destroy();
    }
  };
  SpellTopBarView.initClass();
  return SpellTopBarView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}