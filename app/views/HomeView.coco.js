// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let HomeView;
import 'app/styles/home-view.sass';
import RootView from 'views/core/RootView';
import template from 'templates/home-view';
import CocoCollection from 'collections/CocoCollection';
import utils from 'core/utils';
import storage from 'core/storage';
import { logoutUser, me } from 'core/auth';
import CreateAccountModal from 'views/core/CreateAccountModal/CreateAccountModal';
import GetStartedSignupModal from 'app/views/teachers/GetStartedSignupModal';
import paymentUtils from 'app/lib/paymentUtils';
import fetchJson from 'core/api/fetch-json';
import DOMPurify from 'dompurify';

export default HomeView = (function() {
  HomeView = class HomeView extends RootView {
    constructor(...args) {
      this.onCarouselSlide = this.onCarouselSlide.bind(this);
      this.activateCarousels = this.activateCarousels.bind(this);
      super(...args);
    }

    static initClass() {
      this.prototype.id = 'home-view';
      this.prototype.template = template;
  
      this.prototype.events = {
        'click .continue-playing-btn': 'onClickTrackEvent',
        'click .student-btn': 'onClickStudentButton',
        'click .teacher-btn': 'onClickTeacherButton',
        'click .parent-btn': 'onClickParentButton',
        'click .my-classes-btn': 'onClickTrackEvent',
        'click .my-courses-btn': 'onClickTrackEvent',
        'click .try-ozaria': 'onClickTrackEvent',
        'click .product-btn a': 'onClickTrackEvent',
        'click .product-btn button': 'onClickTrackEvent',
        'click a': 'onClickAnchor',
        'click .get-started-btn': 'onClickGetStartedButton',
        'click .create-account-teacher-btn': 'onClickCreateAccountTeacherButton',
        'click .carousel-dot': 'onCarouselDirectMove',
        'click .carousel-tab': 'onCarouselDirectMovev2'
      };
    }

    initialize(options) {
      super.initialize(options);
      this.renderedPaymentNoty = false;
      return this.getBanner();
    }

    getRenderData(context) {
      if (context == null) { context = {}; }
      context = super.getRenderData(context);
      context.maintenanceStartTime = moment('2022-05-07T16:00:00-07:00');
      context.i18nData = {
        slides: `<a href='https://docs.google.com/presentation/d/1KgFOg2tqbKEH8qNwIBdmK2QbHvTsxnW_Xo7LvjPsxwE/edit?usp=sharing' target='_blank'>${$.i18n.t('new_home.lesson_slides')}</a>`,
        clever: `<a href='/teachers/resources/clever-faq'>${$.i18n.t('new_home_faq.clever_integration_faq')}</a>`,
        contact: me.isTeacher() ? `<a class='contact-modal'>${$.i18n.t('general.contact_us')}</a>` : `<a href=\"mailto:support@codecombat.com\">${$.i18n.t('general.contact_us')}</a>`,
        funding: `<a href='https://www.ozaria.com/funding' target='_blank'>${$.i18n.t('nav.funding_resources_guide')}</a>`,
        maintenanceStartTime: `${context.maintenanceStartTime.calendar()} (${context.maintenanceStartTime.fromNow()})`,
        interpolation: { escapeValue: false },
        topBannerHereLink: `<a href='/teachers/hour-of-code' target='_blank'>${$.i18n.t('new_home.top_banner_blurb_hoc_2022_12_01_here')}</a>`
      };
      return context;
    }

    getMeta() {
      return {
        title: $.i18n.t('new_home.title_coco'),
        meta: [
            { vmid: 'meta-description', name: 'description', content: $.i18n.t('new_home.meta_description_coco') }
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

    onClickStudentButton(e) {
      this.homePageEvent('Started Signup');
      this.homePageEvent($(e.target).data('event-action'));
      return this.openModalView(new CreateAccountModal({startOnPath: 'student'}));
    }

    onClickTeacherButton(e) {
      this.homePageEvent($(e.target).data('event-action'));
      return this.openModalView(new CreateAccountModal({startOnPath: 'oz-vs-coco'}));
    }

    onClickParentButton(e) {
      this.homePageEvent($(e.target).data('event-action'));
      return application.router.navigate('/parents', {trigger: true});
    }

    onClickCreateAccountTeacherButton(e) {
      this.homePageEvent('Started Signup');
      return this.openModalView(new CreateAccountModal({startOnPath: 'teacher'}));
    }

    cleanupModals() {
      if (this.ozariaEncouragementModal) {
        this.ozariaEncouragementModal.$destroy();
        this.ozariaEncouragementModalContainer.remove();
      }
      if (this.getStartedSignupContainer) {
        this.getStartedSignupContainer.$destroy();
        return this.getStartedSignupModal.remove();
      }
    }

    onClickTrackEvent(e) {
      return this.homePageEvent($(e.target).data('event-action'), {});
    }

    // Provides a uniform interface for collecting information from the homepage.
    // Always provides the category Homepage and includes the user role.
    homePageEvent(action, extraProperties) {
      if (extraProperties == null) { extraProperties = {}; }
      const defaults = {
        category: 'Homepage',
        user: me.get('role') || (me.isAnonymous() && "anonymous") || "homeuser"
      };
      const properties = _.merge(defaults, extraProperties);
      return (window.tracker != null ? window.tracker.trackEvent(action, properties) : undefined);
    }

    onClickAnchor(e) {
      let anchor, anchorText;
      if (!(anchor = e != null ? e.currentTarget : undefined)) { return; }
      // Track an event with action of the English version of the link text
      let translationKey = $(anchor).attr('data-i18n');
      if (translationKey == null) { translationKey = $(anchor).children('[data-i18n]').attr('data-i18n'); }
      if (translationKey) {
        anchorText = $.i18n.t(translationKey, {lng: 'en-US'});
      } else {
        anchorText = anchor.text;
      }

      const properties = {};
      if (anchorText) {
        return this.homePageEvent(`Link: ${anchorText}`, properties);
      } else {
        properties.clicked = __guard__(e != null ? e.currentTarget : undefined, x => x.host) || "unknown";
        return this.homePageEvent("Link:", properties);
      }
    }

    onClickGetStartedButton(e) {
      this.homePageEvent($(e.target).data('event-action'));
      if (this.getStartedSignupContainer != null) {
        this.getStartedSignupContainer.remove();
      }
      this.getStartedSignupContainer = document.createElement('div');
      document.body.appendChild(this.getStartedSignupContainer);
      return this.getStartedSignupModal = new GetStartedSignupModal({ el: this.getStartedSignupContainer });
    }

    onCarouselDirectMovev2(e) {
      const selector = $(e.target).closest('.carousel-tab').data('selector');
      const slideNum = $(e.target).closest('.carousel-tab').data('slide-num');
      return this.$(selector).carousel(slideNum);
    }

    onCarouselDirectMove(e) {
      const selector = $(e.target).closest('.carousel-dot').data('selector');
      const slideNum = $(e.target).closest('.carousel-dot').data('slide-num');
      return this.$(selector).carousel(slideNum);
    }

    onCarouselSlide(e) {
      const $carousel = $(e.currentTarget).closest('.carousel');
      const $carouselContainer = this.$(`#${$carousel.attr('id')}-carousel`);
      const slideNum = parseInt($(e.relatedTarget).data('slide'), 10);
      $carouselContainer.find(`.carousel-tabs li:not(:nth-child(${slideNum + 1}))`).removeClass('active');
      $carouselContainer.find(`.carousel-tabs li:nth-child(${slideNum + 1})`).addClass('active');
      $carouselContainer.find(`.carousel-dot:not(:nth-child(${slideNum + 1}))`).removeClass('active');
      return $carouselContainer.find(`.carousel-dot:nth-child(${slideNum + 1})`).addClass('active');
    }

    activateCarousels() {
      if (this.destroyed) { return; }
      return this.$('.carousel').carousel().off().on('slide.bs.carousel', this.onCarouselSlide);
    }

    afterRender() {
      let needle, needle1, paymentResult, title, type;
      if (me.isAnonymous()) {
        if ((document.location.hash === '#create-account') || (utils.getQueryVariable('registering') === true)) {
          _.defer(() => { if (!this.destroyed) { return this.openModalView(new CreateAccountModal()); } });
        }
        if (document.location.hash === '#create-account-individual') {
          _.defer(() => { if (!this.destroyed) { return this.openModalView(new CreateAccountModal({startOnPath: 'individual'})); } });
        }
        if (document.location.hash === '#create-account-home') {
          _.defer(() => { if (!this.destroyed) { return this.openModalView(new CreateAccountModal({startOnPath: 'individual-basic'})); } });
        }
        if (document.location.hash === '#create-account-student') {
          _.defer(() => { if (!this.destroyed) { return this.openModalView(new CreateAccountModal({startOnPath: 'student'})); } });
        }
        if (document.location.hash === '#create-account-teacher') {
          _.defer(() => { if (!this.destroyed) { return this.openModalView(new CreateAccountModal({startOnPath: 'teacher'})); } });
        }
        if (utils.getQueryVariable('create-account') === 'teacher') {
          _.defer(() => { if (!this.destroyed) { return this.openModalView(new CreateAccountModal({startOnPath: 'teacher'})); } });
        }
        if (document.location.hash === '#login') {
          const AuthModal = require('app/views/core/AuthModal');
          const url = new URLSearchParams(window.location.search);
          _.defer(() => { if (!this.destroyed) { return this.openModalView(new AuthModal({initialValues:{email: url.get('email')}})); } });
        }
      }

      if ((needle = utils.getQueryVariable('payment-studentLicenses'), ['success', 'failed'].includes(needle)) && !this.renderedPaymentNoty) {
        paymentResult = utils.getQueryVariable('payment-studentLicenses');
        if (paymentResult === 'success') {
          title = $.i18n.t('payments.studentLicense_successful');
          type = 'success';
          if (utils.getQueryVariable('tecmilenio')) {
            title = '¡Felicidades! El alumno recibirá más información de su profesor para acceder a la licencia de CodeCombat.';
          }
          this.trackPurchase(`Student license purchase ${type}`);
        } else {
          title = $.i18n.t('payments.failed');
          type = 'error';
        }
        noty({ text: title, type, timeout: 10000, killer: true });
        this.renderedPaymentNoty = true;
      } else if ((needle1 = utils.getQueryVariable('payment-homeSubscriptions'), ['success', 'failed'].includes(needle1)) && !this.renderedPaymentNoty) {
        paymentResult = utils.getQueryVariable('payment-homeSubscriptions');
        if (paymentResult === 'success') {
          title = $.i18n.t('payments.homeSubscriptions_successful');
          type = 'success';
          this.trackPurchase(`Home subscription purchase ${type}`);
        } else {
          title = $.i18n.t('payments.failed');
          type = 'error';
        }
        noty({ text: title, type, timeout: 10000, killer: true });
        this.renderedPaymentNoty = true;
      }
      _.delay(this.activateCarousels, 1000);
      return super.afterRender();
    }

    trackPurchase(event) {
      if (!paymentUtils.hasTrackedPremiumAccess()) {
        this.homePageEvent(event, this.getPaymentTrackingData());
        return paymentUtils.setTrackedPremiumPurchase();
      }
    }

    getPaymentTrackingData() {
      const amount = utils.getQueryVariable('amount');
      const duration = utils.getQueryVariable('duration');
      return paymentUtils.getTrackingData({ amount, duration });
    }

    afterInsert() {
      super.afterInsert();
      // scroll to the current hash, once everything in the browser is set up
      const f = () => {
        if (this.destroyed) { return; }
        try {
          const link = $(document.location.hash);
          if (link.length) {
            return this.scrollToLink(document.location.hash, 0);
          }
        } catch (e) {
          return console.warn(e);  // Possibly a hash that would not match a valid element
        }
      };
      return _.delay(f, 100);
    }

    destroy() {
      this.cleanupModals();
      return super.destroy();
    }
  };
  HomeView.initClass();
  return HomeView;
})();

// 2021-06-08: currently causing issues with i18n interpolation, disabling for now
// TODO: understand cause, performance impact
//mergeWithPrerendered: (el) ->
//  true

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}