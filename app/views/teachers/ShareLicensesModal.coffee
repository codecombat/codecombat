ModalView = require 'views/core/ModalView'
State = require 'models/State'
TrialRequests = require 'collections/TrialRequests'
forms = require 'core/forms'
store = require('core/store')
ShareLicensesStoreModule = require('./ShareLicensesStoreModule')

# module.exports = class ShareLicensesModal extends ModalView
#   id: 'share-licenses-modal'
#   template: require 'templates/core/vue-modal-wrapper'
#   events: {}
#   initialize: (options={}) ->
#     @shareLicensesComponent = null
#     store.registerModule('modal', ShareLicensesStoreModule)
#     store.dispatch('modal/setPrepaid', options.prepaid.attributes)
#   afterRender: ->
#     target = @$el.find('#modal-wrapper')
#     if @shareLicensesComponent
#       target.replaceWith(@shareLicensesComponent.$el)
#     else
#       @shareLicensesComponent = new ShareLicensesComponent({
#         el: target[0]
#         store
#       })
#       @shareLicensesComponent.$on 'setJoiners', (prepaidID, joiners) =>
#         @trigger 'setJoiners', prepaidID, joiners
#   destroy: ->
#     @shareLicensesComponent.$destroy()
#     super(arguments...)

module.exports = ShareLicensesComponent = Vue.extend
  # name: 'share-licenses-modal'
  template: require('templates/teachers/share-licenses-modal')()
  storeModule: ShareLicensesStoreModule
  props:
    prepaid:
      type: Object
  data: ->
    me: me
    teacherSearchInput: ''
  computed: _.assign({}, Vuex.mapGetters(prepaid: 'modal/prepaid', error: 'modal/error', rawJoiners: 'modal/rawJoiners'))
  watch:
    teacherSearchInput: ->
      @$store.commit('modal/setError', '')
  components:
    'share-licenses-joiner-row': require('./ShareLicensesJoinerRow')
  methods:
    addTeacher: ->
      @$store.dispatch('modal/addTeacher', @teacherSearchInput).then =>
        # Send an event back to backbone-land so it can update its model
        @$emit 'setJoiners', @prepaid._id, @rawJoiners
  created: ->
    store.registerModule('modal', ShareLicensesStoreModule)
    store.dispatch('modal/setPrepaid', @$options.propsData.prepaid.attributes)
  destroyed: ->
    @$store.commit('modal/clearData')
    @$store.unregisterModule('modal')
