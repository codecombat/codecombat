// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ClansView;
require('app/styles/clans/clans.sass');
const CreateAccountModal = require('views/core/CreateAccountModal');
const RootView = require('views/core/RootView');
const template = require('app/templates/clans/clans');
const CocoCollection = require('collections/CocoCollection');
const Clan = require('models/Clan');
const SubscribeModal = require('views/core/SubscribeModal');

// TODO: Waiting for async messages
// TODO: Invalid clan name message
// TODO: Refresh data instead of page

module.exports = (ClansView = (function() {
  ClansView = class ClansView extends RootView {
    static initClass() {
      this.prototype.id = 'clans-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click .create-clan-btn': 'onClickCreateClan',
        'click .join-clan-btn': 'onJoinClan',
        'click .leave-clan-btn': 'onLeaveClan',
        'click .private-clan-checkbox': 'onClickPrivateCheckbox'
      };
    }

    getMeta() {
      return {
        title: $.i18n.t('clans.title'),
        meta: [
          { vmid: 'meta-description', name: 'description', content: $.i18n.t('clans.meta_description') }
        ]
      };
    }

    constructor (options = {}) {
      super(options)
      this.loadData()
    }

    initialize() {
      super.initialize();

      this.publicClansArray = [];
      this.myClansArray = [];
      this.idNameMap = {};
    }

    destroy() {
      if (typeof this.stopListening === 'function') {
        this.stopListening();
      }
      return super.destroy();
    }

    afterRender() {
      super.afterRender();
      return this.setupPrivateInfoPopover();
    }

    onLoaded() {
      super.onLoaded();
      this.publicClansArray = _.filter(this.publicClans.models, clan => clan.get('type') === 'public');
      return this.myClansArray = this.myClans.models;
    }

    loadData() {
      let left;
      const sortClanList = function(a, b) {
        if (a.get('memberCount') !== b.get('memberCount')) {
          if (a.get('memberCount') < b.get('memberCount')) { return 1; } else { return -1; }
        } else {
          return b.id.localeCompare(a.id);
        }
      };
      this.publicClans = new CocoCollection([], { url: '/db/clan/-/public?excludeAutoclans=true', model: Clan, comparator: sortClanList });
      this.listenTo(this.publicClans, 'sync', () => {
        this.refreshNames(this.publicClans.models);
        return (typeof this.render === 'function' ? this.render() : undefined);
      });
      this.supermodel.loadCollection(this.publicClans, 'public_clans', {cache: false});

      this.myClans = new CocoCollection([], { url: `/db/user/${me.id}/clans`, model: Clan, comparator: sortClanList });
      this.listenTo(this.myClans, 'sync', () => {
        this.refreshNames(this.myClans.models);
        return (typeof this.render === 'function' ? this.render() : undefined);
      });
      this.supermodel.loadCollection(this.myClans, 'my_clans', {cache: false});

      this.listenTo(me, 'sync', () => (typeof this.render === 'function' ? this.render() : undefined));
      return this.myClanIDs = (left = me.get('clans')) != null ? left : [];
    }

    refreshNames(clans) {
      let clanIDs = _.filter(clans, clan => clan.get('type') === 'public');
      clanIDs = _.filter(_.map(clans, clan => clan.get('ownerID')));
      const options = {
        url: '/db/user/-/names',
        method: 'POST',
        data: {ids: clanIDs},
        success: (models, response, options) => {
          for (var userID in models) { this.idNameMap[userID] = models[userID].name; }
          return (typeof this.render === 'function' ? this.render() : undefined);
        }
      };
      return this.supermodel.addRequestResource('user_names', options, 0).load();
    }

    setupPrivateInfoPopover() {
      const popoverTitle = "<h3>" + $.i18n.t('clans.private_clans') + "</h3>";
      let popoverContent = "<ul>";
      popoverContent += "<li><span style='font-weight:bold;'>" + $.i18n.t('clans.track_concepts1') + "</span> " + $.i18n.t('clans.track_concepts2b');
      popoverContent += "<li>" + $.i18n.t('clans.track_concepts3b');
      popoverContent += "<li>" + $.i18n.t('clans.track_concepts4b') + " <span style='font-weight:bold;'>" + $.i18n.t('clans.track_concepts5') + "</span>";
      popoverContent += "<li>" + $.i18n.t('clans.track_concepts6b');
      popoverContent += "<li><span style='font-weight:bold;'>" + $.i18n.t('clans.track_concepts7') + "</span> " + $.i18n.t('clans.track_concepts8');
      popoverContent += "</ul>";
      popoverContent += "<p><img src='/images/pages/clans/dashboard_preview.png' height='400'></p>";
      popoverContent += "<p>" + $.i18n.t('clans.private_require_sub') + "</p>";
      return this.$el.find('.private-more-info').popover({
        animation: true,
        html: true,
        placement: 'right',
        trigger: 'hover',
        title: popoverTitle,
        content: popoverContent,
        container: this.$el
      });
    }

    onClickCreateClan(e) {
      let name;
      if (me.isAnonymous()) { return this.openModalView(new CreateAccountModal()); }
      const clanType = $('.private-clan-checkbox').prop('checked') ? 'private' : 'public';
      if ((clanType === 'private') && !me.isPremium()) {
        this.openModalView(new SubscribeModal());
        if (window.tracker != null) {
          window.tracker.trackEvent('Show subscription modal', {category: 'Subscription', label: 'create clan'});
        }
        return;
      }
      if (name = $('.create-clan-name').val()) {
        let description;
        const clan = new Clan();
        clan.set('type', clanType);
        clan.set('name', name);
        if (description = $('.create-clan-description').val()) { clan.set('description', description); }
        return clan.save({}, {
          error: (model, response, options) => {
            return console.error('Error saving clan', response.status);
          },
          success: (model, response, options) => {
            application.router.navigate(`/clans/${model.id}`);
            return window.location.reload();
          }
        }
        );
      } else {
        return console.log('Invalid name');
      }
    }

    onJoinClan(e) {
      let clanID;
      if (me.isAnonymous()) { return this.openModalView(new CreateAccountModal()); }
      if (clanID = $(e.target).data('id')) {
        const options = {
          url: `/db/clan/${clanID}/join`,
          method: 'PUT',
          error: (model, response, options) => {
            return console.error('Error joining clan', response);
          },
          success: (model, response, options) => {
            application.router.navigate(`/clans/${clanID}`);
            return window.location.reload();
          }
        };
        return this.supermodel.addRequestResource( 'join_clan', options).load();
      } else {
        return console.error("No clan ID attached to join button.");
      }
    }

    onLeaveClan(e) {
      let clanID;
      if (clanID = $(e.target).data('id')) {
        const options = {
          url: `/db/clan/${clanID}/leave`,
          method: 'PUT',
          error: (model, response, options) => {
            return console.error('Error leaving clan', response);
          },
          success: (model, response, options) => {
            me.fetch({cache: false});
            this.publicClans.fetch({cache: false});
            return this.myClans.fetch({cache: false});
          }
        };
        return this.supermodel.addRequestResource( 'leave_clan', options).load();
      } else {
        return console.error("No clan ID attached to leave button.");
      }
    }

    onClickPrivateCheckbox(e) {
      if (me.isAnonymous()) { return this.openModalView(new CreateAccountModal()); }
      if ($('.private-clan-checkbox').prop('checked') && !me.isPremium()) {
        $('.private-clan-checkbox').attr('checked', false);
        this.openModalView(new SubscribeModal());
        return (window.tracker != null ? window.tracker.trackEvent('Show subscription modal', {category: 'Subscription', label: 'check private clan'}) : undefined);
      }
    }
  };
  ClansView.initClass();
  return ClansView;
})());
