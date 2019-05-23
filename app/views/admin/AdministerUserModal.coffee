_ = require 'lodash'
require('app/styles/admin/administer-user-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/admin/administer-user-modal'
User = require 'models/User'
Prepaid = require 'models/Prepaid'
StripeCoupons = require 'collections/StripeCoupons'
forms = require 'core/forms'
Prepaids = require 'collections/Prepaids'
Classrooms = require 'collections/Classrooms'
TrialRequests = require 'collections/TrialRequests'
fetchJson = require('core/api/fetch-json')
api = require 'core/api'

# TODO: the updateAdministratedTeachers method could be moved to an afterRender lifecycle method.
# TODO: Then we could use @render in the finally method, and remove the repeated use of both of them through the file.

module.exports = class AdministerUserModal extends ModalView
  id: 'administer-user-modal'
  template: template

  events:
    'click #save-changes': 'onClickSaveChanges'
    'click #create-payment-btn': 'onClickCreatePayment'
    'click #add-seats-btn': 'onClickAddSeatsButton'
    'click #destudent-btn': 'onClickDestudentButton'
    'click #deteacher-btn': 'onClickDeteacherButton'
    'click #reset-progress-btn': 'onClickResetProgressButton'
    'click .update-classroom-btn': 'onClickUpdateClassroomButton'
    'click .add-new-courses-btn': 'onClickAddNewCoursesButton'
    'click .user-link': 'onClickUserLink'
    'click #verified-teacher-checkbox': 'onClickVerifiedTeacherCheckbox'
    'click .edit-prepaids-info-btn': 'onClickEditPrepaidsInfoButton'
    'click .cancel-prepaid-info-edit-btn': 'onClickCancelPrepaidInfoEditButton'
    'click .save-prepaid-info-btn': 'onClickSavePrepaidInfo'
    'click #school-admin-checkbox': 'onClickSchoolAdminCheckbox'
    'click #edit-school-admins-link': 'onClickEditSchoolAdmins'
    'submit #teacher-search-form': 'onSubmitTeacherSearchForm'
    'click .add-administer-teacher': 'onClickAddAdministeredTeacher'
    'click #clear-teacher-search-button': 'onClearTeacherSearchResults'
    'click #teacher-search-button': 'onSubmitTeacherSearchForm'
    'click .remove-teacher-button': 'onClickRemoveAdministeredTeacher'

  initialize: (options, @userHandle) ->
    @user = new User({_id:@userHandle})
    @supermodel.trackRequest @user.fetch({cache: false})
    @coupons = new StripeCoupons()
    @supermodel.trackRequest @coupons.fetch({cache: false})
    @prepaids = new Prepaids()
    @supermodel.trackRequest @prepaids.fetchByCreator(@userHandle, { data: {includeShared: true} })
    @listenTo @prepaids, 'sync', =>
      @prepaids.each (prepaid) =>
        if prepaid.loaded and not prepaid.creator
          prepaid.creator = new User()
          @supermodel.trackRequest prepaid.creator.fetchCreatorOfPrepaid(prepaid)
    @classrooms = new Classrooms()
    @supermodel.trackRequest @classrooms.fetchByOwner(@userHandle)
    @trialRequests = new TrialRequests()
    @supermodel.trackRequest @trialRequests.fetchByApplicant(@userHandle)
    @timeZone = if features?.chinaInfra then 'Asia/Shanghai' else 'America/Los_Angeles'

  onLoaded: ->
    # TODO: Figure out a better way to expose this info, perhaps User methods?
    stripe = @user.get('stripe') or {}
    @free = stripe.free is true
    @freeUntil = _.isString(stripe.free)
    @freeUntilDate = if @freeUntil then stripe.free else new Date().toISOString()[...10]
    @currentCouponID = stripe.couponID
    @none = not (@free or @freeUntil or @coupon)
    @trialRequest = @trialRequests.first()
    @prepaidTableState={}
    @foundTeachers = []
    @administratedTeachers = []
    @trialRequests = new TrialRequests()
    @supermodel.trackRequest @trialRequests.fetchByApplicant(@userHandle)

    super()

  onClickCreatePayment: ->
    service = @$('#payment-service').val()
    amount = parseInt(@$('#payment-amount').val())
    amount = 0 if isNaN(amount)
    gems = parseInt(@$('#payment-gems').val())
    gems = 0 if isNaN(gems)
    if _.isEmpty(service)
      alert('Service cannot be empty')
      return
    else if amount < 0
      alert('Payment cannot be negative')
      return
    else if gems < 0
      alert('Gems cannot be negative')
      return

    data = {
      purchaser: @user.get('_id')
      recipient: @user.get('_id')
      service: service
      created: new Date().toISOString()
      gems: gems
      amount: amount
      description: @$('#payment-description').val()
    }
    $.post('/db/payment/admin', data, => @hide())

  onClickSaveChanges: ->
    stripe = _.clone(@user.get('stripe') or {})
    delete stripe.free
    delete stripe.couponID
    selection = @$el.find('input[name="stripe-benefit"]:checked').val()
    dateVal = @$el.find('#free-until-date').val()
    couponVal = @$el.find('#coupon-select').val()
    switch selection
      when 'free' then stripe.free = true
      when 'free-until' then stripe.free = dateVal
      when 'coupon' then stripe.couponID = couponVal
    @user.set('stripe', stripe)

    newGems = parseInt(@$('#stripe-add-gems').val())
    newGems = 0 if isNaN(newGems)
    if newGems > 0
      purchased = _.clone(@user.get('purchased') ? {})
      purchased.gems ?= 0
      purchased.gems += newGems
      @user.set('purchased', purchased)

    options = {}
    options.success = => @hide()
    @user.patch(options)

  onClickAddSeatsButton: ->
    attrs = forms.formToObject(@$('#prepaid-form'))
    attrs.maxRedeemers = parseInt(attrs.maxRedeemers)
    return unless _.all(_.values(attrs))
    return unless attrs.maxRedeemers > 0
    return unless attrs.endDate and attrs.startDate and attrs.endDate > attrs.startDate
    attrs.endDate = attrs.endDate + " " + "23:59"   # Otherwise, it ends at 12 am by default which does not include the date indicated
    attrs.startDate = moment.timezone.tz(attrs.startDate, @timeZone ).toISOString()
    attrs.endDate = moment.timezone.tz(attrs.endDate, @timeZone).toISOString()
    _.extend(attrs, {
      type: 'course'
      creator: @user.id
      properties:
        adminAdded: me.id
    })
    prepaid = new Prepaid(attrs)
    prepaid.save()
    @state = 'creating-prepaid'
    @renderSelectors('#prepaid-form')
    @listenTo prepaid, 'sync', ->
      @state = 'made-prepaid'
      @renderSelectors('#prepaid-form')

  onClickDestudentButton: (e) ->
    button = @$(e.currentTarget)
    button.attr('disabled', true).text('...')
    Promise.resolve(@user.destudent())
    .then =>
      button.remove()
    .catch (e) =>
      button.attr('disabled', false).text('Destudent')
      noty {
        text: e.message or e.responseJSON?.message or e.responseText or 'Unknown Error'
        type: 'error'
      }
      if e.stack
        throw e

  onClickDeteacherButton: (e) ->
    button = @$(e.currentTarget)
    button.attr('disabled', true).text('...')
    Promise.resolve(@user.deteacher())
    .then =>
      button.remove()
    .catch (e) =>
      button.attr('disabled', false).text('Destudent')
      noty {
        text: e.message or e.responseJSON?.message or e.responseText or 'Unknown Error'
        type: 'error'
      }
      if e.stack
        throw e

  onClickResetProgressButton: ->
    if confirm("Really RESET this person's progress?")
      api.users.resetProgress({ userID: @user.id})

  onClickUpdateClassroomButton: (e) ->
    classroom = @classrooms.get(@$(e.currentTarget).data('classroom-id'))
    if confirm("Really update #{classroom.get('name')}?")
      Promise.resolve(classroom.updateCourses())
      .then =>
        noty({text: 'Updated classroom courses.'})
        @renderSelectors('#classroom-table')
      .catch ->
        noty({text: 'Failed to update classroom courses.', type: 'error'})

  onClickAddNewCoursesButton: (e) ->
    classroom = @classrooms.get(@$(e.currentTarget).data('classroom-id'))
    if confirm("Really update #{classroom.get('name')}?")
      Promise.resolve(classroom.updateCourses({data: {addNewCoursesOnly: true}}))
      .then =>
        noty({text: 'Updated classroom courses.'})
        @renderSelectors('#classroom-table')
      .catch ->
        noty({text: 'Failed to update classroom courses.', type: 'error'})

  onClickUserLink: (e) ->
    userID = @$(e.target).data('user-id')
    @openModalView new AdministerUserModal({}, userID) if userID

  userIsVerifiedTeacher: () ->
    @user.get('verifiedTeacher')

  onClickVerifiedTeacherCheckbox: (e) ->
    checked = @$(e.target).prop('checked')
    @userSaveState = 'saving'
    @render()
    fetchJson("/db/user/#{@user.id}/verifiedTeacher", {
      method: 'PUT',
      json: checked
    }).then (res) =>
      @userSaveState = 'saved'
      @user.set('verifiedTeacher', res.verifiedTeacher)
      @render()
      setTimeout((()=>
        @userSaveState = null
        @render()
      ), 2000)
    null

  onClickEditPrepaidsInfoButton: (e) ->
    prepaidId=@$(e.target).data('prepaid-id')
    @prepaidTableState[prepaidId] = 'editMode'
    @renderSelectors('#'+prepaidId)

  onClickCancelPrepaidInfoEditButton: (e) ->
    @prepaidTableState[@$(e.target).data('prepaid-id')] = 'viewMode'
    @renderSelectors('#'+@$(e.target).data('prepaid-id'))

  onClickSavePrepaidInfo: (e) ->
    prepaidId= @$(e.target).data('prepaid-id')  
    prepaidStartDate= @$el.find('#'+'startDate-'+prepaidId).val()
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

  userIsSchoolAdmin: -> @user.isSchoolAdmin()

  onClickSchoolAdminCheckbox: (e) ->
    checked = @$(e.target).prop('checked')
    cancelled = false
    if checked
      unless window.confirm("ENABLE school administator for #{@user.get('email') || @user.broadName()}?")
        cancelled = true
    else
      unless window.confirm("DISABLE school administator for #{@user.get('email') || @user.broadName()}?")
        cancelled = true
    if cancelled
      e.preventDefault()
      @userSaveState = null
      @render()
      return

    @userSaveState = 'saving'
    @render()
    fetchJson("/db/user/#{@user.id}/schoolAdministrator", {
      method: 'PUT',
      json: {
        schoolAdministrator: checked
      }
    }).then (res) =>
      @userSaveState = 'saved'
      @user.fetch({cache: false}).then => @render()
    null

  onClickEditSchoolAdmins: (e) ->
    if typeof @editingSchoolAdmins is 'undefined'
      administrated = @user.get('administratedTeachers')

      if administrated?.length
        api.users.fetchByIds({
          fetchByIds: administrated
          teachersOnly: true
          includeTrialRequests: true
        }).then (teachers) =>
          @administratedTeachers = teachers or []
          @updateAdministratedTeachers()
        .catch (jqxhr) =>
          errorString = "There was an error getting existing administratedTeachers, see the console"
          @userSaveState = errorString
          @render()
          console.error errorString, jqxhr

    @editingSchoolAdmins = !@editingSchoolAdmins
    @render()

  onClickAddAdministeredTeacher: (e) ->
    teacher = _.find @foundTeachers, (t) -> t._id is $(e.target).closest('tr').data('user-id')
    @foundTeachers = _.filter @foundTeachers, (t) -> t._id isnt teacher._id
    @render()

    fetchJson("/db/user/#{@user.id}/schoolAdministrator/administratedTeacher", {
      method: 'POST',
      json: {
        administratedTeacherId: teacher._id
      }
    }).then (res) =>
      @administratedTeachers.push(teacher)
    .catch (jqxhr) =>
      errorString = "There was an error adding teacher, see the console"
      @userSaveState = errorString
      console.error errorString, jqxhr
      @render()
    .finally =>
      @updateAdministratedTeachers()
    null

  onClickRemoveAdministeredTeacher: (e) ->
    teacher = $(e.target).closest('tr').data('user-id')
    @render()

    fetchJson("/db/user/#{@user.id}/schoolAdministrator/administratedTeacher/#{teacher}", {
      method: 'DELETE'
    }).then (res) =>
      @administratedTeachers = @administratedTeachers.filter (t) -> t._id isnt teacher
      @updateAdministratedTeachers()
    null

  onSearchRequestSuccess: (teachers) =>
    forms.enableSubmit(@$('#teacher-search-button'))

    # Filter out the existing administrated teachers and themselves:
    existingTeachers = _.pluck(@administratedTeachers, '_id')
    existingTeachers.push(@user.id)
    @foundTeachers = _.filter(teachers, (teacher) -> teacher._id not in existingTeachers)

    result = _.map(@foundTeachers, (teacher) ->
      "
        <tr data-user-id='#{teacher._id}'>
          <td>
            <button class='add-administer-teacher'>Add</button>
          </td>
          <td><code>#{teacher._id}</code></td>
          <td>#{_.escape(teacher.name or 'Anonymous')}</td>
          <td>#{_.escape(teacher.email)}</td>
          <td>#{teacher.firstName or 'No first name'}</td>
          <td>#{teacher.lastName or 'No last name'}</td>
          <td>#{teacher.schoolName or 'Other'}</td>
          <td>Verified teacher: #{teacher.verifiedTeacher or 'false'}</td>
        </tr>
      "
    )

    result = "<table class=\"table\">#{result.join('\n')}</table>"
    @$el.find('#teacher-search-result').html(result)

  onSearchRequestFailure: (jqxhr, status, error) =>
    return if @destroyed
    forms.enableSubmit(@$('#teacher-search-button'))
    console.warn "There was an error looking up #{@lastTeacherSearchValue}:", error

  onClearTeacherSearchResults: (e) ->
    @$el.find('#teacher-search-result').html('')

  onSubmitTeacherSearchForm: (e) ->
    @userSaveState = null
    e.preventDefault()
    forms.disableSubmit(@$('#teacher-search-button'))

    $.ajax
      type: 'GET',
      url: '/db/user'
      data: {
        adminSearch: @$el.find('#teacher-search').val()
      }
      success: @onSearchRequestSuccess
      error: @onSearchRequestFailure

  updateAdministratedTeachers: () ->
    schools = @administratedSchools(@administratedTeachers)
    schoolNames = Object.keys(schools)

    result = _.map(schoolNames, (schoolName) ->
      teachers = _.map(schools[schoolName], (teacher) ->
        return "
          <tr data-user-id='#{teacher._id}'>
            <td>#{teacher.firstName} #{teacher.lastName}</td>
            <td>#{teacher.role}</td>
            <td>#{teacher.email}</td>
            <td><button class='btn btn-primary btn-large remove-teacher-button'>Remove</button></td>
          </tr>
        "
      )

      return "
        <tr>
          <th>#{schoolName}</th>
          #{teachers.join('\n')}
        </tr>
      "
    )

    result = "<table class=\"table\">#{result.join('\n')}</table>"
    @$el.find('#school-admin-result').html(result)

  administratedSchools: (teachers) ->
    schools = {}
    _.forEach teachers, (teacher) =>
      school = teacher?._trialRequest?.organization or "Other"
      if not schools[school]
        schools[school] = [teacher]
      else
        schools[school].push(teacher)

    schools

