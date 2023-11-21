/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ShareLicensesJoinerRow;
const store = require('core/store');
const api = require('core/api');
const ShareLicensesStoreModule = require('./ShareLicensesStoreModule');
const User = require('models/User');

module.exports = (ShareLicensesJoinerRow = {
  name: 'share-licenses-joiner-row',
  template: require('app/templates/teachers/share-licenses-joiner-row')(),
  storeModule: ShareLicensesStoreModule,
  props: {
    joiner: {
      type: Object,
      default() { return {}; }
    },
    prepaid: {
      type: Object,
      default() {
        return {joiners: []};
      }
    }
  },
  created() {},
  data() {
    return {
      me,
      editing: false,
      maxRedeemers: this.joiner.maxRedeemers
    };
  },
  computed: {
    broadName() {
      return (new User(this.joiner)).broadName();
    }
  },
  components: {},
  methods:
    {
      saveJoiner() {
        this.$emit('setJoinerMaxRedeemers', this.prepaid._id, this.joiner, this.maxRedeemers);
        return this.editing = false;
      },

      editJoiner() {
        return this.editing = true;
      },

      revokeTeacher() {
        // coco version can be applied for both, because this code
        // doesn't run in Ozaria anyway
        if (this.joiner.licensesUsed > 0) {
          return noty({
            text: $.i18n.t('share_licenses.teacher_delete_warning'),
            layout: 'center',
            type: 'warning',
            buttons: [
              {
                addClass: 'btn btn-primary',
                text: 'Ok',
                onClick: $noty => {
                  this.$emit('revokeJoiner', this.prepaid._id, this.joiner);
                  return $noty.close();
                }
              },
              {
                addClass: 'btn btn-danger',
                text: 'Cancel',
                onClick: $noty => {
                  return $noty.close();
                }
              }
            ]});
        } else {
          return this.$emit('revokeJoiner', this.prepaid._id, this.joiner);
        }
      }
    }
});
