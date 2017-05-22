store = require('core/store')
ShareLicensesStoreModule = require './ShareLicensesStoreModule'
User = require 'models/User'

module.exports = ShareLicensesJoinerRow =
  name: 'share-licenses-joiner-row'
  template: require('templates/teachers/share-licenses-joiner-row')()
  storeModule: ShareLicensesStoreModule
  props:
    joiner:
      type: Object
      default: -> {}
    prepaid:
      type: Object
      default: ->
        joiners: []
  created: ->
  data: ->
    me: me
  computed:
    broadName: ->
      (new User(@joiner)).broadName()
  components: {}
  methods:
    {}
