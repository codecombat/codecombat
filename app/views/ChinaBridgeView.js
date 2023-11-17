// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ContactGEEKView;
require('app/styles/china-bridge.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/china-bridge-view');
const utils = require('core/utils');
const storage = require('core/storage');


module.exports = (ContactGEEKView = (function() {
  ContactGEEKView = class ContactGEEKView extends RootView {
    constructor(...args) {
      super(...args);
      this.goRedirect = this.goRedirect.bind(this);
    }

    static initClass() {
      this.prototype.id = 'contact-geek-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click .one': 'onClickOne',
        'click .two': 'onClickTwo'
      };
    }

    initialize(options) {
      super.initialize(options);
      this.history = this.getRedirect();
      if (this.history) {
        return setTimeout(this.goRedirect, 5000);
      }
    }

    goRedirect(value) {
      const redirectURL = utils.getQueryVariable('redirect');
      let url = (value || this.history) === 'koudashijie' ? 'https://koudashijie.com' : 'https://codecombat.163.com';
      if (redirectURL) {
        url += redirectURL;
      }
      return window.location.href = url;
    }

    setRedirect(redirect) { return storage.save('redirect', redirect); }
    getRedirect() { return storage.load('redirect'); }

    onClickOne(e) {
      this.setRedirect("koudashijie");
      return this.goRedirect("koudashijie");
    }

    onClickTwo(e) {
      this.setRedirect("netease");
      return this.goRedirect("netease");
    }
  };
  ContactGEEKView.initClass();
  return ContactGEEKView;
})());
