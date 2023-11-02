ModalComponent = require 'views/core/ModalComponent'
LicenseStatsComponent = require('./components/LicenseStatsModal.vue').default

module.exports = class LicenseStatsModal extends ModalComponent
  id: 'license-stats-modal'
  template: require('app/templates/core/modal-base-flat')
  VueComponent: LicenseStatsComponent

  constructor: (options) ->
    super options
    @prepaid = options.prepaid

    @redeemers = @prepaid.get('redeemers') ? []
    redeemerIds = @redeemers.map((r) =>
      r.userID
    )
    @removedRedeemers = @prepaid.get('removedRedeemers') ? []
    removedRedeemerIds = @removedRedeemers.map((r) =>
      r.userID
    )
    @propsData =
      hide: () => @hide()
      loading: { finished: false }
      prepaid: @prepaid
      redeemers: @redeemers
      removedRedeemers: @removedRedeemers

    @supermodel.resetProgress()
    userNameRequest = @supermodel.addRequestResource 'user_names', {
      url: '/db/user/-/names'
      data: {ids: redeemerIds.concat(removedRedeemerIds)}
      method: 'POST'
      success: (@nameMap) =>
        @redeemers.forEach(@nameMapping)
        @removedRedeemers.forEach(@nameMapping)
        @propsData.loading.finished = true
    }
    userNameRequest.load()

  nameMapping: (r, index, arr) =>
    user = @nameMap[r.userID]
    name = user.firstName if user?.firstName
    name += ' ' + user.lastName if user?.lastName?
    name ||= user?.name
    arr[index].name = name

  destroy: ->
    @onDestroy?()
    super()
