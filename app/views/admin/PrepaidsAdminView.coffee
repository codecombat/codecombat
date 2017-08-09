template = require 'templates/base-flat'
require('vendor/co')
api = require 'core/api'
FlatLayout = require 'core/components/FlatLayout'
store = require('core/store')
utils = require('core/utils')

PrepaidsAdminView = Vue.extend
  name: 'prepaids-admin-view'
  template: require('templates/admin/prepaids-admin-view')()
  components:
    'flat-layout': FlatLayout
  props: {}
  created: ->
    if utils.getQueryVariable('prepaidID')
      @searchInput = utils.getQueryVariable('prepaidID')
      @searchForPrepaid()
  data: ->
    searchInput: ''
    prepaid: {}
    savedStatus: null
  computed:
    {}
  watch: ->
    prepaid: ->
      @savedStatus = null
  methods:
    formatDate: (date) ->
      moment(date).format('dddd, MMM Do, YYYY, h:mma ZZ')
    searchForPrepaid: co.wrap ->
      @prepaid = yield api.prepaids.get({ prepaidID: @searchInput })
      @savedStatus = null
    savePrepaid: co.wrap (prepaid) ->
      console.log "Saving prepaid:", prepaid.endDate
      try
        result = yield api.prepaids.put({ prepaid })
        console.log result
        console.log "Result from PUT:", result.endDate
        savedPrepaid = yield api.prepaids.get({ prepaidID: prepaid._id })
        console.log "Result from GET:", savedPrepaid.endDate
        @prepaid = savedPrepaid
        @savedStatus = 'saved'
        setTimeout =>
          @savedStatus = null
      catch e
        console.log e
        @savedStatus = 'error'

VueWrapper = require('views/core/VueWrapper')
module.exports = VueWrapper.RootComponent(PrepaidsAdminView)
