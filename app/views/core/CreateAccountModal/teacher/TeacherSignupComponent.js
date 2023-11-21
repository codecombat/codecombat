// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let TeacherSignupComponent;
const SchoolInfoPanel = require('./SchoolInfoPanel');
const TeacherRolePanel = require('./TeacherRolePanel');
const SetupAccountPanel = require('./SetupAccountPanel');

module.exports = (TeacherSignupComponent = Vue.extend({
  name: 'teacher-signup-component',
  template: require('app/templates/core/create-account-modal/teacher-signup-component')(),

  created() {
    return this.disableKeyboardClose();
  },

  data() {
    return {
      panelIndex: 0,
      panels: ['school-info-panel', 'teacher-role-panel', 'setup-account-panel'],
      trialRequestAttributes: {}
    };
  },

  computed: {
    panel() { return this.panels[this.panelIndex]; }
  },

  components: {
    'school-info-panel': SchoolInfoPanel,
    'teacher-role-panel': TeacherRolePanel,
    'setup-account-panel': SetupAccountPanel
  },

  methods: {
    onContinue(attributes) {
      this.trialRequestAttributes = _.assign({}, this.trialRequestAttributes, attributes);
      this.panelIndex += 1;
    },

    onBack() {
      if (this.panelIndex === 0) { this.$emit('back') } else { this.panelIndex -= 1 }
    },

    disableKeyboardClose() {
      // NOTE: This uses undocumented API calls and might break in future bootstrap releases
      const modal = $('#create-account-modal').data('bs.modal');
      __guard__(modal != null ? modal.options : undefined, x => x.keyboard = false);
      return __guardMethod__(modal, 'escape', o => o.escape());
    }
  },

  mounted() {}
}));
    // 2020-11-05: Now that we have more Ozaria on the homepage, we don't want to pop it up by default; let them click the banner
    //window.localStorage.setItem('showOzariaEncouragementModal', true)

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