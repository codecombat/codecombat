template = require 'templates/base-flat'
require('vendor/co')
api = require 'core/api'
FlatLayout = require 'core/components/FlatLayout'
store = require('core/store')

PrepaidsAdminView = Vue.extend
  name: 'prepaids-admin-view'
  template: require('templates/admin/prepaids-admin-view')()
  components:
    'flat-layout': FlatLayout
  props: {}
  created: ->
  data: ->
    searchInput: '59162c58e5816532e0e69634'
    prepaids: []
    savedStatus: {}
  computed:
    {}
  methods:
    formatDate: (date) ->
      moment(date).format('dddd, MMM Do, YYYY, h:mma ZZ')
    searchForPrepaid: co.wrap ->
      prepaid = yield api.prepaids.get({ prepaidID: @searchInput })
      @prepaids = [prepaid]
      @savedStatus[prepaid._id] = null
    savePrepaid: co.wrap (prepaid) ->
      console.log "Saving prepaid:", prepaid.endDate
      index = _.findIndex(@prepaids, {_id: prepaid._id})
      try
        result = yield api.prepaids.put({ prepaid })
        console.log result
        console.log "Result from PUT:", result.endDate
        savedPrepaid = yield api.prepaids.get({ prepaidID: prepaid._id })
        console.log "Result from GET:", savedPrepaid.endDate
        Vue.set(@prepaids, index, savedPrepaid)
        Vue.set(@savedStatus, prepaid._id, 'saved')
      catch e
        console.log e
        @savedStatus[prepaid._id] = 'error'

VueWrapper = require('views/core/VueWrapper')
module.exports = VueWrapper.RootComponent(PrepaidsAdminView)
