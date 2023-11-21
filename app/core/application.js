// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const globalVar = require('core/globalVar');

// TODO: move this out of here to where it should go
window.SPRITE_RESOLUTION_FACTOR = 3;
window.SPRITE_PLACEHOLDER_WIDTH = 10;

// Prevent Ctrl/Cmd + [ / ], P, S
const ctrlDefaultPrevented = [219, 221, 80, 83];
const preventBackspace = function(event) {
  if ((event.keyCode === 8) && !elementAcceptsKeystrokes(event.srcElement || event.target)) {
    return event.preventDefault();
  } else if ((event.ctrlKey || event.metaKey) && !event.altKey && Array.from(ctrlDefaultPrevented).includes(event.keyCode)) {
    console.debug("Prevented keystroke", key, event);
    return event.preventDefault();
  }
};

var elementAcceptsKeystrokes = function(el) {
  // http://stackoverflow.com/questions/1495219/how-can-i-prevent-the-backspace-key-from-navigating-back
  if (el == null) { el = document.activeElement; }
  const tag = el.tagName.toLowerCase();
  const type = el.type != null ? el.type.toLowerCase() : undefined;
  const textInputTypes = ['text', 'password', 'file', 'number', 'search', 'url', 'tel', 'email', 'date', 'month', 'week', 'time', 'datetimelocal'];
  // not radio, checkbox, range, or color
  return ((tag === 'textarea') || ((tag === 'input') && Array.from(textInputTypes).includes(type)) || ['', 'true'].includes(el.contentEditable)) && !(el.readOnly || el.disabled);
};

// IE9 doesn't expose console object unless debugger tools are loaded
if (window.console == null) { window.console = {
  info() {},
  log() {},
  error() {},
  debug() {}
}; }
if (console.debug == null) { console.debug = console.log; }  // Needed for IE10 and earlier

