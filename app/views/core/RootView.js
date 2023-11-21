// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// A root view is one that replaces everything else on the screen when it
// comes into being, as opposed to sub-views which get inserted into other views.

let RootView;
const {
  merge
} = require('lodash');

const CocoView = require('./CocoView');

const {logoutUser, me} = require('core/auth');
const locale = require('locale/locale');

const Achievement = require('models/Achievement');
const AchievementPopup = require('views/core/AchievementPopup');
let errors = require('core/errors');
const utils = require('core/utils');
const userUtils = require('../../lib/user-utils');

const BackboneVueMetaBinding = require('app/core/BackboneVueMetaBinding').default;
const Navigation = require('app/components/common/Navigation.vue').default;
const Footer = require('app/components/common/Footer.vue').default;
const store = require('core/store');

const filterKeyboardEvents = (allowedEvents, func) => (function(...splat) {
  const e = splat[0];
  if (!Array.from(allowedEvents).includes(e.keyCode) && !!e.keyCode) { return; }
  return func(...Array.from(splat || []));
});

module.exports = (RootView = (function() {
  RootView = class RootView extends CocoView {
    static initClass() {
      this.prototype.showBackground = true;
  
      this.prototype.events = {
        'click #logout-button': 'logoutAccount',
        'click #nav-stop-spying-button': 'stopSpying',
        'click #nav-stop-switching-button': 'stopSwitching',
        'click #nav-student-mode': 'switchToStudentMode',
        'change .language-dropdown': 'onLanguageChanged',
        'click .language-dropdown li': 'onLanguageChanged',
        'click .toggle-fullscreen': 'toggleFullscreen',
        'click .signup-button': 'onClickSignupButton',
        'click .login-button': 'onClickLoginButton',
        'treema-error': 'onTreemaError',
        'click [data-i18n]': 'onClickTranslatedElement',
        'click .track-click-event': 'onTrackClickEvent',
        'click .dashboard-toggle-link': 'onClickDashboardToggleLink'
      };
  
      this.prototype.subscriptions =
        {'achievements:new': 'handleNewAchievements'};
  
      this.prototype.shortcuts =
        {'ctrl+shift+a': 'navigateToAdmin'};
          //console.log 'Saved language:', newLang
  
      this.prototype.isOldBrowser = utils.isOldBrowser;
  
      this.prototype.isChinaOldBrowser = utils.isChinaOldBrowser;
  
      this.prototype.logoutRedirectURL = '/';
    }

    initialize(options) {
      super.initialize(options);

      try {
        return this.initializeMetaBinding();
      } catch (e) {
        return console.error('Failed to initialize meta binding', e);
      }
    }

    showNewAchievement(achievement, earnedAchievement) {
      earnedAchievement.set('notified', true);
      earnedAchievement.patch();
      if ((achievement.get('collection') === 'level.sessions') && !__guard__(achievement.get('query'), x => x.team)) { return; }
      //return if @isIE()  # Some bugs in IE right now, TODO fix soon!  # Maybe working now with not caching achievement fetches in CocoModel?
      if (window.serverConfig.picoCTF) { return; }
      if (achievement.get('hidden')) { return; }

      if (utils.isOzaria) { return; } // Hiding legacy achievement popups in Ozaria
      return new AchievementPopup({achievement, earnedAchievement});
    }

    handleNewAchievements(e) {
      return _.each(e.earnedAchievements.models, earnedAchievement => {
        const achievement = new Achievement({_id: earnedAchievement.get('achievement')});
        return achievement.fetch({
          success: achievement => (typeof this.showNewAchievement === 'function' ? this.showNewAchievement(achievement, earnedAchievement) : undefined),
          cache: false
        });
      });
    }

    logoutAccount() {
      if (application.isIPadApp) { __guard__(__guard__(__guard__(typeof window !== 'undefined' && window !== null ? window.webkit : undefined, x2 => x2.messageHandlers), x1 => x1.notification), x => x.postMessage({name: "signOut"})); }
      Backbone.Mediator.publish("auth:logging-out", {});
      const category = utils.isCodeCombat ? 'Homepage' : 'Home';
      if (this.id === 'home-view') { if (window.tracker != null) {
        window.tracker.trackEvent('Log Out', {category});
      } }
      if (me.isTarena()) {
        return logoutUser({
          success() {
            return window.location = "http://kidtts.tmooc.cn/ttsPage/login.html";
          }
        });
      } else {
        return logoutUser();
      }
    }

    stopSpying() {
      return me.stopSpying({
        success() { return document.location.reload(); },
        error() {
          return errors.showNotyNetworkError(...arguments);
        }
      });
    }

    stopSwitching() {
      const text = 'Switching to teacher account..';
      noty({ text, type: 'success', timeout: 5000, killer: true });
      return me.switchToTeacherMode()
        .then(() => document.location.reload())
        .catch(err => errors.showNotyNetworkError(err));
    }

    switchToStudentMode() {
      const text = 'Switching to test student account..';
      noty({ text, type: 'success', timeout: 5000, killer: true });
      return me.switchToStudentMode()
        .then(() => window.location.reload())
        .catch(err => errors.showNotyNetworkError(err));
    }

    onClickSignupButton(e) {
      const CreateAccountModal = require('views/core/CreateAccountModal');
      switch (this.id) {
        case 'home-view':
          var properties = {
            category: utils.isCodeCombat ? 'Homepage' : 'Home'
          };
          if (window.tracker != null) {
            window.tracker.trackEvent('Started Signup', properties);
          }
          var eventAction = __guard__($(e.target), x => x.data('event-action'));
          if (eventAction) { if (window.tracker != null) {
            window.tracker.trackEvent(eventAction, properties);
          } }
          break;
        case 'world-map-view':
          // TODO: add campaign data
          if (window.tracker != null) {
            window.tracker.trackEvent('Started Signup', {category: 'World Map', label: 'World Map'});
          }
          break;
        default:
          if (window.tracker != null) {
            window.tracker.trackEvent('Started Signup', {label: this.id});
          }
      }
      const options = {};
      if (userUtils.isInLibraryNetwork()) {
        options.startOnPath = 'individual';
      }
      return this.openModalView(new CreateAccountModal(options));
    }

    onClickLoginButton(e) {
      const {
        loginMessage
      } = e.target.dataset;
      const {
        nextUrl
      } = e.target.dataset;
      const AuthModal = require('views/core/AuthModal');
      if (this.id === 'home-view') {
        const properties = { category: utils.isCodeCombat ? 'Homepage' : 'Home' };
        if (window.tracker != null) {
          window.tracker.trackEvent('Login', properties);
        }

        const eventAction = __guard__($(e.target), x => x.data('event-action'));
        if (eventAction) { if (window.tracker != null) {
          window.tracker.trackEvent(eventAction, properties);
        } }
      }
      return this.openModalView(new AuthModal({loginMessage, nextUrl}));
    }

    onTrackClickEvent(e) {
      const eventAction = __guard__(__guard__($(e.target), x1 => x1.closest('a')), x => x.data('event-action'));
      if (eventAction) {
        return (window.tracker != null ? window.tracker.trackEvent(eventAction, { category: 'Teachers' }) : undefined);
      }
    }

    onClickDashboardToggleLink(e) {
      __guard__(__guard__($(e.target), x1 => x1.parent('.dashboard-button')), x => x.addClass('active'));
      return __guard__(__guard__(__guard__($(e.target), x4 => x4.parent('.dashboard-button')), x3 => x3.siblings('.dashboard-button')), x2 => x2.removeClass('active'));
    }

    showLoading($el) {
      if ($el == null) { $el = this.$el.find('#site-content-area'); }
      return super.showLoading($el);
    }

    afterInsert() {
      // force the browser to scroll to the hash
      // also messes with the browser history, so perhaps come up with a better solution
      super.afterInsert();
      //hash = location.hash
      //location.hash = ''
      //location.hash = hash
      this.renderScrollbar();

      // Ensure navigation displays when visting SingletonAppVueComponentView.
      return this.initializeNavigation();
    }

    afterRender() {
      if (this.$el.find('#main-nav.legacy').length) { // hack...
        this.$el.addClass('site-chrome');
        if (this.showBackground) {
          this.$el.addClass('show-background');
        }
      }

      super.afterRender(...arguments);
      if (location.hash) { this.chooseTab(location.hash.replace('#', '')); }
      this.buildLanguages();
      $('body').removeClass('is-playing');
      return this.initializeNavigation();
    }

    chooseTab(category) {
      return $(`a[href='#${category}']`, this.$el).tab('show');
    }

    // TODO: automate tabs to put in hashes when they are clicked

    buildLanguages() {
      const $select = this.$el.find('.language-dropdown').empty();
      const preferred = me.get('preferredLanguage', true);
      this.addLanguagesToSelect($select, preferred);
      return $('body').attr('lang', preferred);
    }

    addLanguagesToSelect($select, initialVal) {
      // For now, we only want to support a few languages for Ozaria that we have people working to translate.
      const filteredLocale = locale;
      const codes = _.keys(filteredLocale);

      // Because we only support a few languages, we force English as the default here:
      if (initialVal == null) { initialVal = me.get('preferredLanguage', true); }
      if (utils.isOzaria && !Array.from(codes).includes(initialVal)) {
        initialVal = 'en-US';
      }

      if ($select.is('ul')) { // base-flat
        __guard__(this.$el.find('.language-dropdown-current'), x => x.text(locale[initialVal].nativeDescription));
      }

      const genericCodes = _.filter(codes, code => _.find(codes, code2 => (code2 !== code) && (code2.split('-')[0] === code)));
      return (() => {
        const result = [];
        for (var code in filteredLocale) {
          var localeInfo = filteredLocale[code];
          if (!(Array.from(genericCodes).includes(code)) || (code === initialVal)) {
            if ($select.is('ul')) { // base-flat template
              $select.append(
                $('<li data-code="' + code + '"><a class="language-dropdown-item" href="#">' + localeInfo.nativeDescription + '</a></li>'));
              if (utils.isCodeCombat && (code === 'pt-BR')) {
                result.push($select.append($('<li role="separator" class="divider"</li>')));
              } else {
                result.push(undefined);
              }
            } else { // base template
              $select.append($('<option></option>').val(code).text(localeInfo.nativeDescription));
              if (utils.isCodeCombat && (code === 'pt-BR')) {
                $select.append(
                  $('<option class="select-dash" disabled="disabled"></option>').text('----------------------------------'));
              }
              result.push($select.val(initialVal));
            }
          }
        }
        return result;
      })();
    }

    onLanguageChanged(event){
      let newLang;
      const targetElem = $(event.currentTarget);
      if (targetElem.is('li')) { // base-flat template
        newLang = targetElem.data('code');
        __guard__(this.$el.find('.language-dropdown-current'), x => x.text(locale[newLang].nativeDescription));
      } else { // base template
        newLang = $('.language-dropdown').val();
      }
      return $.i18n.changeLanguage(newLang, () => {
        this.saveLanguage(newLang);
        return locale.load(me.get('preferredLanguage', true)).then(() => {
          return this.onLanguageLoaded();
        });
      });
    }

    onLanguageLoaded() {
      this.render();
      if (!utils.isOzaria && (me.get('preferredLanguage').split('-')[0] !== 'en') && !me.hideDiplomatModal()) {
        const DiplomatModal = require('views/core/DiplomatSuggestionModal');
        return this.openModalView(new DiplomatModal());
      }
    }

    saveLanguage(newLang) {
      me.set('preferredLanguage', newLang);
      const res = me.patch();
      if (!res) { return; }
      res.error(function() {
        errors = JSON.parse(res.responseText);
        return console.warn('Error saving language:', errors);
      });
      return res.success(function(model, response, options) {});
    }

    navigateToAdmin() {
      if (window.serverSession.amActually || me.isAdmin()) {
        return application.router.navigate('/admin', {trigger: true});
      }
    }

    onTreemaError(e) {
      return noty({text: e.message, layout: 'topCenter', type: 'error', killer: false, timeout: 5000, dismissQueue: true});
    }

    // Initialize the binding to vue-meta by initializing a Vue component that sets the head tags
    // on render.  This binding will be destroyed via the Vue component's $destory method when
    // this view is destroyed.  Views can specify @skipMetaBinding = true when they want to manage
    // head tags in their own way.  This is useful for legacy Vue components that eventually inherit
    // from RootView (ie RootComponent and VueComponentView).  These views can use vue-meta directly
    // within their Vue components.
    initializeMetaBinding() {
      if (this.metaBinding) {
        return this.metaBinding;
      }

      // Set a noop meta binding object when the view opts to skip meta binding
      if (this.skipMetaBinding) {
        return this.metaBinding = {
          $destroy() {},
          setMeta() {}
        };
      }

      let legacyTitle = this.getTitle();
      if (typeof localStorage !== 'undefined' && localStorage !== null ? localStorage.showViewNames : undefined) {
        legacyTitle = this.constructor.name;
      }

      // Create an empty, mounted element so that the vue component actually renders and runs vue-meta
      return this.metaBinding = new BackboneVueMetaBinding({
        el: document.createElement('div'),
        propsData: {
          baseMeta: this.getMeta(),
          legacyTitle
        }
      });
    }

    // Attach the navigation Vue component to the page
    initializeNavigation() {
      let staticFooter, staticNav;
      if (staticNav = document.querySelector('#main-nav')) {
        if (this.navigation) {
          staticNav.replaceWith(this.navigation.$el);
        } else {
          this.navigation = new Navigation({ el: staticNav, store });
          // Hack - It would be better for the Navigation component to manage the language dropdown.
          _.defer(() => (typeof this.buildLanguages === 'function' ? this.buildLanguages() : undefined));
        }
      }
      if (staticFooter = document.querySelector('#site-footer')) {
        if (this.footer) {
          return staticFooter.replaceWith(this.footer.$el);
        } else {
          return this.footer = new Footer({ el: staticFooter, store });
        }
      }
    }

    // Set the page title when the view is loaded.  This value is merged into the
    // result of getMeta.  It will override any title specified in getMeta.  Kept
    // for backwards compatibility
    getTitle() { return ''; }

    // Head tag configuration used to configure vue-meta when the View is loaded.
    // See https://vue-meta.nuxtjs.org/ for available configuration options.  This
    // can be later modified by calling setMeta
    getMeta() { return {}; }

    // Allow async updates of the view's meta configuration.  This can be used in addition to getMeta
    // to update meta configuration when the meta configuration is computed asynchronously
    setMeta(meta) {
      return this.metaBinding.setMeta(meta);
    }

    destroy() {
      if (this.metaBinding != null) {
        this.metaBinding.$destroy();
      }
      if (this.navigation != null) {
        this.navigation.$destroy();
      }
      if (this.footer != null) {
        this.footer.$destroy();
      }
      return super.destroy();
    }
  };
  RootView.initClass();
  return RootView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}