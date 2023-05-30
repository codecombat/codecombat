/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ArtisanGuideModal;
require('app/styles/editor/level/modal/artisan-guide-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/editor/level/modal/artisan-guide-modal');

const forms = require('core/forms');
const {sendContactMessage} = require('core/contact');

const contactSchema = {
  additionalProperties: false,
  required: ['creditName', 'levelPurpose', 'levelInspiration', 'levelLocation'],
  properties: {
    creditName: {
      type: 'string'
    },
    levelPurpose: {
      type: 'string'
    },
    levelInspiration: {
      type: 'string'
    },
    levelLocation: {
      type: 'string'
    }
  }
};

module.exports = (ArtisanGuideModal = (function() {
  ArtisanGuideModal = class ArtisanGuideModal extends ModalView {
    static initClass() {
      this.prototype.id = 'artisan-guide-modal';
      this.prototype.template = template;
      this.prototype.events =
        {'click #level-submit': 'levelSubmit'};
    }

    initialize(options) {
      this.level = options.level;
      return this.options = {
        level:this.level.get('name'),
        levelSlug:this.level.get('slug')
      };
    }

    levelSubmit() {
      this.playSound('menu-button-click');
      forms.clearFormAlerts(this.$el);
      const results = forms.formToObject(this.$el);
      const res = tv4.validateMultiple(results, contactSchema);
      if (!res.valid) { return forms.applyErrorsToForm(this.$el, res.errors); }
      let contactMessage = {message:`User Name: ${results.creditName}
Level: <a href="http://codecombat.com/editor/level/${this.options.levelSlug}">${this.options.level}</a>
Purpose: ${results.levelPurpose}
Inspiration: ${results.levelInspiration}
Location: ${results.levelLocation}`};
      this.populateBrowserData(contactMessage);
      contactMessage = _.merge(contactMessage, this.options);
      contactMessage.country = me.get('country');
      sendContactMessage(contactMessage, this.$el);
      return $.post(`/db/user/${me.id}/track/contact_codecombat`);
    }

    populateBrowserData(context) {
      if ($.browser) {
        context.browser = `${$.browser.platform} ${$.browser.name} ${$.browser.versionNumber}`;
      }
      context.screenSize = `${(typeof screen !== 'undefined' && screen !== null ? screen.width : undefined) != null ? (typeof screen !== 'undefined' && screen !== null ? screen.width : undefined) : $(window).width()} x ${(typeof screen !== 'undefined' && screen !== null ? screen.height : undefined) != null ? (typeof screen !== 'undefined' && screen !== null ? screen.height : undefined) : $(window).height()}`;
      return context.screenshotURL = this.screenshotURL;
    }

    hasOwnership() {
      if (this.level.getOwner() === me.id) {
        return true;
      }
      return false;
    }
  };
  ArtisanGuideModal.initClass();
  return ArtisanGuideModal;
})());
