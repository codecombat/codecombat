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
let SpellTranslationView;
const CocoView = require('views/core/CocoView');
const LevelComponent = require('models/LevelComponent');
const template = require('app/templates/play/level/tome/spell_translation');
const ace = require('lib/aceContainer');
const {
  Range
} = ace.require('ace/range');
const {
  TokenIterator
} = ace.require('ace/token_iterator');
const utils = require('core/utils');

module.exports = (SpellTranslationView = (function() {
  SpellTranslationView = class SpellTranslationView extends CocoView {
    static initClass() {
      this.prototype.className = 'spell-translation-view';
      this.prototype.template = template;

      this.prototype.events = {
        'mousemove'() {
          return this.$el.hide();
        }
      };

      this.prototype.subscriptions =
        {'tome:completer-popup-focus-change': 'onPopupFocusChange'};
    }

    constructor(options) {
      super(options);
      this.setTooltipText = this.setTooltipText.bind(this);
      this.onMouseMove = this.onMouseMove.bind(this);
      this.onPopupFocusChange = this.onPopupFocusChange.bind(this);
      this.ace = options.ace;

      const levelComponents = this.supermodel.getModels(LevelComponent);
      this.componentTranslations = levelComponents.reduce(function(acc, lc) {
        let left;
        for (var doc of Array.from(((left = lc.get('propertyDocumentation')) != null ? left : []))) {
          var translated = utils.i18n(doc, 'name', null, false);
          if (translated !== doc.name) { acc[doc.name] = translated; }
        }
        return acc;
      }
      , {});

      this.onMouseMove = _.throttle(this.onMouseMove, 25);
    }

    afterRender() {
      super.afterRender();
      if (this.ace != null) {
        return this.ace.on('mousemove', this.onMouseMove);
      }
    }

    setTooltipText(text) {
      this.$el.find('code').text(text);
      return this.$el.show().css(this.pos);
    }

    isIdentifier(t) {
      return t && (_.any([/identifier/, /keyword/], regex => regex.test(t.type)) || (t.value === 'this'));
    }

    onMouseMove(e) {
      let start, token;
      if (this.destroyed) { return; }
      const pos = e.getDocumentPosition();
      const it = new TokenIterator(e.editor.session, pos.row, pos.column);
      const endOfLine = __guard__(it.getCurrentToken(), x => x.index) === (it.$rowTokens.length - 1);
      while ((it.getCurrentTokenRow() === pos.row) && !this.isIdentifier(token = it.getCurrentToken())) {
        if (endOfLine || !token) { break; }  // Don't iterate beyond end or beginning of line
        it.stepBackward();
      }
      if (!this.isIdentifier(token)) {
        this.word = null;
        this.update();
        return;
      }
      try {
        // Ace was breaking under some (?) conditions, dependent on mouse location.
        //   with $rowTokens = [] (but should have things)
        start = it.getCurrentTokenColumn();
      } catch (error) {
        start = 0;
      }
      const end = start + token.value.length;
      if (this.isIdentifier(token)) {
        this.word = token.value;
        this.markerRange = new Range(pos.row, start, pos.row, end);
        this.reposition(e.domEvent);
      }
      return this.update();
    }

    onPopupFocusChange({word, markerRang}) {
      this.word = word;
      this.markerRang = markerRang;
      if (this.destroyed) { return; }
      return this.update();
    }

    reposition(e) {
      let offsetX = e.offsetX != null ? e.offsetX : e.clientX - $(e.target).offset().left;
      const offsetY = e.offsetY != null ? e.offsetY : e.clientY - $(e.target).offset().top;
      const w = $(document).width() - 20;
      if ((e.clientX + this.$el.width()) > w) { offsetX = w - $(e.target).offset().left - this.$el.width(); }
      this.pos = {left: offsetX + 80, top: offsetY - 20};
      return this.$el.css(this.pos);
    }

    onMouseOut() {
      this.word = null;
      this.markerRange = null;
      return this.update();
    }

    update() {
      const i18nKey = 'code.'+this.word;
      const translation = this.componentTranslations[this.word] || $.t(i18nKey);
      if (this.word && translation && ![i18nKey, this.word].includes(translation)) {
        return this.setTooltipText(translation);
      } else {
        return this.$el.hide();
      }
    }

    destroy() {
      if (this.ace != null) {
        this.ace.removeEventListener('mousemove', this.onMouseMove);
      }
      return super.destroy();
    }
  };
  SpellTranslationView.initClass();
  return SpellTranslationView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}