// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ModalView;
const CocoView = require('./CocoView');
const focusTrap = require('focus-trap');

module.exports = (ModalView = (function() {
  ModalView = class ModalView extends CocoView {
    static initClass() {
      this.prototype.className = 'modal fade';
      this.prototype.closeButton = true;
      this.prototype.closesOnClickOutside = true;
      this.prototype.modalWidthPercent = null;
      this.prototype.plain = false;
      this.prototype.instant = false;
      this.prototype.template = require('app/templates/core/modal-base');
      this.prototype.trapsFocus = true;

      this.prototype.events = {
        'click a': 'toggleModal',
        'click button': 'toggleModal',
        'click li': 'toggleModal',
        'click [data-i18n]': 'onClickTranslatedElement'
      };

      this.prototype.shortcuts =
        {'esc': 'onEsc'};

      this.prototype.subscriptions =
        {};
    }

    constructor(options) {
      super(...arguments)
      if ((options != null ? options.instant : undefined) || this.instant) { this.className = this.className.replace(' fade', ''); }
      if ((options != null ? options.closeButton : undefined) != null) { this.closeButton = options.closeButton; }
      if (options != null ? options.modalWidthPercent : undefined) { this.modalWidthPercent = options.modalWidthPercent; }
      if (this.options == null) { this.options = {}; }
      if ((options != null ? options.trapsFocus : undefined) != null) { this.trapsFocus = options.trapsFocus; }
    }

    render() {
      __guardMethod__(this.focusTrap, 'deactivate', o => o.deactivate());
      super.render();
      return this.trapFocus();
    }

    afterRender() {
      super.afterRender();
      if (this.modalWidthPercent) {
        this.$el.find('.modal-dialog').css({width: `${this.modalWidthPercent}%`});
      }
      this.$el.on('hide.bs.modal', () => {
        if (!this.hidden) { this.onHidden(); }
        return this.hidden = true;
      });
      if (this.plain) { return this.$el.find('.background-wrapper').addClass('plain'); }
    }

    afterInsert() {
      super.afterInsert();
      // This makes sure if you press enter right after opening the players guide,
      // it doesn't just reopen the modal.
      $(document.activeElement).blur();

      if (typeof localStorage !== 'undefined' && localStorage !== null ? localStorage.showViewNames : undefined) {
        const title = this.constructor != null ? this.constructor.name : undefined;
        return setTimeout(function() {
          if (!this.destroyed) { return $('title').text(title); }
        }
        , 500);
      }
    }

    trapFocus() {
      if (!this.trapsFocus) { return; }
      console.log(this.constructor != null ? this.constructor.name : undefined, 'trapping focus within modal');
      if (this.focusTrap == null) { this.focusTrap = focusTrap.createFocusTrap(this.el); }
      try {
        return (this.focusTrap != null ? this.focusTrap.activate() : undefined);
      } catch (e) {
        return console.log(this.constructor != null ? this.constructor.name : undefined, 'not trapping focus for modal with no focusable elements');
      }
    }

    showLoading($el) {
      if (!$el) { $el = this.$el.find('.modal-body'); }
      return super.showLoading($el);
    }

    onEsc() {
      if (__guard__(__guard__(this.$el.data('bs.modal'), x1 => x1.options), x => x.keyboard)) {
        return this.hide();
      }
    }

    // TODO: Combine hide/onHidden such that backbone 'hide/hidden.bs.modal' events and our 'hide/hidden' events are more 1-to-1
    // For example:
    //   pressing 'esc' or using `currentModal.hide()` triggers 'hide', 'hide.bs.modal', 'hidden', 'hidden.bs.modal'
    //   clicking outside the modal triggers 'hide.bs.modal', 'hidden', 'hidden.bs.modal' (but not 'hide')
    hide() {
      this.trigger('hide');
      if (!this.destroyed) { this.$el.removeClass('fade').modal('hide'); }
      return __guardMethod__(this.focusTrap, 'deactivate', o => o.deactivate());
    }

    onHidden() {
      return this.trigger('hidden');
    }

    destroy() {
      if (!this.hidden) { this.hide(); }
      if (this.$el) { this.$el.off('hide.bs.modal'); }
      __guardMethod__(this.focusTrap, 'deactivate', o => o.deactivate());
      return super.destroy();
    }
  };
  ModalView.initClass();
  return ModalView;
})());

function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName);
  } else {
    return undefined;
  }
}
function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}