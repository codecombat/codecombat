// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const utils = require('core/utils');

const SetupAccountPanel = Vue.extend({
  name: 'setup-account-panel',
  template: require('app/templates/core/create-account-modal/setup-account-panel')(),
  data() { return {
    supportEmail: utils.isOzaria ? "<a href='mailto:support@ozaria.com'>support@ozaria.com</a>" : "<a href='mailto:support@codecombat.com'>support@codecombat.com</a>",
    saving: true,
    error: '',
    isCodeCombat: utils.isCodeCombat
  }; },
  computed: {
    inEU() {
      return me.inEU();
    }
  },
  mounted() {
    this.$store.dispatch('modalTeacher/createAccount')
      .catch(e => {
        if (e.i18n) {
          this.error = this.$t(e.i18n)
        } else {
          this.error = e.message
        }
        if (!this.error) {
          this.error = this.$t('loading_error.unknown')
        }
      })
      .then(() => {
        this.saving = false
      })
  },
  methods: {
    clickFinish() {
      console.log('click finish')
      // Save annoucements subscribe info
      return me.fetch({ cache: false })
      .then(() => {
        const emails = _.assign({}, me.get('emails'));
        if (emails.generalNews == null) { emails.generalNews = {}; }
        emails.generalNews.enabled = $('#subscribe-input').is(':checked');
        if (this.inEU) {
          if (emails.teacherNews == null) { emails.teacherNews = {}; }
          emails.teacherNews.enabled = $('#subscribe-input').is(':checked');
          me.set('unsubscribedFromMarketingEmails', !($('#subscribe-input').is(':checked')));
        }
        me.set('emails', emails);
        const jqxhr = me.save();
        if (!jqxhr) {
          console.error(me.validationError);
          throw new Error('Could not save user');
        }
        return new Promise(jqxhr.then)
            .then(() => {
            // Make sure to add conditions if we change this to be used on non-teacher path
              if (window.tracker != null) {
                window.tracker.trackEvent('CreateAccountModal Teacher SetupAccountPanel Finish Clicked', { category: 'Teachers' })
              }
              // I think the block below can go to both coco/ozaria
              if (window.nextURL) {
                window.location.href = window.nextURL
                return
              }
              application.router.navigate('teachers/classes', { trigger: true })
              document.location.reload()
            })
        })
    },

    clickBack() {
      if (window.tracker != null) {
        window.tracker.trackEvent('CreateAccountModal Teacher SetupAccountPanel Back Clicked', {category: 'Teachers'});
      }
      this.$emit('back')
    }
  }
});

module.exports = SetupAccountPanel;
