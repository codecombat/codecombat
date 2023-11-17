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
let HomeCNView;
require('app/styles/home-cn-view.sass');
const RootView = require('views/core/RootView');
const template = require('templates/home-cn-view');
const CocoCollection = require('collections/CocoCollection');
const TrialRequest = require('models/TrialRequest');
const TrialRequests = require('collections/TrialRequests');
const Courses = require('collections/Courses');
const utils = require('core/utils');
const storage = require('core/storage');
const {logoutUser, me} = require('core/auth');
const CreateAccountModal = require('views/core/CreateAccountModal/CreateAccountModal');
const fetchJson = require('core/api/fetch-json');
const DOMPurify = require('dompurify');

module.exports = (HomeCNView = (function() {
  HomeCNView = class HomeCNView extends RootView {
    static initClass() {
      this.prototype.id = 'home-cn-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click .continue-playing-btn': 'onClickTrackEvent',
        'click .example-gd-btn': 'onClickTrackEvent',
        'click .example-wd-btn': 'onClickTrackEvent',
        'click .play-btn': 'onClickTrackEvent',
        'click .signup-home-btn': 'onClickTrackEvent',
        'click .student-btn': 'onClickStudentButton',
        'click .teacher-btn': 'onClickTeacherButton',
        'click .request-quote': 'onClickRequestQuote',
        'click .logout-btn': 'logoutAccount',
        'click .profile-btn': 'onClickTrackEvent',
        'click .setup-class-btn': 'onClickSetupClass',
        'click .my-classes-btn': 'onClickTrackEvent',
        'click .my-courses-btn': 'onClickTrackEvent',
        'click a': 'onClickAnchor'
      };
    }

    constructor (options) {
      super(options)

      this.courses = new Courses();
      this.supermodel.trackRequest(this.courses.fetchReleased());

      // @getBanner()
      if (me.isTeacher()) {
        this.trialRequests = new TrialRequests();
        this.trialRequests.fetchOwn();
        return this.supermodel.loadCollection(this.trialRequests);
      }
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
        return this.banner.display = DOMPurify.sanitize(marked(content != null ? content : ''));
      });
    }

    onLoaded() {
      if (this.trialRequests != null ? this.trialRequests.size() : undefined) { this.trialRequest = this.trialRequests.first(); }
      return super.onLoaded();
    }

    onClickRequestQuote(e) {
      this.playSound('menu-button-click');
      e.preventDefault();
      e.stopImmediatePropagation();
      this.homePageEvent($(e.target).data('event-action'));
      if (me.isTeacher()) {
        return application.router.navigate('/teachers/update-account', {trigger: true});
      } else {
        return application.router.navigate('/contact-cn', {trigger: true});
      }
    }

    onClickSetupClass(e) {
      this.homePageEvent($(e.target).data('event-action'));
      return application.router.navigate("/teachers/classes", { trigger: true });
    }

    onClickStudentButton(e) {
      this.homePageEvent('Started Signup');
      this.homePageEvent($(e.target).data('event-action'));
      return this.openModalView(new CreateAccountModal({startOnPath: 'student'}));
    }

    onClickTeacherButton(e) {
      this.homePageEvent('Started Signup');
      this.homePageEvent($(e.target).data('event-action'));
      return this.openModalView(new CreateAccountModal({startOnPath: 'teacher'}));
    }

    onClickTrackEvent(e) {
      let properties;
      if (__guard__($(e.target), x => x.hasClass('track-ab-result'))) {
        properties = {trackABResult: true};
      }
      return this.homePageEvent($(e.target).data('event-action'), properties || {});
    }

    // Provides a uniform interface for collecting information from the homepage.
    // Always provides the category Homepage and includes the user role.
    homePageEvent(action, extraproperties) {
      if (extraproperties == null) { extraproperties = {}; }
      const defaults = {
        category: 'Homepage',
        user: me.get('role') || (me.isAnonymous() && "anonymous") || "homeuser"
      };
      const properties = _.merge(defaults, extraproperties);
      return (window.tracker != null ? window.tracker.trackEvent(action, properties) : undefined);
    }

    onClickAnchor(e) {
      let anchor, anchorText, properties;
      if (!(anchor = e != null ? e.currentTarget : undefined)) { return; }
      // Track an event with action of the English version of the link text
      let translationKey = $(anchor).attr('data-i18n');
      if (translationKey == null) { translationKey = $(anchor).children('[data-i18n]').attr('data-i18n'); }
      if (translationKey) {
        anchorText = $.i18n.t(translationKey, {lng: 'en-US'});
      } else {
        anchorText = anchor.text;
      }

      if (__guard__($(e.target), x => x.hasClass('track-ab-result'))) {
        properties = {trackABResult: true};
      }

      if (anchorText) {
        return this.homePageEvent(`Link: ${anchorText}`, properties || {});
      } else {
        _.extend(properties || {}, {
          clicked: __guard__(e != null ? e.currentTarget : undefined, x1 => x1.host) || "unknown"
        });
        return this.homePageEvent("Link:", properties);
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
      }
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

    logoutAccount() {
      Backbone.Mediator.publish("auth:logging-out", {});
      return logoutUser();
    }

    mergeWithPrerendered(el) {
      return true;
    }
  };
  HomeCNView.initClass();
  return HomeCNView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}