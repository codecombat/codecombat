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
require('app/styles/home-view.sass');
require('app/styles/home-view.scss');
const RootView = require('views/core/RootView');
const cocoTemplate = require('templates/coco-home-view');
const ozarTemplate = require('templates/ozar-home-view');
const CocoCollection = require('collections/CocoCollection');
const utils = require('core/utils');
let storage = require('core/storage');
const {logoutUser, me} = require('core/auth');
const CreateAccountModal = require('views/core/CreateAccountModal/CreateAccountModal');
const GetStartedSignupModal  = require('app/views/teachers/GetStartedSignupModal').default;
const paymentUtils = require('app/lib/paymentUtils');
const fetchJson = require('core/api/fetch-json');
const DOMPurify = require('dompurify');
const MineModal = require('views/core/MineModal'); // Roblox modal
storage = require('core/storage');


const PRODUCT_SUFFIX = utils.isCodeCombat ? 'coco' : 'ozar';
module.exports = (HomeView = (function() {
  HomeView = class HomeView extends RootView {
    constructor(...args) {
      super(...args);
      this.onCarouselSlide = this.onCarouselSlide.bind(this);
      this.activateCarousels = this.activateCarousels.bind(this);
      this.renderedPaymentNoty = false;
      this.getBanner();
    }

    static initClass() {
      this.prototype.id = 'home-view';
      this.prototype.template = utils.isCodeCombat ? cocoTemplate : ozarTemplate;

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
        'click .carousel-tab': 'onCarouselDirectMovev2',
        'click .request-quote': 'onClickRequestQuote',
        'click .logout-btn': 'logoutAccount',
        'click .setup-class-btn': 'onClickSetupClass',
        'click .try-chapter-1': 'onClickGenericTryChapter1',
        'click .contact-us': 'onClickContactModal'
      };
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
        codecombatHome: `<a href='/premium' target='_blank'>${$.i18n.t('new_home.codecombat_home')}</a>`,
        pd: `<a href='/professional-development'>${$.i18n.t('nav.professional_development')}</a>`,
        maintenanceStartTime: `${context.maintenanceStartTime.calendar()} (${context.maintenanceStartTime.fromNow()})`,
        interpolation: { escapeValue: false },
        topBannerHereLink: `<a href='https://codecombat.com/teachers/hour-of-code' target='_blank'>${$.i18n.t('new_home.top_banner_blurb_hoc_2022_12_01_here')}</a>`,
        deipage: `<a href='/diversity-equity-and-inclusion' target='_blank'>${$.i18n.t('ozaria_home.dei_page')}</a>`,
        efficacypage: `<a href='/efficacy' target='_blank'>${$.i18n.t('ozaria_home.efficacy_page')}</a>`,
        selpage: `<a href='/social-and-emotional-learning' target='_blank'>${$.i18n.t('ozaria_home.sel_page')}</a>`
      };

      return context;
    }

    getMeta() {
      return {
        title: $.i18n.t('new_home.title_' + PRODUCT_SUFFIX),
        meta: [
            { vmid: 'meta-description', name: 'description', content: $.i18n.t('new_home.meta_description_' + PRODUCT_SUFFIX) },
            { vmid: 'viewport', name: 'viewport', content: 'width=device-width, initial-scale=1' }
        ],
        link: [
          { vmid: 'rel-canonical', rel: 'canonical', href: '/'  }
        ]
      };
    }

    getBanner() {
      return fetchJson('/db/banner').then(data => {
        if (!data) { return }
        this.banner = data
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
      this.homePageEvent($(e.target).data('event-action'));
      return this.openModalView(new CreateAccountModal({startOnPath: 'student'}));
    }

    onClickTeacherButton(e) {
      if (utils.isCodeCombat) {
        this.homePageEvent($(e.target).data('event-action'));
        return this.openModalView(new CreateAccountModal({startOnPath: 'oz-vs-coco'}));
      } else {
        this.homePageEvent('Started Signup');
        return this.openModalView(new CreateAccountModal({startOnPath: 'teacher'}));
      }
    }

    onClickParentButton(e) {
      this.homePageEvent($(e.target).data('event-action'));
      return application.router.navigate('/parents/signup', {trigger: true});
    }

    onClickCreateAccountTeacherButton(e) {
      this.homePageEvent('Started Signup');
      return this.openModalView(new CreateAccountModal({startOnPath: 'teacher'}));
    }

    cleanupModals() {
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
      action = action || 'unknown';
      const defaults = {
        category: utils.isCodeCombat ? 'Homepage' : 'Home',
        user: me.get('role') || (me.isAnonymous() && "anonymous") || "homeuser"
      };
      const properties = _.merge(defaults, extraProperties);
      return (window.tracker != null ? window.tracker.trackEvent(action, properties) : undefined);
    }

    onClickAnchor(e) {
      let anchor, properties, translationKey;
      if (!(anchor = e != null ? e.currentTarget : undefined)) { return; }
      if (utils.isCodeCombat) {
        // Track an event with action of the English version of the link text
        let anchorText;
        translationKey = $(anchor).attr('data-i18n');
        if (translationKey == null) { translationKey = $(anchor).children('[data-i18n]').attr('data-i18n'); }
        if (translationKey) {
          anchorText = $.i18n.t(translationKey, {lng: 'en-US'});
        } else {
          anchorText = anchor.text;
        }

        properties = {};
        if (anchorText) {
          return this.homePageEvent(`Link: ${anchorText}`, properties);
        } else {
          properties.clicked = __guard__(e != null ? e.currentTarget : undefined, x => x.host) || "unknown";
          return this.homePageEvent("Link:", properties);
        }
      } else {
        let anchorEventAction = $(anchor).data('event-action');
        if (!anchorEventAction) {
          // Track an event with action of the English version of the link text
          translationKey = $(anchor).data('i18n');
          if (translationKey == null) { translationKey = $(anchor).children('[data-i18n]').data('i18n'); }
          anchorEventAction = translationKey ? $.i18n.t(translationKey, {lng: 'en-US'}) : anchor.text;
          anchorEventAction = `Click: ${anchorEventAction || 'unknown'}`;
        }

        if (anchorEventAction) {
          return this.homePageEvent(anchorEventAction);
        } else {
          _.extend(properties || {}, {
            clicked: __guard__(e != null ? e.currentTarget : undefined, x1 => x1.host) || "unknown"
          });
          return this.homePageEvent('Click: unknown');
        }
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
      if (utils.isCodeCombat) {
        const selector = $(e.target).closest('.carousel-dot').data('selector');
        const slideNum = $(e.target).closest('.carousel-dot').data('slide-num');
        return this.$(selector).carousel(slideNum);
      } else {
        const frameNum = e;
        return $("#core-curriculum-carousel").carousel(frameNum);
      }
    }

    onCarouselLeft() {
      return $("#core-curriculum-carousel").carousel('prev');
    }
    onCarouselRight() {
      return $("#core-curriculum-carousel").carousel('next');
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

      _.defer(() => { if (!storage.load('roblox-clicked') && !this.destroyed) { return this.openModalView(new MineModal()); } });

      if (utils.isCodeCombat) {
        let needle, needle1, paymentResult, title, type;
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
      } else {
        window.addEventListener('load', () => __guard__($('#core-curriculum-carousel').data('bs.carousel'), x => x.$element.on('slid.bs.carousel', function(event) {
          const nextActiveSlide = $(event.relatedTarget).index();
          const $buttons = $('.control-buttons > button');
          $buttons.removeClass('active');
          return $('[data-slide-to=\'' + nextActiveSlide + '\']').addClass('active');
        })));
      }
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

    logoutAccount() {
      Backbone.Mediator.publish("auth:logging-out", {});
      return logoutUser();
    }

    destroy() {
      this.cleanupModals();
      return super.destroy();
    }
  };
  HomeView.initClass();
  return HomeView;
})());

  // 2021-06-08: currently causing issues with i18n interpolation, disabling for now
  // TODO: understand cause, performance impact
  //mergeWithPrerendered: (el) ->
  //  true

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}