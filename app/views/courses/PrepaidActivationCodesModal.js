_ = require 'lodash'
require('app/styles/admin/administer-user-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/courses/prepaid-activation-codes-modal.pug'
User = require 'models/User'
Prepaid = require 'models/Prepaid'
StripeCoupons = require 'collections/StripeCoupons'
forms = require 'core/forms'
Prepaids = require 'collections/Prepaids'
Classrooms = require 'collections/Classrooms'
TrialRequests = require 'collections/TrialRequests'
fetchJson = require('core/api/fetch-json')
utils = require 'core/utils'
api = require 'core/api'
{ LICENSE_PRESETS } = require 'core/constants'

# TODO: the updateAdministratedTeachers method could be moved to an afterRender lifecycle method.
# TODO: Then we could use @render in the finally method, and remove the repeated use of both of them through the file.

module.exports = class PreapidActivationCodesModal extends ModalView
  id: 'administer-user-modal'
  template: template

  events:
    'click .edit-prepaids-info-btn': 'onClickEditPrepaidsInfoButton'
    'click .cancel-prepaid-info-edit-btn': 'onClickCancelPrepaidInfoEditButton'
    'click .save-prepaid-info-btn': 'onClickSavePrepaidInfo'
    'click #license-type-select>.radio': 'onSelectLicenseType'
    'click #add-seats-btn': 'onClickAddSeatsButton'

  initialize: (options, @classroom) ->
    @user = me
    @supermodel.trackRequest @user.fetch({cache: false})
    @prepaids = new Prepaids()
    @supermodel.trackRequest @prepaids.fetchByCreator(me.get('_id'), { data: {includeShared: true, onlyActivationCodes: true} })
    @listenTo @prepaids, 'sync', =>
      @prepaids.forEach (prepaid) =>
        if prepaid.loaded and not prepaid.creator
          prepaid.creator = new User()
          @supermodel.trackRequest prepaid.creator.fetchCreatorOfPrepaid(prepaid)
    @timeZone = if features?.chinaInfra then 'Asia/Shanghai' else 'America/Los_Angeles'
    @licenseType = 'all'
    @licensePresets = LICENSE_PRESETS
    @utils = utils

  onLoaded: ->
    # TODO: Figure out a better way to expose this info, perhaps User methods?
    @prepaidTableState={}

    super()

  onClickEditPrepaidsInfoButton: (e) ->
    prepaidId=@$(e.target).data('prepaid-id')
    @prepaidTableState[prepaidId] = 'editMode'
    @renderSelectors('#'+prepaidId)

  onClickCancelPrepaidInfoEditButton: (e) ->
    @prepaidTableState[@$(e.target).data('prepaid-id')] = 'viewMode'
    @renderSelectors('#'+@$(e.target).data('prepaid-id'))

  onClickSavePrepaidInfo: (e) ->
    prepaidId= @$(e.target).data('prepaid-id')  
    prepaidEndDate= @$el.find('#'+'endDate-'+prepaidId).val()
    prepaidTotalLicenses=@$el.find('#'+'totalLicenses-'+prepaidId).val()
    @prepaids.each (prepaid) =>
      if (prepaid.get('_id') == prepaidId) 
        #validations
        unless prepaidStartDate and prepaidEndDate and prepaidTotalLicenses
          return 
        if(prepaidStartDate >= prepaidEndDate)
          alert('End date cannot be on or before start date')
          return
        if(prepaidTotalLicenses < (prepaid.get('redeemers') || []).length)
          alert('Total number of licenses cannot be less than used licenses')
          return
        prepaid.set('startDate', moment.timezone.tz(prepaidStartDate, @timeZone).toISOString())
        prepaid.set('endDate',  moment.timezone.tz(prepaidEndDate, @timeZone).toISOString())
        prepaid.set('maxRedeemers', prepaidTotalLicenses)
        options = {}
        prepaid.patch(options)
        @listenTo prepaid, 'sync', -> 
          @prepaidTableState[prepaidId] = 'viewMode'
          @renderSelectors('#'+prepaidId)
        return

  onSelectLicenseType: (e) ->
    @licenseType = $(e.target).parent().children('input').val()
    console.log('select liscense', @licenseType)
    @renderSelectors("#license-type-select")

  onClickAddSeatsButton: ->
    attrs = forms.formToObject(@$('#prepaid-form'))
    attrs.maxRedeemers = parseInt(attrs.maxRedeemers)
    return unless _.all(_.values(attrs))
    return unless attrs.maxRedeemers > 0
    return unless attrs.duration > 0
    return unless attrs.endDate and moment().isBefore(attrs.endDate)
    attrs.endDate = attrs.endDate + " " + "23:59"   # Otherwise, it ends at 12 am by default which does not include the date indicated
    attrs.startDate = moment.timezone.tz(@timeZone ).toISOString()
    attrs.endDate = moment.timezone.tz(attrs.endDate, @timeZone).toISOString()
    days = attrs.duration
    delete attrs.duration

    if attrs.licenseType of @licensePresets
      attrs.includedCourseIDs = @licensePresets[attrs.licenseType]
    return unless attrs.licenseType == 'all' or attrs.includedCourseIDs.length
    delete attrs.licenseType

    _.extend(attrs, {
      type: 'course'
      creator: @user.id
      generateActivationCodes: true
      properties:
        adminAdded: me.id
        classroom: @classroom
        days: days
    })
    prepaid = new Prepaid(attrs)
    prepaid.save()
    @state = 'creating-prepaid'
    @renderSelectors('#prepaid-form')
    @listenTo prepaid, 'sync', ->
      csvContent = 'Code,Expires\n'
      ocode = prepaid.get('code').toUpperCase()
      for code in prepaid.get('redeemers')
        csvContent += "#{ocode.slice(0, 4)}-#{code.code.toUpperCase()}-#{ocode.slice(4)},#{code.date}\n"
      file = new Blob([csvContent], {type: 'text/csv;charset=utf-8'})
      window.saveAs(file, 'ActivationCodes.csv')
      @state = 'made-prepaid'
      @renderSelectors('#prepaid-form')

 