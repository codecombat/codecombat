/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ShareLicensesModal
require('app/styles/teachers/share-licenses-modal.sass')
const ModalView = require('views/core/ModalView')
const store = require('core/store')
const ShareLicensesStoreModule = require('./ShareLicensesStoreModule')

module.exports = (ShareLicensesModal = (function () {
  ShareLicensesModal = class ShareLicensesModal extends ModalView {
    static initClass () {
      this.prototype.id = 'share-licenses-modal'
      this.prototype.template = require('app/templates/teachers/share-licenses-modal')
      this.prototype.events = {}
    }

    constructor (options) {
      if (!options) {
        options = {}
      }
      super(options)
      this.shareLicensesComponent = null
      store.registerModule('modal', ShareLicensesStoreModule)
      store.dispatch('modal/setPrepaid', options.prepaid.attributes)
    }

    afterRender () {
      const target = this.$el.find('#share-licenses-component')
      if (this.shareLicensesComponent) {
        return target.replaceWith(this.shareLicensesComponent.$el)
      } else {
        this.shareLicensesComponent = new ShareLicensesComponent({
          el: target[0],
          store
        })
        return this.shareLicensesComponent.$on('setJoiners', (prepaidID, joiners) => {
          return this.trigger('setJoiners', prepaidID, joiners)
        })
      }
    }

    destroy () {
      this.shareLicensesComponent.$destroy()
      return super.destroy(...arguments)
    }
  }
  ShareLicensesModal.initClass()
  return ShareLicensesModal
})())

const ShareLicensesComponent = Vue.extend({
  name: 'ShareLicensesComponent',
  template: require('app/templates/teachers/share-licenses-component')(),
  storeModule: ShareLicensesStoreModule,
  data () {
    return {
      me,
      teacherSearchInput: ''
    }
  },
  computed: _.assign({}, Vuex.mapGetters({ prepaid: 'modal/prepaid', error: 'modal/error', rawJoiners: 'modal/rawJoiners' })),
  watch: {
    teacherSearchInput () {
      return this.$store.commit('modal/setError', '')
    }
  },
  components: {
    'share-licenses-joiner-row': require('./ShareLicensesJoinerRow')
  },
  created () {},
  destroyed () {
    this.$store.commit('modal/clearData')
    return this.$store.unregisterModule('modal')
  },
  methods: {
    addTeacher () {
      return this.$store.dispatch('modal/addTeacher', this.teacherSearchInput).then(() => {
        // Send an event back to backbone-land so it can update its model
        return this.$emit('setJoiners', this.prepaid._id, this.rawJoiners)
      })
    },
    revokeJoiner (prepaidID, joiner) {
      return this.$store.dispatch('modal/revokeTeacher', { prepaidID, userID: joiner._id }).then(() => {
        return this.$emit('setJoiners', prepaidID, this.rawJoiners)
      })
    },
    setJoinerMaxRedeemers (prepaidID, joiner, maxRedeemers) {
      return this.$store.dispatch('modal/setJoinerMaxRedeemers', { prepaidID, userID: joiner._id, maxRedeemers }).then(() => {
        return this.$emit('setJoiners', prepaidID, this.rawJoiners)
      })
    }
  }
})
