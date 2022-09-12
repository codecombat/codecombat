store = require('core/store')
api = require 'core/api'
ShareLicensesStoreModule = require './ShareLicensesStoreModule'
User = require 'models/User'

module.exports = ShareLicensesJoinerRow =
  name: 'share-licenses-joiner-row'
  template: require('app/templates/teachers/share-licenses-joiner-row')()
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
    me: me,
    editing: false,
    maxRedeemers: @joiner.maxRedeemers
  computed:
    broadName: ->
      (new User(@joiner)).broadName()
  components: {}
  methods:
    {
      saveJoiner: ->
        @$emit 'setJoinerMaxRedeemers', @prepaid._id, @joiner, @maxRedeemers
        this.editing = false

      editJoiner: ->
        this.editing = true

      revokeTeacher: ->
        # coco version can be applied for both, because this code
        # doesn't run in Ozaria anyway
        if @joiner.licensesUsed > 0
          noty
            text: $.i18n.t 'share_licenses.teacher_delete_warning'
            layout: 'center',
            type: 'warning',
            buttons: [
              {
                addClass: 'btn btn-primary',
                text: 'Ok',
                onClick: ($noty) =>
                  @$emit 'revokeJoiner', @prepaid._id, @joiner
                  $noty.close()
              }
              {
                addClass: 'btn btn-danger',
                text: 'Cancel',
                onClick: ($noty) =>
                  $noty.close()
              }
            ]
        else
          @$emit 'revokeJoiner', @prepaid._id, @joiner
    }
