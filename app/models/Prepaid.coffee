CocoModel = require './CocoModel'
schema = require 'schemas/models/prepaid.schema'
utils = require '../core/utils'

{ STARTER_LICENSE_COURSE_IDS } = require 'core/constants'

module.exports = class Prepaid extends CocoModel
  @className: "Prepaid"
  urlRoot: '/db/prepaid'

  openSpots: ->
    return @get('maxRedeemers') - @get('redeemers')?.length if @get('redeemers')?
    @get('maxRedeemers')

  usedSpots: ->
    _.size(@get('redeemers'))

  totalSpots: ->
    return @get('maxRedeemers')

  userHasRedeemed: (userID) ->
    for redeemer in @get('redeemers')
      return redeemer.date if redeemer.userID is userID
    return null

  initialize: ->
    @listenTo @, 'add', ->
      maxRedeemers = @get('maxRedeemers')
      if _.isString(maxRedeemers)
        @set 'maxRedeemers', parseInt(maxRedeemers)
    super(arguments...)

  status: ->
    endDate = @get('endDate')
    if endDate and new Date(endDate) < new Date()
      return 'expired'

    startDate = @get('startDate')
    if startDate and new Date(startDate) > new Date()
      return 'pending'

    if @openSpots() <= 0
      return 'empty'

    return 'available'

  typeDescription: ->
    type = @get('type')
    if type == 'starter_license'
      return i18n.t('teacher.starter_license')
    includedCourseIDs = @get('includedCourseIDs')
    if includedCourseIDs
      return i18n.t('teacher.customized_license')+ ': '+ (includedCourseIDs.map (id) -> utils.courseAcronyms[id]).join('+')
    else
      return i18n.t('teacher.full_license')

  typeDescriptionWithTime: ->
    type = @get('type')
    endDate = moment(@get('endDate')).utc().format('ll')
    endAt = "<br>#{i18n.t('teacher.status_enrolled')}"
    endAt = endAt.replace('{{date}}', endDate)
    if type == 'starter_license'
      return i18n.t('teacher.starter_license') + endAt
    includedCourseIDs = @get('includedCourseIDs')
    if includedCourseIDs
      return i18n.t('teacher.customized_license') + ': ' + (includedCourseIDs.map (id) -> utils.courseAcronyms[id]).join('+') + endAt
    else
      return i18n.t('teacher.full_license') + endAt


  redeem: (user, options={}) ->
    options.url = _.result(@, 'url')+'/redeemers'
    options.type = 'POST'
    options.data ?= {}
    options.data.userID = user.id or user
    @fetch(options)

  includesCourse: (course) ->
    courseID = course.get?('name') or course
    if @get('type') is 'starter_license'
      return courseID in (@get('includedCourseIDs') ? [])
    else
      # no includedCourseIDs means full-license, so always return true
      return courseID in (@get('includedCourseIDs') ? [ courseID ])

  revoke: (user, options={}) ->
    options.url = _.result(@, 'url')+'/redeemers'
    options.type = 'DELETE'
    options.data ?= {}
    options.data.userID = user.id or user
    @fetch(options)

  hasBeenUsedByTeacher: (userID) ->
    if @get('creator') is userID and _.detect(@get('redeemers'), { teacherID: undefined })
      return true
    _.detect(@get('redeemers'), { teacherID: userID })
