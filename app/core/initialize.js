// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS203: Remove `|| {}` from converted for-own loops
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let serializeForIOS;
Backbone.Mediator.setValidationEnabled(false);
let app = null;
const utils = require('./utils');
const { installVueI18n } = require('locale/locale');
const { log } = require('ozaria/site/common/logger');
const globalVar = require('core/globalVar');

const VueRouter = require('vue-router');
const Vuex = require('vuex');
const VTooltip = require('v-tooltip');
const VueMoment = require('vue-moment');
const VueMeta = require('vue-meta');
const VueYoutube = require('vue-youtube');
const VueShepherd = require('vue-shepherd');
const { VueMaskDirective } = require('v-mask');
const VueAsyncComputed = require('vue-async-computed');

Vue.use(VueRouter.default);
Vue.use(Vuex.default);
Vue.use(VueMoment.default);

if (utils.isCodeCombat) {
  Vue.use(VueYoutube.default);
}

Vue.use(VTooltip.default);
Vue.use(VueMeta);

if (utils.isOzaria) {
  Vue.use(VueShepherd);
  Vue.use(utils.vueNonReactiveInstall);
  Vue.use(VueAsyncComputed);
  Vue.directive('mask', VueMaskDirective);
}

const channelSchemas = {
  'auth': require('schemas/subscriptions/auth'),
  'bus': require('schemas/subscriptions/bus'),
  'editor': require('schemas/subscriptions/editor'),
  'errors': require('schemas/subscriptions/errors'),
  'ipad': require('schemas/subscriptions/ipad'),
  'misc': require('schemas/subscriptions/misc'),
  'play': require('schemas/subscriptions/play'),
  'surface': require('schemas/subscriptions/surface'),
  'tome': require('schemas/subscriptions/tome'),
  'god': require('schemas/subscriptions/god'),
  'scripts': require('schemas/subscriptions/scripts'),
  'web-dev': require('schemas/subscriptions/web-dev'),
  'world': require('schemas/subscriptions/world')
};

const definitionSchemas = {
  'bus': require('schemas/definitions/bus'),
  'misc': require('schemas/definitions/misc')
};

var init = function() {
  if (app) { return; }
  if (!(window.userObject != null ? window.userObject._id : undefined)) {
    const options = { cache: false };
    options.data = _.pick(utils.getQueryVariables(), 'preferredLanguage');
    $.ajax('/auth/whoami', options).then(function(res) {
      window.userObject = res;
      return init();
    });
    return;
  }

  marked.setOptions({gfm: true, sanitize: true, smartLists: true, breaks: false});
  app = require('core/application');
  setupConsoleLogging();
  watchForErrors();
  setUpIOSLogging();
  const path = document.location.pathname;
  app.testing = _.string.startsWith(path, '/test');
  app.demoing = _.string.startsWith(path, '/demo');
  setUpBackboneMediator(app);
  app.initialize();
  if (!app.isProduction()) { loadOfflineFonts(); }
  if (utils.isCodeCombat) {
    // We always want to load this font.
    $('head').prepend('<link rel="stylesheet" type="text/css" href="/fonts/vt323.css">');
  }
  Backbone.history.start({ pushState: true });
  handleNormalUrls();
  setUpMoment(); // Set up i18n for moment
  setUpTv4();
  installVueI18n();
  if (utils.isOzaria) {
    checkAndLogBrowserCrash();
    checkAndRegisterHocModalInterval();
  }
  if (me.isAdmin() || !app.isProduction() || (typeof serverSession !== 'undefined' && serverSession !== null ? serverSession.amActually : undefined) || (typeof serverSession !== 'undefined' && serverSession !== null ? serverSession.switchingUserActualId : undefined)) { window.globalVar = globalVar; }
  if (self !== parent) { return parent.globalVar = globalVar; }
};

module.exports.init = init;

