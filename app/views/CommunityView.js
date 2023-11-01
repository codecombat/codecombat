// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CommunityView;
require('app/styles/community.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/community-view');

module.exports = (CommunityView = (function() {
  CommunityView = class CommunityView extends RootView {
    static initClass() {
      this.prototype.id = 'community-view';
      this.prototype.template = template;
  
      this.prototype.logoutRedirectURL = false;
    }

    afterRender() {
      super.afterRender();
      this.$el.find('.contribute-classes a').each(function() {
        const characterClass = $(this).attr('href').split('/')[2];
        const title = $.i18n.t(`classes.${characterClass}_title`);
        const titleDescription = $.i18n.t(`classes.${characterClass}_title_description`);
        const summary = $.i18n.t(`classes.${characterClass}_summary`);
        const explanation = `<h4>${title} ${titleDescription}</h4>${summary}`;
        return $(this).find('img').popover({placement: 'top', trigger: 'hover', container: 'body', content: explanation, html: true});
      });

      return this.$el.find('.logo-row img').each(function() {
        return $(this).popover({placement: 'top', trigger: 'hover', container: 'body'});
      });
    }
  };
  CommunityView.initClass();
  return CommunityView;
})());
