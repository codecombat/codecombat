// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AboutView;
require('app/styles/about.sass');
const RootView = require('views/core/RootView');
const template = require('templates/about');
const fetchJson = require('core/api/fetch-json');

module.exports = (AboutView = (function() {
  AboutView = class AboutView extends RootView {
    static initClass() {
      this.prototype.id = 'about-view';
      this.prototype.template = template;
      this.prototype.logoutRedirectURL = false;
      this.prototype.jobs = [];
  
      this.prototype.events = {
        'click #fixed-nav a': 'onClickFixedNavLink',
        'click .screen-thumbnail': 'onClickScreenThumbnail',
        'click #carousel-left': 'onLeftPressed',
        'click #carousel-right': 'onRightPressed'
      };
  
      this.prototype.shortcuts = {
        'right': 'onRightPressed',
        'left': 'onLeftPressed',
        'esc': 'onEscapePressed'
      };
    }

    getMeta() {
      return {
        title: $.i18n.t('about.title'),
        meta: [
          { vmid: 'meta-description', name: 'description', content: $.i18n.t('about.meta_description') }
        ]
      };
    }

    initialize(options) {
      super.initialize(options);
      return this.loadJobs();
    }

    loadJobs() {
      const url = 'https://api.lever.co/v0/postings/codecombat?skip=0&limit=100&mode=json';
      return fetchJson(url).then(response => {
        this.jobs = _.sortBy(response, 'createdAt').reverse();
        return this.renderSelectors('#careers');
      });
    }

    afterRender() {
      super.afterRender(...arguments);
      this.$('#fixed-nav').affix({
        offset: {
          top() {
            return $('#nav-container').offset().top;
          }
        }
      });
      //TODO: Maybe cache top value between page resizes to save CPU
      $('body').scrollspy({
        target: '#nav-container',
        offset: 150
      });
      this.$('#screenshot-lightbox').modal();

      return this.$('#screenshot-carousel').carousel({
        interval: 0,
        keyboard: false
      });
    }

    afterInsert() {
      super.afterInsert();
      // scroll to the current hash, once everything in the browser is set up
      const f = () => {
        if (this.destroyed) { return; }
        const link = $(document.location.hash);
        if (link.length) {
          return this.scrollToLink(document.location.hash, 0);
        }
      };
      return _.delay(f, 100);
    }

    onClickFixedNavLink(event) {
      event.preventDefault(); // prevent default page scroll
      const link = $(event.target).closest('a');
      const target = link.attr('href');
      history.replaceState(null, null, `about${target}`); // update hash without triggering page scroll
      return this.scrollToLink(target);
    }

    onRightPressed(event) {
      // Special handling, otherwise after you click the control, keyboard presses move the slide twice
      if ((event.type === 'keydown') && $(document.activeElement).is('.carousel-control')) { return; }
      if (__guard__($('#screenshot-lightbox').data('bs.modal'), x => x.isShown)) {
        event.preventDefault();
        return $('#screenshot-carousel').carousel('next');
      }
    }

    onLeftPressed(event) {
      if ((event.type === 'keydown') && $(document.activeElement).is('.carousel-control')) { return; }
      if (__guard__($('#screenshot-lightbox').data('bs.modal'), x => x.isShown)) {
        event.preventDefault();
        return $('#screenshot-carousel').carousel('prev');
      }
    }

    onEscapePressed(event) {
      if (__guard__($('#screenshot-lightbox').data('bs.modal'), x => x.isShown)) {
        event.preventDefault();
        return $('#screenshot-lightbox').modal('hide');
      }
    }

    onClickScreenThumbnail(event) {
      if (!__guard__($('#screenshot-lightbox').data('bs.modal'), x => x.isShown)) {
        event.preventDefault();
        // Modal opening happens automatically from bootstrap
        return $('#screenshot-carousel').carousel($(event.currentTarget).data("index"));
      }
    }
  };
  AboutView.initClass();
  return AboutView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}