var handleNormalUrls = () => // https://artsy.github.io/blog/2012/06/25/replacing-hashbang-routes-with-pushstate/
$(document).on('click', "a[href^='/']", function(event) {

  const href = $(event.currentTarget).attr('href');
  const target = $(event.currentTarget).attr('target');

  // chain 'or's for other black list routes
  const passThrough = href.indexOf('sign_out') >= 0;

  // Allow shift+click for new tabs, etc.
  if (passThrough || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey || (target === '_blank')) {
    return;
  }

  event.preventDefault();

  // Remove leading slashes and hash bangs (backward compatablility)
  const url = href.replace(/^\//,'').replace('\#\!\/','');

  // Instruct Backbone to trigger routing events
  app.router.navigate(url, { trigger: true });

  return false;
});

var setUpBackboneMediator = function(app) {
  let schemas;
  for (var definition in definitionSchemas) { schemas = definitionSchemas[definition]; Backbone.Mediator.addDefSchemas(schemas); }
  for (var channel in channelSchemas) { schemas = channelSchemas[channel]; Backbone.Mediator.addChannelSchemas(schemas); }
  // Major performance bottleneck if it is true in production
  Backbone.Mediator.setValidationEnabled(!app.isProduction());

  if (window.location.hostname === 'localhost') {
    if ((window.sessionStorage != null ? window.sessionStorage.getItem('COCO_DEBUG_LOGGING') : undefined) === "1") {
      const unwantedEventsRegex = new RegExp('tick|mouse-moved|mouse-over|mouse-out|hover-line|check-away|new-thang-added|zoom-updated|away-back');
      const unwantedStackRegex = new RegExp('eval|debounce|defer|delay|Backbone|Idle');
      const originalPublish = Backbone.Mediator.publish;
      return Backbone.Mediator.publish = function() {
        if (!unwantedEventsRegex.test(arguments[0])) {
          try {
            const splitStack = (new Error()).stack.split("\n").slice(1);
            const maxDepth = 5;
            for (let i = 0; i < splitStack.length; i++) {
              var s = splitStack[i];
              if (i > maxDepth) { break; }
              var filteredStack = s.trim().replace(/at\ |prototype|module|exports/gi, '').replace('..', '');
              filteredStack = filteredStack.split('(webpack-internal')[0];
              if (!unwantedStackRegex.test(filteredStack)) {
                console.log(`>>> ${filteredStack}->`, ...arguments);
                break;
              }
            }
          } catch (error) {
            console.log(">>> ? -> ", ...arguments);
          }
        }

        return originalPublish.apply(Backbone.Mediator, arguments);
      };
    } else {
      return console.log("Not logging Backbone events. Turn on by typing this in your browser console: window.sessionStorage.setItem('COCO_DEBUG_LOGGING', 1)");
    }
  }
};

var setUpMoment = function() {
  const {me} = require('core/auth');
  const setMomentLanguage = function(lang) {
    lang = {
      'zh-HANS': 'zh-cn',
      'zh-HANT': 'zh-tw'
    }[lang] || lang;
    return moment.locale(lang.toLowerCase());
  };
    // TODO: this relies on moment having all languages baked in, which is a performance hit; should switch to loading the language module we need on demand.
  setMomentLanguage(me.get('preferredLanguage', true));
  return me.on('change:preferredLanguage', me => setMomentLanguage(me.get('preferredLanguage', true)));
};

var setUpTv4 = function() {
  const forms = require('core/forms');
  return tv4.addFormat({
  'email'(email) {
    if (forms.validateEmail(email)) {
      return null;
    } else {
      return {code: tv4.errorCodes.FORMAT_CUSTOM, message: $.t('form_validation_errors.requireValidEmail')};
    }
  },
  'phoneNumber'(phoneNumber) {
    if (forms.validatePhoneNumber(phoneNumber)) {
      return null;
    } else {
      return {code: tv4.errorCodes.FORMAT_CUSTOM, message: $.t('form_validation_errors.requireValidPhone')};
    }
  }
  });
};

var setupConsoleLogging = function() {
  // IE9 doesn't expose console object unless debugger tools are loaded
  if (typeof console === 'undefined' || console === null) {
    window.console = {
      info() {},
      log() {},
      error() {},
      debug() {}
    };
  }
  if (!console.debug) {
    // Needed for IE10 and earlier
    return console.debug = console.log;
  }
};

var watchForErrors = function() {
  let currentErrors = 0;
  const oldOnError = window.onerror;

  const showError = function(text) {
    if (currentErrors >= 3) { return; }
    if (app.isProduction() && !me.isAdmin()) { return; } // Don't show noty error messages in production when not an admin
    if (!me.isAdmin() && (document.location.href.search(/codecombat.com/) !== -1) && (document.location.href.search(/\/editor\//) === -1)) { return; }
    ++currentErrors;
    if (!(typeof webkit !== 'undefined' && webkit !== null ? webkit.messageHandlers : undefined)) {  // Don't show these notys on iPad
      return noty({
        text,
        layout: 'topCenter',
        type: 'error',
        killer: false,
        timeout: 5000,
        dismissQueue: true,
        maxVisible: 3,
        callback: {onClose() { return --currentErrors; }}
      });
    }
  };

  window.onerror = function(msg, url, line, col, error) {
    if (oldOnError) { oldOnError.apply(window, arguments); }
    const message = `Error: ${msg}<br>Check the JS console for more.`;
    showError(message);
    return Backbone.Mediator.publish('application:error', {message: `Line ${line} of ${url}:\n${msg}`});  // For iOS app
  };

  // Promise error handling
  return window.addEventListener("unhandledrejection", function(err) {
    if (err.promise) {
      return err.promise.catch(function(e) {
        const message = `${e.message}<br>Check the JS console for more.`;
        return showError(message);
      });
    } else {
      const message = `${err.message || err}<br>Check the JS console for more.`;
      return showError(message);
    }
  });
};

window.addIPadSubscription = channel => window.iPadSubscriptions[channel] = true;

window.removeIPadSubscription = channel => window.iPadSubscriptions[channel] = false;

var setUpIOSLogging = function() {
  if (!(typeof webkit !== 'undefined' && webkit !== null ? webkit.messageHandlers : undefined)) { return; }
  return ['debug', 'log', 'info', 'warn', 'error'].map((level) =>
    (function(level) {
      const originalLog = console[level];
      return console[level] = function() {
        originalLog.apply(console, arguments);
        try {
          let left;
          return __guard__(__guard__(typeof webkit !== 'undefined' && webkit !== null ? webkit.messageHandlers : undefined, x1 => x1.consoleLogHandler), x => x.postMessage({level, arguments: ((Array.from(arguments).map((a) => (left = __guardMethod__(a, 'toString', o => o.toString())) != null ? left : ('' + a))))}));
        } catch (e) {
          return __guard__(__guard__(typeof webkit !== 'undefined' && webkit !== null ? webkit.messageHandlers : undefined, x3 => x3.consoleLogHandler), x2 => x2.postMessage({level, arguments: ['could not post log: ' + e]}));
        }
      };
    })(level));
};

var loadOfflineFonts = function() {
  $('head').prepend('<link rel="stylesheet" type="text/css" href="/fonts/openSansCondensed.css">');
  $('head').prepend('<link rel="stylesheet" type="text/css" href="/fonts/openSans.css">');
  if (utils.isOzaria) {
    $('head').prepend('<link rel="stylesheet" type="text/css" href="/fonts/workSans.css">');
    return $('head').prepend('<link rel="stylesheet" type="text/css" href="/fonts/spaceMono.css">');
  }
};

// This is so hacky... hopefully it's restrictive enough to not be slow.
// We could also keep a list of events we are actually subscribed for and only try to send those over.
let seen = null;
window.serializeForIOS = (serializeForIOS = function(obj, depth) {
  if (depth == null) { depth = 3; }
  if (!depth) { return {}; }
  const root = (seen == null);
  if (seen == null) { seen = []; }
  const clone = {};
  let keysHandled = 0;
  for (var key of Object.keys(obj || {})) {
    var value = obj[key];
    if (++keysHandled > 50) { continue; }
    if (!value) {
      clone[key] = value;
    } else if ((value === window) || value.firstElementChild || value.preventDefault) {
      null;  // Don't include these things
    } else if (Array.from(seen).includes(value)) {
      null;  // No circular references
    } else if (_.isArray(value)) {
      clone[key] = (Array.from(value).map((child) => serializeForIOS(child, depth - 1)));
      seen.push(value);
    } else if (_.isObject(value)) {
      if (value.id && value.attributes) { value = value.attributes; }
      clone[key] = serializeForIOS(value, depth - 1);
      seen.push(value);
    } else {
      clone[key] = value;
    }
  }
  if (root) { seen = null; }
  return clone;
});

// We refresh the browser between levels due to memory leak issues
// hence should register hoc progress modal check after every refresh if relevant
var checkAndRegisterHocModalInterval = function() {
  if (window.sessionStorage != null ? window.sessionStorage.getItem('hoc_progress_modal_time') : undefined) { // set in unit map
    return utils.registerHocProgressModalCheck();
  }
};

// Check if the crash happened, and log it on datadog. Note that the application should be initialized before this.
var checkAndLogBrowserCrash = function() {
  if (window.sessionStorage != null ? window.sessionStorage.getItem('oz_crashed') : undefined) {
    log('Browser crashed', {}, 'error');
    return (window.sessionStorage != null ? window.sessionStorage.removeItem('oz_crashed') : undefined);
  }
};

window.onbeforeunload = function(e) {
  if (utils.isOzaria) {
    if (window.sessionStorage != null) {
      window.sessionStorage.setItem('oz_exit', 'true');
    }
  }
  const leavingMessage = _.result(globalVar.currentView, 'onLeaveMessage');
  if (leavingMessage) {
    // Custom messages don't work any more, main browsers just show generic ones. So, this could be refactored.
    return leavingMessage;
  } else {
    return;
  }
};

if (utils.isOzaria) {
  window.onload = function() {
    if (window.sessionStorage) {
      // Check if the browser crashed before the current loading in order to log it on datadog
      if (window.sessionStorage.getItem('oz_exit') && (window.sessionStorage.getItem('oz_exit') !== 'true')) {
        window.sessionStorage.setItem('oz_crashed', 'true');
      }
      return window.sessionStorage.setItem('oz_exit', 'pending');
    }
  };
}

$(() => init());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName);
  } else {
    return undefined;
  }
}