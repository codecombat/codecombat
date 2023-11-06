// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CocoView;
const SuperModel = require('models/SuperModel');
const utils = require('core/utils');
const CocoClass = require('core/CocoClass');
const loadingScreenTemplate = require('app/templates/core/loading');
const loadingErrorTemplate = require('app/templates/core/loading-error');
require('app/styles/core/loading-error.sass');
const auth = require('core/auth');
const ViewVisibleTimer = require('core/ViewVisibleTimer');
const storage = require('core/storage');
const zendesk = require('core/services/zendesk');

let visibleModal = null;
let waitingModal = null;
let classCount = 0;
const makeScopeName = () => `view-scope-${classCount++}`;
const doNothing = function() {};
const ViewLoadTimer = require('core/ViewLoadTimer');

module.exports = (CocoView = (function() {
  CocoView = class CocoView extends Backbone.View {
    static initClass() {
      this.prototype.cache = false; // signals to the router to keep this view around
      this.prototype.retainSubviews = false;

      this.prototype.events = {
        'click #loading-error .login-btn': 'onClickLoadingErrorLoginButton',
        'click #loading-error #create-account-btn': 'onClickLoadingErrorCreateAccountButton',
        'click #loading-error #logout-btn': 'onClickLoadingErrorLogoutButton',
        'click .contact-modal': 'onClickContactModal'
      };

      this.prototype.subscriptions = {};
      this.prototype.shortcuts = {};

      // load progress properties
      this.prototype.loadProgress =
        {progress: 0};

      // Subscriptions

      this.prototype.addNewSubscription = CocoClass.prototype.addNewSubscription;

      this.prototype.isIE = utils.isIE;
       // set to true if you don't want subviews to be destroyed whenever the view renders
    }
    template() { return ''; }

    // Setup, Teardown

    constructor(options) {
      super(...arguments);
      this.modalShown = this.modalShown.bind(this);
      this.modalClosed = this.modalClosed.bind(this);
      this.animatePointer = this.animatePointer.bind(this);
      this.loadProgress = _.cloneDeep(this.loadProgress);
      if (!this.supermodel) { this.supermodel = new SuperModel(); }
      this.options = options;
      if (options ? options.supermodel : undefined) { // kind of a hacky way to get each view to store its own progress
        this.supermodel.models = options.supermodel.models;
        this.supermodel.collections = options.supermodel.collections;
        this.supermodel.shouldSaveBackups = options.supermodel.shouldSaveBackups;
      }

      this.subscriptions = utils.combineAncestralObject(this, 'subscriptions');
      this.events = utils.combineAncestralObject(this, 'events');
      this.scope = makeScopeName();
      this.shortcuts = utils.combineAncestralObject(this, 'shortcuts');
      this.subviews = {};
      this.listenToShortcuts();
      this.updateProgressBar = _.debounce(this.updateProgressBar, 100);
      // Backbone.Mediator handles subscription setup/teardown automatically

      this.listenTo(this.supermodel, 'loaded-all', this.onLoaded);
      this.listenTo(this.supermodel, 'update-progress', this.updateProgress);
      this.listenTo(this.supermodel, 'failed', this.onResourceLoadFailed);
      this.warnConnectionError = _.throttle(this.warnConnectionError, 3000);

      $('body').addClass('product-' + utils.getProductName().toLowerCase());

      // Warn about easy-to-create race condition that only shows up in production
      const listenedSupermodel = this.supermodel;
      _.defer(() => {
        if ((listenedSupermodel !== this.supermodel) && !this.destroyed) {
          throw new Error(`${(this.constructor != null ? this.constructor.name : undefined) != null ? (this.constructor != null ? this.constructor.name : undefined) : this}: Supermodel listeners not hooked up! Don't reassign @supermodel; CocoView does that for you.`);
        }
      });
    }

    destroy() {
      if (this.viewVisibleTimer != null) {
        this.viewVisibleTimer.destroy();
      }
      this.stopListening();
      this.off();
      this.stopListeningToShortcuts();
      this.undelegateEvents(); // removes both events and subs
      for (var id in this.subviews) { var view = this.subviews[id]; view.destroy(); }
      $('#modal-wrapper .modal').off('hidden.bs.modal', this.modalClosed);
      if (utils.isCodeCombat) {
        $('#modal-wrapper .modal').off('shown.bs.modal', this.modalShown);
      }
      this.$el.find('.has-tooltip, [data-original-title]').tooltip('destroy');
      try {
        this.$('.nano').nanoScroller({destroy: true});
      } catch (e) {
        console.log('dont know why but ', this.$('.nano'), ' failed with ', e);
      }
      this.endHighlight();
      this.getPointer(false).remove();
      for (var key in this) { var value = this[key]; this[key] = undefined; }
      this.destroyed = true;
      this.off = doNothing;
      this.destroy = doNothing;
      return $.noty.closeAll();
    }

    trackTimeVisible(param) {
      if (param == null) { param = {}; }
      const { trackViewLifecycle } = param;
      if (this.viewVisibleTimer) { return; }
      this.viewVisibleTimer = new ViewVisibleTimer();
      return this.trackViewLifecycle = trackViewLifecycle;
    }

    // Report the currently visible feature — this is the default handler for whole-view tracking
    // Views with more involved features should implement this method instead.
    currentVisiblePremiumFeature() {
      if (this.trackViewLifecycle) {
        return { viewName: this.id };
      } else {
        return null;
      }
    }

    updateViewVisibleTimer() {
      if (!this.viewVisibleTimer) { return; }
      const visibleFeature = !this.hidden && !this.destroyed && this.currentVisiblePremiumFeature();
      if (visibleFeature && !_.isEqual(visibleFeature, this.viewVisibleTimer.featureData)) {
        this.viewVisibleTimer.stopTimer({ clearName: true });
        return this.viewVisibleTimer.startTimer(visibleFeature);
      } else if (!visibleFeature) {
        return this.viewVisibleTimer.stopTimer({ clearName: true });
      }
    }

    destroyAceEditor(editor) {
      // convenience method to make sure the ace editor is as destroyed as can be
      if (!editor) { return; }
      const session = editor.getSession();
      session.setMode('');
      return editor.destroy();
    }

    afterInsert() {
      if (storage.load('sub-modal-continue')) {
        const subModalContinue = storage.load('sub-modal-continue');
        storage.remove('sub-modal-continue');
        _.defer(() => {
          const SubscribeModal = require('views/core/SubscribeModal');
          return this.openModalView(new SubscribeModal({subModalContinue}));
        });
      }
      return this.updateViewVisibleTimer();
    }

    willDisappear() {
      // the router removes this view but this view will be cached
      this.undelegateEvents();
      this.hidden = true;
      this.updateViewVisibleTimer();
      this.stopListeningToShortcuts();
      for (var id in this.subviews) { var view = this.subviews[id]; view.willDisappear(); }
      return $.noty.closeAll();
    }

    didReappear() {
      // the router brings back this view from the cache
      this.delegateEvents();
      const wasHidden = this.hidden;
      this.hidden = false;
      this.updateViewVisibleTimer();
      if (wasHidden) { this.listenToShortcuts(); }
      return (() => {
        const result = [];
        for (var id in this.subviews) {
          var view = this.subviews[id];
          result.push(view.didReappear());
        }
        return result;
      })();
    }


    // View Rendering

    isRTL(s) {
      // Hebrew is 0x0590 - 0x05FF, which is adjacent to Arabic at 0x0600 - 0x06FF
      return /[\u0590-\u06FF]/.test(s);
    }

    applyRTLIfNeeded() {
      let needle;
      if ((needle = me.get('preferredLanguage'), !['he', 'ar', 'fa', 'ur'].includes(needle))) { return; }
      return this.$('[data-i18n]').each((i, el) => {
        if (!this.isRTL(el.innerHTML)) { return; }
        el.dir = 'rtl';
        $(el).parentsUntil('table, form, noscript, div:not([class~="rtl-allowed"]):not([class~="form"]):not([class~="form-group"]):not([class~="form-group"]), [dir="ltr"]').attr('dir', 'rtl');
        return $(el).parents('div.form').attr('dir', 'rtl');
      });
    }

    renderSelectors(...selectors) {
      const newTemplate = $(this.template(this.getRenderData()));
      for (let i = 0; i < selectors.length; i++) {
        var selector = selectors[i];
        for (var elPair of Array.from(_.zip(this.$el.find(selector), newTemplate.find(selector)))) {
          $(elPair[0]).replaceWith($(elPair[1]));
        }
      }
      this.delegateEvents();
      this.$el.i18n();
      return this.applyRTLIfNeeded();
    }

    render() {
      let oldSubviews, view;
      if (!me) { return this; }
      if (this.retainSubviews) {
        oldSubviews = _.values(this.subviews);
      } else {
        for (var id in this.subviews) { view = this.subviews[id]; view.destroy(); }
      }
      this.subviews = {};
      super.render();
      if (_.isString(this.template)) { return this.template; }
      this.$el.html(this.template(this.getRenderData()));

      if (this.retainSubviews) {
        for (view of Array.from(oldSubviews)) {
          this.insertSubView(view);
        }
      }

      if (!this.supermodel.finished()) {
        this.showLoading();
      } else {
        this.hideLoading();
      }

      this.afterRender();
      this.$el.i18n();
      this.applyRTLIfNeeded();
      return this;
    }

    getRenderData(context) {
      if (context == null) { context = {}; }
      context.isProduction = application.isProduction();
      context.me = me;
      context.pathname = document.location.pathname;  // like '/play/level'
      context.fbRef = context.pathname.replace(/[^a-zA-Z0-9+/=\-.:_]/g, '').slice(0, 40) || 'home';
      context.isMobile = this.isMobile();
      context.isIE = this.isIE();
      context.moment = moment;
      context.translate = $.t;
      context.view = this;
      context._ = _;
      context.document = document;
      context.i18n = utils.i18n;
      context.state = this.state;
      context.serverConfig = window.serverConfig;
      context.serverSession = window.serverSession;
      context.features = window.features;
      context.getQueryVariable = utils.getQueryVariable;
      return context;
    }

    afterRender() {
      return this.renderScrollbar();
    }

    renderScrollbar() {
      //Defer the call till the content actually gets rendered, nanoscroller requires content to be visible
      return _.defer(() => { if (!this.destroyed) { return this.$el.find('.nano').nanoScroller(); } });
    }

    updateProgress(progress) {
      if (this.destroyed) { return; }

      if (progress > this.loadProgress.progress) { this.loadProgress.progress = progress; }
      return this.updateProgressBar(progress);
    }

    updateProgressBar(progress) {
      if (this.destroyed) { return; }

      this.trigger('loading:progress', progress * 100);
      const prog = `${parseInt(progress*100)}%`;
      return (this.$el != null ? this.$el.find('.loading-container .progress-bar').css('width', prog) : undefined);
    }

    onLoaded() { return this.render(); }

    // Error handling for loading
    onResourceLoadFailed(e) {
      const r = e.resource;
      if (r.value) {
        this.stopListening(this.supermodel);
      }
      if ((r.jqxhr != null ? r.jqxhr.status : undefined) === 402) { return; } // payment-required failures are handled separately
      return this.showError(r.jqxhr);
    }

    warnConnectionError() {
      const msg = $.i18n.t('loading_error.connection_failure', {defaultValue: 'Connection failed.'});
      return noty({text: msg, layout: 'center', type: 'error', killer: true, timeout: 3000});
    }

    onClickContactModal(e) {
      // if !application.isProduction()
      //   noty({
      //     text: 'Contact options are only available in production',
      //     layout: 'center',
      //     type: 'error',
      //     timeout: 5000
      //   })
      //   return

      // If there is no way to open the chat, there's no point in giving the choice in the modal,
      // so we go directly to zendesk. This could potentially be improved in the future by checking
      // availability of support somehow, and going to zendesk if no one is there to answer drift chat.

      const openDirectContactModal = () => {
        let DirectContactModal;
        if (utils.isCodeCombat) {
          DirectContactModal = require('app/views/core/DirectContactModal').default;
        } else {
          DirectContactModal = require('ozaria/site/views/core/DirectContactModal').default;
        }

        return this.openModalView(new DirectContactModal());
      };

      const openContactModal = () => {
        let ContactModal;
        if (utils.isCodeCombat) {
          ContactModal = require('app/views/core/ContactModal');
        } else {
          ContactModal = require('ozaria/site/views/core/ContactModal');
        }

        return this.openModalView(new ContactModal());
      };

      const confirmOOOMessage = afterConfirm => {
        const oooStart = new Date('2023-06-05T00:00:00Z');
        const oooEnd = new Date('2023-06-09T23:59:59Z');

        const storageKey = `contact-modal-confirm-seen-${me.id}-${oooStart.getTime()}-${oooEnd.getTime()}`;
        const seen = storage.load(storageKey);

        const isOoo = (new Date() > oooStart) && (new Date() < oooEnd);

        if ((!isOoo) || seen) {
          afterConfirm();
          return;
        }

        const renderData = {
          body: $.i18n.t('contact.ooo_blurb'),
          decline: $.i18n.t('modal.cancel'),
          confirm: $.i18n.t('modal.okay')
        };
        const ConfirmModal = require('views/core/ConfirmModal');
        const confirmModal = new ConfirmModal(renderData);
        confirmModal.on('confirm', function() {
          storage.save(storageKey, true);
          return afterConfirm();
        });

        return this.openModalView(confirmModal);
      };

      return confirmOOOMessage(() => {
        if ((me.isTeacher(true) && zE) || me.showChinaResourceInfo()) {
          return openDirectContactModal();
        } else if (utils.isCodeCombat) {
          return openContactModal();
        } else {
          return location.href = 'mailto:support@codecombat.com';
        }
      });
    }

    onClickLoadingErrorLoginButton(e) {
      e.stopPropagation(); // Backbone subviews and superviews will handle this call repeatedly otherwise
      const AuthModal = require('views/core/AuthModal');
      return this.openModalView(new AuthModal());
    }

    onClickLoadingErrorCreateAccountButton(e) {
      e.stopPropagation();
      const CreateAccountModal = require('views/core/CreateAccountModal');
      return this.openModalView(new CreateAccountModal({mode: 'signup'}));
    }

    onClickLoadingErrorLogoutButton(e) {
      e.stopPropagation();
      return auth.logoutUser();
    }

    // Modals

    openModalView(modalView, softly) {
      if (softly == null) { softly = false; }
      if (waitingModal) { return; } // can only have one waiting at once
      if (visibleModal) {
        waitingModal = modalView;
        if (softly) { return; }
        if (visibleModal.$el.is(':visible')) { return visibleModal.hide(); } // close, then this will get called again
        return this.modalClosed(visibleModal); // was closed, but modalClosed was not called somehow
      }
      const viewLoad = new ViewLoadTimer(modalView);
      modalView.render();

      $('#modal-wrapper').removeClass('hide').empty().append(modalView.el);
      modalView.afterInsert();
      visibleModal = modalView;
      const modalOptions = {show: true, backdrop: modalView.closesOnClickOutside ? true : 'static'};
      if ((typeof modalView.closesOnEscape === 'boolean') && (modalView.closesOnEscape === false)) { // by default, closes on escape, i.e. if modalView.closesOnEscape = undefined
        modalOptions.keyboard = false;
      }
      if (utils.isCodeCombat) {
        $('.modal-backdrop').remove();  // Hack: get rid of any extras that might be left over from mishandled Vue modals
        const modalRef = $('#modal-wrapper .modal').modal(modalOptions);
        // Hack: Vue modals don't know how to turn the background off because they never really close/destroy. Or maybe they just create two copies sometimes? So, if this is a Vue modal, hide its modal-backdrop
        $('.modal-backdrop').toggleClass('vue-modal', Boolean(modalView.VueComponent));
        modalRef.on('hidden.bs.modal', this.modalClosed);
        modalRef.on('shown.bs.modal', this.modalShown);
      } else {
        $('#modal-wrapper .modal').modal(modalOptions).on('hidden.bs.modal', this.modalClosed);
      }
      window.currentModal = modalView;
      this.getRootView().stopListeningToShortcuts(true);
      Backbone.Mediator.publish('modal:opened', {});
      viewLoad.record();
      return modalView;
    }

    modalShown() {
      return (visibleModal != null ? visibleModal.trigger('shown') : undefined);  // Null soak: this could have closed while in opening animation and already be gone
    }

    modalClosed() {
      if (visibleModal) { visibleModal.willDisappear(); }
      if (visibleModal != null) {
        visibleModal.destroy();
      }
      visibleModal = null;
      window.currentModal = null;
      //$('#modal-wrapper .modal').off 'hidden.bs.modal', @modalClosed
      $('#modal-wrapper').addClass('hide');
      if (waitingModal) {
        const wm = waitingModal;
        waitingModal = null;
        return this.openModalView(wm);
      } else {
        this.getRootView().listenToShortcuts(true);
        return Backbone.Mediator.publish('modal:closed', {});
      }
    }

    // Loading RootViews

    showLoading($el) {
      if ($el == null) { ({
        $el
      } = this); }
      this.trigger('loading:show');
      $el.find('>').addClass('hidden');
      $el.append(loadingScreenTemplate()).i18n();
      this.applyRTLIfNeeded();
      return this._lastLoading = $el;
    }

    hideLoading() {
      if (this._lastLoading == null) { return; }
      this.trigger('loading:hide');
      this._lastLoading.find('.loading-screen').remove();
      this._lastLoading.find('>').removeClass('hidden');
      return this._lastLoading = null;
    }

    showError(jqxhr) {
      if (this._lastLoading == null) { return; }
      const context = {
        jqxhr,
        view: this,
        me
      };
      this._lastLoading.find('.loading-screen').replaceWith((loadingErrorTemplate(context)));
      this._lastLoading.i18n();
      return this.applyRTLIfNeeded();
    }

    showReadOnly() {
      if (me.isAdmin() || me.isArtisan()) { return; }
      const warning = $.i18n.t('editor.read_only_warning2', {defaultValue: 'Note: you can\'t save any edits here, because you\'re not logged in.'});
      return noty({text: warning, layout: 'center', type: 'information', killer: true, timeout: 5000});
    }

    // Loading ModalViews

    enableModalInProgress(modal) {
      const el = modal.find('.modal-content');
      el.find('> div', modal).hide();
      return el.find('.wait', modal).show();
    }

    disableModalInProgress(modal) {
      const el = modal.find('.modal-content');
      el.find('> div', modal).show();
      return el.find('.wait', modal).hide();
    }

    // Shortcuts

    listenToShortcuts(recurse) {
      if (!key) { return; }
      for (var shortcut in this.shortcuts) {
        var func = this.shortcuts[shortcut];
        func = utils.normalizeFunc(func, this);
        key(shortcut, this.scope, _.bind(func, this));
      }
      if (recurse) {
        return (() => {
          const result = [];
          for (var viewID in this.subviews) {
            var view = this.subviews[viewID];
            result.push(view.listenToShortcuts());
          }
          return result;
        })();
      }
    }

    stopListeningToShortcuts(recurse) {
      if (!key) { return; }
      key.deleteScope(this.scope);
      if (recurse) {
        return (() => {
          const result = [];
          for (var viewID in this.subviews) {
            var view = this.subviews[viewID];
            result.push(view.stopListeningToShortcuts());
          }
          return result;
        })();
      }
    }

    // Subviews

    insertSubView(view, elToReplace=null) {
      // used to insert views with ids
      const key = this.makeSubViewKey(view);
      if (this.subviews[key]) { this.subviews[key].destroy() }
      if (elToReplace == null) { elToReplace = this.$el.find('#'+view.id); }
      if (this.retainSubviews) {
        this.registerSubView(view, key);
        if (elToReplace[0]) {
          view.setElement(elToReplace[0]);
          view.render();
          view.afterInsert();
        }
        return view;

      } else {
        elToReplace.after(view.el).remove();
        this.registerSubView(view, key);
        view.render();
        view.afterInsert();
        return view;
      }
    }

    registerSubView(view, key) {
      // used to register views which are custom inserted into the view,
      // like views where you add multiple instances of them
      key = this.makeSubViewKey(view);
      view.parent = this;
      view.parentKey = key;
      this.subviews[key] = view
      return view;
    }

    makeSubViewKey(view) {
      let key = view.id || (view.constructor.name+classCount++);
      key = _.string.underscored(key);  // handy for autocomplete in dev console
      return key;
    }

    removeSubView(view) {
      view.$el.empty();
      delete this.subviews[view.parentKey];
      return view.destroy();
    }

    // Pointing stuff out

    highlightElement(selector, options) {
      let delay, offset;
      this.endHighlight();
      if (options == null) { options = {}; }
      if (delay = options.delay) {
        delete options.delay;
        return this.pointerDelayTimeout = _.delay((() => this.highlightElement(selector, options)), delay);
      }
      const $pointer = this.getPointer();
      const $target = $(selector + ':visible');
      if (parseFloat($target.css('opacity')) === 0.0) { return; }  // Don't point out invisible elements.
      if (!(offset = $target.offset())) { return; }  // Don't point out elements we can't locate.
      let targetLeft = offset.left + ($target.outerWidth() * 0.5);
      let targetTop = offset.top + ($target.outerHeight() * 0.5);

      if (options.sides) {
        if (Array.from(options.sides).includes('left')) { targetLeft = offset.left; }
        if (Array.from(options.sides).includes('right')) { targetLeft = offset.left + $target.outerWidth(); }
        if (Array.from(options.sides).includes('top')) { targetTop = offset.top; }
        if (Array.from(options.sides).includes('bottom')) { targetTop = offset.top + $target.outerHeight(); }
      } else {
        // Aim to hit the side if the target is entirely on one side of the screen.
        if (offset.left > (this.$el.outerWidth() * 0.5)) {
          targetLeft = offset.left;
        } else if ((offset.left + $target.outerWidth()) < (this.$el.outerWidth() * 0.5)) {
          targetLeft = offset.left + $target.outerWidth();
        }

        // Aim to hit the bottom or top if the target is entirely on the top or bottom of the screen.
        if (offset.top > (this.$el.outerWidth() * 0.5)) {
          targetTop = offset.top;
        } else if  ((offset.top + $target.outerHeight()) < (this.$el.outerHeight() * 0.5)) {
          targetTop = offset.top + $target.outerHeight();
        }
      }

      if (options.offset) {
        targetLeft += options.offset.x;
        targetTop += options.offset.y;
      }

      this.pointerRadialDistance = -47;
      this.pointerRotation = options.rotation != null ? options.rotation : Math.atan2((this.$el.outerWidth() * 0.5) - targetLeft, targetTop - (this.$el.outerHeight() * 0.5));
      const initialScale = Math.max(1, 20 - me.level());
      $pointer.css({
        opacity: 1.0,
        transition: 'none',
        transform: `rotate(${this.pointerRotation}rad) translate(-3px, ${this.pointerRadialDistance}px) scale(${initialScale})`,
        top: targetTop - 50,
        left: targetLeft - 50
      });
      _.defer(() => {
        if (this.destroyed) { return; }
        this.animatePointer();
        clearInterval(this.pointerInterval);
        return this.pointerInterval = setInterval(this.animatePointer, 1200);
      });
      if (options.duration) {
        return this.pointerDurationTimeout = _.delay((() => { if (!this.destroyed) { return this.endHighlight(); } }), options.duration);
      }
    }

    animatePointer() {
      const $pointer = this.getPointer();
      $pointer.css({transition: 'all 0.6s ease-out', transform: `rotate(${this.pointerRotation}rad) translate(-3px, ${this.pointerRadialDistance-50}px)`});
      return setTimeout((() => $pointer.css({transition: 'all 0.4s ease-in', transform: `rotate(${this.pointerRotation}rad) translate(-3px, ${this.pointerRadialDistance}px)`})), 800);
    }

    endHighlight() {
      this.getPointer(false).css({'opacity': 0.0, 'transition': 'none', top: '-50px', right: '-50px'});
      clearInterval(this.pointerInterval);
      clearTimeout(this.pointerDelayTimeout);
      clearTimeout(this.pointerDurationTimeout);
      return this.pointerInterval = (this.pointerDelayTimeout = (this.pointerDurationTimeout = null));
    }

    getPointer(add) {
      let $pointer;
      if (add == null) { add = true; }
      if (($pointer = $(`.highlight-pointer[data-cid='${this.cid}']`)) && ($pointer.length || !add)) { return $pointer; }
      $pointer = $(`<img src='/images/level/pointer.png' class='highlight-pointer' data-cid='${this.cid}'>`);
      if (this.$el.parents('#modal-wrapper').length) { $pointer.css('z-index', 1040); }
      $('body').append($pointer);
      return $pointer;
    }

    // Utilities

    getRootView() {
      let view = this;
      while (view.parent != null) { view = view.parent; }
      return view;
    }

    isMobile() {
      const ua = navigator.userAgent || navigator.vendor || window.opera;
      return mobileRELong.test(ua) || mobileREShort.test(ua.substr(0, 4));
    }

    isMac() {
      return navigator.platform.toUpperCase().indexOf('MAC') !== -1;
    }

    isIPadApp() {
      if (this._isIPadApp != null) { return this._isIPadApp; }
      return this._isIPadApp = ((typeof webkit !== 'undefined' && webkit !== null ? webkit.messageHandlers : undefined) != null) && ((navigator.userAgent != null ? navigator.userAgent.indexOf('iPad') : undefined) !== -1);
    }

    isIPadBrowser() {
      return __guard__(typeof navigator !== 'undefined' && navigator !== null ? navigator.userAgent : undefined, x => x.indexOf('iPad')) !== -1;
    }

    isFirefox() {
      return navigator.userAgent.toLowerCase().indexOf('firefox') !== -1;
    }

    scrollToLink(link, speed) {
      if (speed == null) { speed = 300; }
      const scrollTo = $(link).offset().top;
      return $('html, body').animate({ scrollTop: scrollTo }, speed);
    }

    scrollToTop(speed) {
      if (speed == null) { speed = 300; }
      return $('html, body').animate({ scrollTop: 0 }, speed);
    }

    toggleFullscreen(e) {
      // https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Using_full_screen_mode?redirectlocale=en-US&redirectslug=Web/Guide/DOM/Using_full_screen_mode
      // Whoa, even cooler: https://developer.mozilla.org/en-US/docs/WebAPI/Pointer_Lock
      let req;
      const full = document.fullscreenElement ||
             document.mozFullScreenElement ||
             document.mozFullscreenElement ||
             document.webkitFullscreenElement ||
             document.msFullscreenElement;
      const d = document.documentElement;
      if (!full) {
        req = d.requestFullScreen ||
              d.mozRequestFullScreen ||
              d.mozRequestFullscreen ||
              d.msRequestFullscreen ||
              (d.webkitRequestFullscreen ? () => d.webkitRequestFullscreen(Element.ALLOW_KEYBOARD_INPUT) : null);
        if (req != null) {
          req.call(d);
        }
        if (req) { this.playSound('full-screen-start'); }
      } else {
        const nah = document.exitFullscreen ||
              document.mozCancelFullScreen ||
              document.mozCancelFullscreen ||
              document.msExitFullscreen ||
              document.webkitExitFullscreen;
        if (nah != null) {
          nah.call(document);
        }
        if (req) { this.playSound('full-screen-end'); }
      }
    }

    playSound(trigger, volume, delay, pos=null, pan) {
      if (volume == null) { volume = 1; }
      if (delay == null) { delay = 0; }
      if (pan == null) { pan = 0; }
      return Backbone.Mediator.publish('audio-player:play-sound', {trigger, volume, delay, pos, pan});
    }

    tryCopy() {
      let message;
      try {
        document.execCommand('copy');
        message = 'Copied to clipboard';
        return noty({text: message, layout: 'topCenter', type: 'info', killer: false, timeout: 2000});
      } catch (err) {
        message = 'Oops, unable to copy';
        return noty({text: message, layout: 'topCenter', type: 'error', killer: false, timeout: 3000});
      }
    }

    wait(event) { return new Promise(resolve => this.once(event, resolve)); }

    onClickTranslatedElement(e) {
      if ((!key.ctrl && !key.command) || !key.alt) { return; }
      e.preventDefault();
      e.stopImmediatePropagation();
      const i18nKey = _.last($(e.currentTarget).data('i18n').split(';')).replace(/\[.*?\]/, '');
      const base = $.i18n.t(i18nKey, {lng: 'en'});
      const translated = $.i18n.t(i18nKey);
      const en = require('locale/en');
      const [clickedSection, clickedKey] = Array.from(i18nKey.split('.'));
      let lineNumber = 2;
      let found = false;
      for (var enSection in en.translation) {
        var enEntries = en.translation[enSection];
        for (var enKey in enEntries) {
          var enValue = enEntries[enKey];
          ++lineNumber;
          if ((clickedSection === enSection) && (clickedKey === enKey)) {
            found = true;
            break;
          }
        }
        if (found) { break; }
        lineNumber += 2;
      }
      if (!found) {
        return console.log(`Couldn't find ${i18nKey} in app/locale/en.coffee.`);
      }
      let targetLanguage = me.get('preferredLanguage') || 'en';
      if (targetLanguage.split('-')[0] === 'en') { targetLanguage = 'en'; }
      const githubUrl = `https://github.com/codecombat/codecombat/blob/master/app/locale/${targetLanguage}.coffee#L${lineNumber}`;
      return window.open(githubUrl, {target: '_blank'});
    }
  };
  CocoView.initClass();
  return CocoView;
})());

var mobileRELong = /(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino/i;

var mobileREShort = /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i;

module.exports = CocoView;

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}