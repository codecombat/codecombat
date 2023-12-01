// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const forms = require('core/forms')
const utils = require('core/utils')

const TeacherRolePanel = Vue.extend({
  name: 'TeacherRolePanel',
  template: require('app/templates/core/create-account-modal/teacher-role-panel')(),
  data () {
    const formData = _.pick(this.$store.state.modalTeacher.trialRequestProperties, [
      'role',
      'numStudents',
      'notes',
      'referrer',
      'phoneNumber'
    ])
    return _.assign(formData, {
      showRequired: false,
      product: utils.getProductName(),
      isCodeCombat: utils.isCodeCombat
    })
  },

  computed:
    _.assign({},
      Vuex.mapGetters({ trialReqProps: 'modalTeacher/getTrialRequestProperties' }), {
        askForPhoneNumber () {
          return me.showChinaRegistration() || (this.trialReqProps.country === 'United States')
        },
        phoneNumberRequired () {
          return me.showChinaRegistration()
        },
        validPhoneNumber () {
          return !this.phoneNumber || forms.validatePhoneNumber(this.phoneNumber)
        }
      }
    ),

  mounted () {
    return this.$refs.focus.focus()
  },

  methods: {
    clickContinue () {
      // Make sure to add conditions if we change this to be used on non-teacher path
      if (window.tracker != null) {
        window.tracker.trackEvent('CreateAccountModal Teacher TeacherRolePanel Continue Clicked', { category: 'Teachers' })
      }
      const requiredAttrs = _.pick(this, ['role', 'numStudents'].concat(this.phoneNumberRequired ? ['phoneNumber'] : []))
      if (!_.all(requiredAttrs) || !this.validPhoneNumber) {
        this.showRequired = true
        return
      }
      this.commitValues()
      if (window.tracker != null) {
        window.tracker.trackEvent('CreateAccountModal Teacher TeacherRolePanel Continue Success', { category: 'Teachers' })
      }
      // Facebook Pixel tracking for Teacher conversions.
      if (utils.isOzaria) {
        if (window.tracker != null) {
          window.tracker.trackEvent('OzariaUniqueTeacherSignup')
        }
      } else {
        if (window.tracker != null) {
          window.tracker.trackEvent('UniqueTeacherSignup')
        }
      }
      // Google AdWord teacher conversion.
      if (typeof gtag === 'function') {
        gtag('event', 'conversion', { send_to: 'AW-811324643/8dp2CJK6_5QBEOOp74ID' })
      }
      return this.$emit('continue')
    },

    clickBack () {
      this.commitValues()
      if (window.tracker != null) {
        window.tracker.trackEvent('CreateAccountModal Teacher TeacherRolePanel Back Clicked', { category: 'Teachers' })
      }
      return this.$emit('back')
    },

    commitValues () {
      const attrs = _.pick(this, 'role', 'numStudents', 'notes', 'referrer', 'phoneNumber')
      return this.$store.commit('modalTeacher/updateTrialRequestProperties', attrs)
    }
  }
})

module.exports = TeacherRolePanel
