// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let HomeView;
require('app/styles/home-view.scss');
const RootView = require('views/core/RootView');
const template = require('templates/home-view');
const CocoCollection = require('collections/CocoCollection');
const CreateAccountModal = require('views/core/CreateAccountModal/CreateAccountModal');

const utils = require('core/utils');
const storage = require('core/storage');
const {logoutUser, me} = require('core/auth');
const fetchJson = require('core/api/fetch-json');
const DOMPurify = require('dompurify');

module.exports = (HomeView = (function() {
  HomeView = class HomeView extends RootView {
    static initClass() {
      this.prototype.id = 'home-view';
      this.prototype.template = template;
  
      this.prototype.events = {
        'click .student-btn': 'onClickStudentButton',
        'click .teacher-btn': 'onClickTeacherButton',
        'click .request-quote': 'onClickRequestQuote',
        'click .logout-btn': 'logoutAccount',
        'click .setup-class-btn': 'onClickSetupClass',
        'click .try-chapter-1': 'onClickGenericTryChapter1',
        'click .contact-us': 'onClickContactModal',
        'click a': 'onClickAnchor'
      };
    }

    initialize(options) {
      super.initialize(options);
      return this.getBanner();
    }

    getRenderData(context) {
      if (context == null) { context = {}; }
      context = super.getRenderData(context);
      context.maintenanceStartTime = moment('2022-05-07T16:00:00-07:00');
      context.i18nData = {
        pd: `<a href='/professional-development'>${$.i18n.t('nav.professional_development')}</a>`,
        maintenanceStartTime: `${context.maintenanceStartTime.calendar()} (${context.maintenanceStartTime.fromNow()})`,
        interpolation: { escapeValue: false },
        topBannerHereLink: `<a href='https://codecombat.com/teachers/hour-of-code' target='_blank'>${$.i18n.t('new_home.top_banner_blurb_hoc_2022_12_01_here')}</a>`
      };
      return context;
    }

    getMeta() {
      return {
        title: $.i18n.t('new_home.title_ozar'),
        meta: [
            { vmid: 'meta-description', name: 'description', content: $.i18n.t('new_home.meta_description_ozar') },
            { vmid: 'viewport', name: 'viewport', content: 'width=device-width, initial-scale=1' }
        ],
        link: [
          { vmid: 'rel-canonical', rel: 'canonical', href: '/'  }
        ]
      };
    }

    getBanner() {
      return fetchJson('/db/banner').then(data => {
        this.banner = data;
        const content = utils.i18n(data, 'content');
        this.banner.display = DOMPurify.sanitize(marked(content != null ? content : ''));
        return this.renderSelectors('#top-banner');
      });
    }

    onClickRequestQuote(e) {
      this.playSound('menu-button-click');
      e.preventDefault();
      e.stopImmediatePropagation();
      this.homePageEvent($(e.target).data('event-action'));
      if (me.isTeacher()) {
        return application.router.navigate('/teachers/update-account', {trigger: true});
      } else {
        return application.router.navigate('/teachers/quote', {trigger: true});
      }
    }

    onClickSetupClass(e) {
      this.homePageEvent($(e.target).data('event-action'));
      return application.router.navigate("/teachers/classes", { trigger: true });
    }

    onClickGenericTryChapter1(e) {
      this.homePageEvent($(e.target).data('event-action'));
      return window.open('/hoc', '_blank');
    }

    onClickStudentButton(e) {
      this.homePageEvent('Started Signup');
      return this.openModalView(new CreateAccountModal({startOnPath: 'student'}));
    }

    onClickTeacherButton(e) {
      this.homePageEvent('Started Signup');
      return this.openModalView(new CreateAccountModal({startOnPath: 'teacher'}));
    }

    // Provides a uniform interface for collecting information from the homepage.
    // Always provides the category Homepage and includes the user role.
    homePageEvent(action, extraproperties) {
      if (extraproperties == null) { extraproperties = {}; }
      action = action || 'unknown';
      const defaults = {
        category: 'Home',
        user: me.get('role') || (me.isAnonymous() && "anonymous") || "homeuser"
      };
      const properties = _.merge(defaults, extraproperties);
      return (window.tracker != null ? window.tracker.trackEvent(action, properties) : undefined);
    }

    onClickAnchor(e) {
      let anchor;
      if (!(anchor = e != null ? e.currentTarget : undefined)) { return; }
      let anchorEventAction = $(anchor).data('event-action');
      if (!anchorEventAction) {
        // Track an event with action of the English version of the link text
        let translationKey = $(anchor).data('i18n');
        if (translationKey == null) { translationKey = $(anchor).children('[data-i18n]').data('i18n'); }
        anchorEventAction = translationKey ? $.i18n.t(translationKey, {lng: 'en-US'}) : anchor.text;
        anchorEventAction = `Click: ${anchorEventAction || 'unknown'}`;
      }

      if (anchorEventAction) {
        return this.homePageEvent(anchorEventAction);
      } else {
        _.extend(properties || {}, {
          clicked: __guard__(e != null ? e.currentTarget : undefined, x => x.host) || "unknown"
        });
        return this.homePageEvent('Click: unknown');
      }
    }

    afterRender() {
      if (me.isAnonymous()) {
        if (document.location.hash === '#create-account') {
          this.openModalView(new CreateAccountModal());
        }
        if (document.location.hash === '#create-account-individual') {
          this.openModalView(new CreateAccountModal({startOnPath: 'individual'}));
        }
        if (document.location.hash === '#create-account-student') {
          this.openModalView(new CreateAccountModal({startOnPath: 'student'}));
        }
        if (document.location.hash === '#create-account-teacher') {
          this.openModalView(new CreateAccountModal({startOnPath: 'teacher'}));
        }
        if (document.location.hash === '#login') {
          const AuthModal = require('views/core/AuthModal');
          const url = new URLSearchParams(window.location.search);
          _.defer(() => { if (!this.destroyed) { return this.openModalView(new AuthModal({initialValues:{email: url.get('email')}})); } });
        }
      }

      window.addEventListener('load', () => __guard__($('#core-curriculum-carousel').data('bs.carousel'), x => x.$element.on('slid.bs.carousel', function(event) {
        const nextActiveSlide = $(event.relatedTarget).index();
        const $buttons = $('.control-buttons > button');
        $buttons.removeClass('active');
        return $('[data-slide-to=\'' + nextActiveSlide + '\']').addClass('active');
      })));

      return super.afterRender();
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

    onCarouselLeft() {
      return $("#core-curriculum-carousel").carousel('prev');
    }
    onCarouselRight() {
      return $("#core-curriculum-carousel").carousel('next');
    }

    onCarouselDirectMove(frameNum) {
      return $("#core-curriculum-carousel").carousel(frameNum);
    }

    logoutAccount() {
      Backbone.Mediator.publish("auth:logging-out", {});
      return logoutUser();
    }
  };
  HomeView.initClass();
  return HomeView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}