const Application = {
  initialize() {
    let i18nextInstance, userUtils;
    const {me} = require('core/auth');
    const i18next = require('i18next');
    const jqueryI18next = require('jquery-i18next');
    const CocoModel = require('models/CocoModel');
    const FacebookHandler = require('core/social-handlers/FacebookHandler');
    const GPlusHandler = require('core/social-handlers/GPlusHandler');
    const GitHubHandler = require('core/social-handlers/GitHubHandler');
    const locale = require('locale/locale');
    const Tracker = require('core/Tracker2').default;
    const api = require('core/api');
    const utils = require('core/utils');
    if (utils.isCodeCombat) { userUtils = require('../lib/user-utils'); }
    const wsBus = require('lib/wsBus');

    const Router = require('core/Router');
    Vue.config.devtools = !this.isProduction();
    Vue.config.ignoredElements = ['stream']; // Used for Cloudflare Cutscene Player and would throw Vue warnings

    // propagate changes from global 'me' User to 'me' vuex module
    const store = require('core/store');

    if (utils.useWebsocket) {
      this.wsBus = new wsBus();
    }
    me.on('change', () => store.commit('me/updateUser', me.changedAttributes()));
    store.commit('me/updateUser', me.attributes);
    store.commit('updateFeatures', features);
    if (utils.isOzaria) {
      store.dispatch('layoutChrome/syncSoundToAudioSystem');
    }

    this.store = store;
    this.api = api;

    this.isIPadApp = ((typeof webkit !== 'undefined' && webkit !== null ? webkit.messageHandlers : undefined) != null) && ((navigator.userAgent != null ? navigator.userAgent.indexOf('CodeCombat-iPad') : undefined) !== -1);
    if (this.isIPadApp) { $('body').addClass('ipad'); }
    if (window.serverConfig.picoCTF) { $('body').addClass('picoctf'); }
    if ($.browser.msie && (parseInt($.browser.version) === 10)) {
      $("html").addClass("ie10");
    }

    this.tracker = new Tracker(store);
    window.tracker = this.tracker;
    locale.load(me.get('preferredLanguage', true))
      .then(() => this.tracker.initialize())
      .catch(e => console.error('Tracker initialization failed', e));

    if (me.useSocialSignOn()) {
      this.facebookHandler = new FacebookHandler();
      this.gplusHandler = new GPlusHandler();
    }
      //@githubHandler = new GitHubHandler(@)  # Currently unused
    $(document).bind('keydown', preventBackspace);
    moment.relativeTimeThreshold('ss', 1); // do not return 'a few seconds' when calling 'humanize'
    CocoModel.pollAchievements();
    if (!me.get('anonymous')) {
      this.checkForNewAchievement();
    }
    this.remindPlayerToTakeBreaks();
    if (utils.isCodeCombat) { userUtils.provisionPremium(); }
    window.i18n = (i18nextInstance = i18next.default.createInstance({
      lng: me.get('preferredLanguage', true),
      fallbackLng: locale.mapFallbackLanguages(),
      resources: locale,
      interpolation: {prefix: '__', suffix: '__'}
      //debug: true
    }));
    i18nextInstance.init();
    i18nextInstance.services.languageUtils.__proto__.formatLanguageCode = code => code;  // Hack so that it doesn't turn zh-HANS into zh-Hans
    jqueryI18next.init(i18nextInstance, $, {
      tName: 't',  // --> appends $.t = i18next.t
      i18nName: 'i18n',  // --> appends $.i18n = i18next
      handleName: 'i18n',  // --> appends $(selector).i18n(opts)
      selectorAttr: 'data-i18n',  // selector for translating elements
      targetAttr: 'i18n-target',  // data-() attribute to grab target element to translate (if different than itself)
      optionsAttr: 'i18n-options',  // data-() attribute that contains options, will load/set if useOptionsAttr = true
      useOptionsAttr: true,  // see optionsAttr
      parseDefaultValueFromContent: true
    }
    );  // parses default values from content ele.val or ele.text
    // We need i18n loaded before setting up router.
    // Otherwise dependencies can't use i18n.
    const routerSync = require('vuex-router-sync');
    const vueRouter = require('app/core/vueRouter').default();
    routerSync.sync(store, vueRouter);

    this.router = new Router();
    this.userIsIdle = false;
    const onIdleChanged = to => { return () => { return Backbone.Mediator.publish('application:idle-changed', {idle: (this.userIsIdle = to)}); }; };
    this.idleTracker = new Idle({
      onAway: onIdleChanged(true),
      onAwayBack: onIdleChanged(false),
      onHidden: onIdleChanged(true),
      onVisible: onIdleChanged(false),
      awayTimeout: 5 * 60 * 1000
    });
    this.idleTracker.start();
    this.trackProductVisit();
    return this.setReferrerTracking();
  },

  checkForNewAchievement() {
    let startFrom;
    const utils = require('core/utils');
    if (utils.isOzaria) { return; }  // Not needed until/unlesss we start using achievements in Ozaria
    if (me.get('lastAchievementChecked')) {
      startFrom = new Date(me.get('lastAchievementChecked'));
    } else {
      startFrom = me.created();
    }

    const daysSince = moment.duration(new Date() - startFrom).asDays();
    if (daysSince > 1) {
      return me.checkForNewAchievement().then(() => this.checkForNewAchievement());
    }
  },

  featureMode: {
    useChina() { return api.admin.setFeatureMode('china').then(() => document.location.reload()); },
    usePicoCtf() { return api.admin.setFeatureMode('pico-ctf').then(() => document.location.reload()); },
    useBrainPop() { return api.admin.setFeatureMode('brain-pop').then(() => document.location.reload()); },
    clear() { return api.admin.clearFeatureMode().then(() => document.location.reload()); }
  },

  isProduction() {
    return document.location.href.search('https?://localhost') === -1;
  },

  loadedStaticPage: (window.alreadyLoadedView != null),

  setHocCampaign(campaignSlug) {
    const storage = require('core/storage');
    return storage.save('hoc-campaign', campaignSlug);
  },

  getHocCampaign() {
    const storage = require('core/storage');
    return storage.load('hoc-campaign');
  },

  remindPlayerToTakeBreaks() {
    if (!me.showChinaRemindToast()) { return; }
    return setInterval(( () => noty({
      text: '你已经练习了一个小时了，建议休息一会儿哦',
      layout: 'topRight',
      type:'warning',
      killer: false,
      timeout: 5000
      })), 3600000);
  },  // one hour

  trackProductVisit() {
    if (window.serverSession != null ? window.serverSession.amActually : undefined) { return; }
    const utils = require('core/utils');
    //activity = "visit-#{utils.getProduct()}"
    const activity = `visit-${utils.isOzaria ? 'ozaria' : 'codecombat'}`;
    const last = __guard__(__guard__(me.get('activity'), x1 => x1[activity]), x => x.last);
    if (last && moment(last).isAfter(moment().subtract(12, 'hour'))) { return; }
    return me.trackActivity(activity);
  },

  setReferrerTracking() {
    if (window.serverSession != null ? window.serverSession.amActually : undefined) { return; }
    const utils = require('core/utils');
    const queryParams = utils.getQueryVariables();
    const utmSource = queryParams['utm_source'];
    const utmMedium = queryParams['utm_medium'];
    const utmCampaign = queryParams['utm_campaign'];
    const referrerParams = {};
    if (utmSource) {
      referrerParams.source = utmSource;
    }
    if (utmMedium) {
      referrerParams.medium = utmMedium;
    }
    if (utmCampaign) {
      referrerParams.campaign = utmCampaign;
    }
    if (Object.keys(referrerParams).length === 0) {
      return;
    }
    const value = Object.assign(referrerParams, (me.get('referrerTrack') || {}));
    me.set('referrerTrack', value);
    return me.save();
  }
};

module.exports = Application;
globalVar.application = Application;

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}