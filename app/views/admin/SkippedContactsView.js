// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SkippedContactsView;
require('app/styles/admin/skipped-contacts-view.sass');
const RootComponent = require('views/core/RootComponent');
const template = require('app/templates/base-flat');
const co = require('co');
const api = require('core/api');
const FlatLayout = require('core/components/FlatLayout');

const SkippedContactInfo = {
  template: require('app/templates/admin/skipped-contacts/skipped-contact-info')(),
  props: {
    skippedContact: {
      type: Object,
      default() { return {}; }
    },
    user: {
      type: Object,
      default() { return undefined; }
    }
  },
  computed: {
    noteData() {
      // TODO: Clean this up; it's hastily copied/modified from updateCloseIoLeads.js
      // TODO: Figure out how to make this less redundant with that script
      let noteData = "";
      this.skippedContact;
      if (this.skippedContact.trialRequest != null ? this.skippedContact.trialRequest.properties : undefined) {
        const props = this.skippedContact.trialRequest.properties;
        if (props.name) {
          noteData += `${props.name}\n`;
        }
        if (props.email) {
          noteData += `demo_email: ${props.email.toLowerCase()}\n`;
        }
        if (this.skippedContact.trialRequest.created) {
          noteData += `demo_request: ${this.skippedContact.trialRequest.created}\n`;
        }
        if (props.educationLevel) {
          noteData += `demo_educationLevel: ${props.educationLevel.join(', ')}\n`;
        }
        for (var prop of Array.from(props)) {
          if (['email', 'educationLevel', 'created'].indexOf(prop) >= 0) { continue; }
          noteData += `demo_${prop}: ${props[prop]}\n`;
        }
      }

      if (this.user) {
        noteData += `coco_userID: ${this.user._id}\n`;
        if (this.user.firstName) { noteData += `coco_firstName: ${this.user.firstName}\n`; }
        if (this.user.lastName) { noteData += `coco_lastName: ${this.user.lastName}\n`; }
        if (this.user.name) { noteData += `coco_name: ${this.user.name}\n`; }
        if (this.user.emaillower) { noteData += `coco_email: ${this.user.emailLower}\n`; }
        if (this.user.gender) { noteData += `coco_gender: ${this.user.gender}\n`; }
        if (this.user.lastLevel) { noteData += `coco_lastLevel: ${this.user.lastLevel}\n`; }
        if (this.user.role) { noteData += `coco_role: ${this.user.role}\n`; }
        if (this.user.schoolName) { noteData += `coco_schoolName: ${this.user.schoolName}\n`; }
        if (this.user.stats && this.user.stats.gamesCompleted) { noteData += `coco_gamesCompleted: ${this.user.stats.gamesCompleted}\n`; }
        noteData += `coco_preferredLanguage: ${this.user.preferredLanguage || 'en-US'}\n`;
      }
      if (this.numClassrooms) { // TODO compute this
        noteData += `coco_numClassrooms: ${skippedContact.numClassrooms}\n`;
      }
      if (this.numStudents) { // TODO compute this
        noteData += `coco_numStudents: ${skippedContact.numStudents}\n`;
      }
      return noteData;
    },

    // Optional TODO: Reconcile where these kinds of model-y calculations should go (API? the view?)
    queryString() {
      let query;
      if (this.skippedContact.trialRequest) {
        const {
          trialRequest
        } = this.skippedContact;
        const leadName = trialRequest.properties.nces_name || trialRequest.properties.organization || trialRequest.properties.school || trialRequest.properties.district || trialRequest.properties.nces_district || trialRequest.properties.email;
        query = `name:\"${leadName}\"`;
        if (trialRequest.properties.nces_school_id) {
          query = `custom.demo_nces_id:\"${trialRequest.properties.nces_school_id}\"`;
        } else if (trialRequest.properties.nces_district_id) {
          query = `custom.demo_nces_district_id:\"${trialRequest.properties.nces_district_id}\" custom.demo_nces_id:\"\" custom.demo_nces_name:\"\"`;
        }
        return query;
      }
      if (this.skippedContact.zpContact) {
        const {
          zpContact
        } = this.skippedContact;
        query = `name:\"${zpContact.organization}\"`;
        if (zpContact.nces_school_id) {
          query = `custom.demo_nces_id:\"${zpContact.nces_school_id}\"`;
        } else if (zpContact.nces_district_id) {
          query = `custom.demo_nces_district_id:\"${zpContact.nces_district_id}\" custom.demo_nces_id:\"\" custom.demo_nces_name:\"\"`;
        }
        return query;
      }
    },

    queryURL() {
      return "https://app.close.io/search/" + encodeURIComponent(this.queryString);
    }
  },

  methods: {
    onClickArchiveContact(e) {
      const archived = true;
      return this.$store.dispatch('page/archiveContact', {skippedContact: this.skippedContact, archived});
    },
      // @$emit('archiveContact', @skippedContact, archived)
    onClickUnarchiveContact(e) {
      const archived = false;
      return this.$store.dispatch('page/archiveContact', {skippedContact: this.skippedContact, archived});
    }
  }
};
      // @$emit('archiveContact', @skippedContact, archived)

