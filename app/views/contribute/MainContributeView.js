/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let MainContributeView;
require('app/styles/contribute/contribute.sass');
const ContributeClassView = require('views/contribute/ContributeClassView');
const template = require('app/templates/contribute/contribute');
const utils = require('core/utils');

module.exports = (MainContributeView = (function() {
  MainContributeView = class MainContributeView extends ContributeClassView {
    static initClass() {
      this.prototype.id = 'contribute-view';
      this.prototype.template = template;
  
      this.prototype.events =
        {'change input[type="checkbox"]': 'onCheckboxChanged'};
    }

    initialize() {
      super.initialize();
      this.apiLink = this.getApiLink();
      this.communityLink = this.getCommunityLink();
      return this.forumLink = this.getForumLink();
    }

    getLanguage() {
      return (me.get('preferredLanguage') || 'en').split('-')[0];
    }

    getApiLink() {
      let link = 'https://github.com/codecombat/codecombat-api';
      if (['zh'].includes(this.getLanguage()) || features.china) {
        link = utils.cocoBaseURL() + '/api-docs';
      }
      return link;
    }

    getCommunityLink() {
      return utils.cocoBaseURL() + '/community';
    }

    getForumLink() {
      let link = 'https://discourse.codecombat.com/';
      if (['zh', 'ru', 'es', 'fr', 'pt', 'de', 'nl', 'lt'].includes(this.getLanguage())) {
        link += `c/other-languages/${this.getLanguage()}`;
      }
      return link;
    }
  };
  MainContributeView.initClass();
  return MainContributeView;
})());


