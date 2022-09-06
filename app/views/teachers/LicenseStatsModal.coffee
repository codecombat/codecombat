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
      loading: true
      redeemers: @redeemers
      removedRedeemers: @removedRedeemers

    userNameRequest = @supermodel.addRequestResource 'user_names', {
      url: '/db/user/-/names'
      data: {ids: redeemerIds.concat(removedRedeemerIds)}
      method: 'POST'
      success: (@nameMap) =>
        @redeemers.forEach(@nameMapping)
        @removedRedeemers.forEach(@nameMapping)
        @propsData.loading = false
        console.log('loading, ',@redeemers, @removedRedeemers)
    }
    userNameRequest.load()

  nameMapping: (r, index, arr) =>
    user = @nameMap[r.userID]
    name = user.firstName + ' ' + user.lastName if user?.firstName
    name ||= user?.name
    name ||= "Anonymous #{opponent.userID.substr(18)}" if user
    name ||= opponent.name
    name ||= '<bad match data>'
    arr[index].name = name

  # render: ->
  #   super()
  #   if @VueComponent
  #     @$el.find("#modal-base-flat").replaceWith(@VueComponent.$el)
  #   else
  #     @VueComponent = new @VueComponent({
  #       el: @$el.find('#modal-base-falt')[0]
  #       propsData: @propsData,
  #     })
  # onLoaded: -> @render()
  destroy: ->
    @onDestroy?()
    super()