const SkippedContactsComponent = Vue.extend({
  template: require('app/templates/admin/skipped-contacts/skipped-contacts-view')(),
  data() {
    return {
      sortOrder: 'date (descending)',
      showArchived: false,
      showTrialRequestContacts: true,
      showZenProspectContacts: true,
      searchInput: ''
    };
  },
  computed:
    _.assign({},
      Vuex.mapState('page', ['skippedContacts', 'users']),
      Vuex.mapGetters('page', ['numArchivedUsers']), {
      sortedContacts(state) {
        switch (state.sortOrder) {
          case 'date (ascending)':
            return _(state.skippedContacts).sortBy(s => s.dateCreated).value();
          case 'date (descending)':
            return _(state.skippedContacts).sortBy(s => s.dateCreated).reverse().value();
          case 'email':
            return _(state.skippedContacts).sortBy(s => __guard__(s.trialRequest != null ? s.trialRequest.properties : undefined, x => x.email)).value();
          case 'archived':
            return _(state.skippedContacts).sortBy(s => !!s.archived).reverse().value();
          case 'unarchived':
            return _(state.skippedContacts).sortBy(s => !!s.archived).value();
          default:
            return state.skippedContacts;
        }
      }
    }
    ),
  methods: {
    isContactShown(contact) {
      if (!_.isEmpty(this.searchInput)) { return this.matchesFilter(contact); }
      return (this.showArchived || !contact.archived) &&
        ((this.showTrialRequestContacts && contact.trialRequest) ||
         (this.showZenProspectContacts && contact.zpContact));
    },
    matchesFilter(contact) {
      return _.contains(contact.email, this.searchInput);
    }
  },
  components: {
    'skipped-contact-info': SkippedContactInfo,
    'flat-layout': FlatLayout
  },
  created: co.wrap(function*() {
    try {
      const skippedContacts = yield api.skippedContacts.getAll();
      this.$store.commit('page/loadContacts', skippedContacts);
      return yield skippedContacts.map(co.wrap(function*(skippedContact) {
        const userHandle = skippedContact.trialRequest != null ? skippedContact.trialRequest.applicant : undefined;
        if (!userHandle) { return; }
        const user = yield api.users.getByHandle(userHandle);
        return this.$store.commit('page/addUser', { skippedContact , user });
      }.bind(this))
      );
    } catch (e) {
      return this.$store.commit('addPageError', e);
    }
  })
});

const store = require('core/store');

module.exports = (SkippedContactsView = (function() {
  SkippedContactsView = class SkippedContactsView extends RootComponent {
    static initClass() {
      this.prototype.id = 'skipped-contacts-view';
      this.prototype.template = template;
      this.prototype.VueComponent = SkippedContactsComponent;
    }
    vuexModule() { return {
      namespaced: true,
      state: {
        skippedContacts: [],
        users: {}
      },
      actions: {
        archiveContact({ commit, state }, {skippedContact, archived}) {
          const newContact = _.assign({}, skippedContact, {archived});
          return api.skippedContacts.put(newContact).then(() => commit('archiveContact', {skippedContact, archived}));
        }
      },
      mutations: {
        archiveContact(state, { skippedContact, archived }) {
          const index = _.findIndex(state.skippedContacts, s => s._id === skippedContact._id);
          const oldContact = state.skippedContacts[index];
          return Vue.set(state.skippedContacts, index, _.assign({}, oldContact, { archived }));
        },
        addUser(state, { skippedContact, user }) {
          return Vue.set(state.users, skippedContact._id, user);
        },
        loadContacts(state, skippedContacts) {
          return state.skippedContacts = skippedContacts;
        }
      },
      getters: {
        numArchivedUsers(state) {
          return _.countBy(state.skippedContacts, contact => contact.archived)[true];
        }
      }
    }; }
  };
  SkippedContactsView.initClass();
  return SkippedContactsView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}