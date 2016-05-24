Level = require 'models/Level'
Course = require 'models/Course'
Courses = require 'collections/Courses'
User = require 'models/User'
Classroom = require 'models/Classroom'
LevelSession = require 'models/LevelSession'
CourseInstance = require 'models/CourseInstance'
Achievement = require 'models/Achievement'
EarnedAchievement = require 'models/EarnedAchievement'
ThangType = require 'models/ThangType'
Users = require 'collections/Users'
Prepaid = require 'models/Prepaid'

module.exports = {

  makeCourse: (attrs, sources={}) ->
    _id = _.uniqueId('course_')
    attrs = _.extend({}, {
      _id: _id
      name: _.string.humanize(_id)
    }, attrs)
    
    attrs.campaignID ?= sources.campaign?.id or _.uniqueId('campaign_')
    return new Course(attrs)
  
  makeLevel: (attrs) ->
    _id = _.uniqueId('level_')
    attrs = _.extend({}, {
      _id: _id
      name: _.string.humanize(_id)
      original: _id+'_original'
      version:
        major: 0
        minor: 0
        isLatestMajor: true
        isLatestMinor: true
    }, attrs)
    return new Level(attrs)
  
  makeUser: (attrs, sources={}) ->
    _id = _.uniqueId('user_')
    attrs = _.extend({
      _id: _id
      permissions: []
      email: _id+'@email.com'
      anonymous: false
      name: _.string.humanize(_id)
    }, attrs)
    
    if sources.prepaid and not attrs.coursePrepaid
      attrs.coursePrepaid = sources.prepaid.pick('_id', 'startDate', 'endDate')
    
    return new User(attrs)
  
  makeClassroom: (attrs, sources={}) ->
    levels = sources.levels or [] # array of Levels collections
    courses = sources.courses or new Courses()
    members = sources.members or new Users()
  
    _id = _.uniqueId('classroom_')
    attrs = _.extend({}, {
      _id: _id,
      name: _.string.humanize(_id)
      aceConfig: { language: 'python' }
    }, attrs)
  
    # populate courses
    if not attrs.courses
      courses = sources.courses or new Courses()
      attrs.courses = (course.pick('_id') for course in courses.models)
  
    # populate levels
    for [courseAttrs, levels] in _.zip(attrs.courses, levels)
      break if not courseAttrs
      course ?= @makeCourse()
      levels ?= new Levels()
      courseAttrs.levels = (level.pick('_id', 'slug', 'name', 'original', 'type') for level in levels.models)
  
    # populate members
    if not attrs.members
      members = members or new Users()
      attrs.members = (member.id for member in members.models)
  
    return new Classroom(attrs)
  
  makeLevelSession: (attrs, sources={}) ->
    level = sources.level or @makeLevel()
    creator = sources.creator or @makeUser()
    attrs = _.extend({}, {
      level:
        original: level.get('original'),
      creator: creator.id,
    }, attrs)
    return new LevelSession(attrs)
  
  makeCourseInstance: (attrs, sources={}) ->
    _id = _.uniqueId('course_instance_')
    course = sources.course or @makeCourse()
    classroom = sources.classroom or @makeClassroom()
    owner = sources.owner or @makeUser()
    members = sources.members or new Users()
    attrs = _.extend({}, {
      _id
      courseID: course.id
      classroomID: classroom.id
      ownerID: owner.id
      members: members.pluck('_id')
    }, attrs)
    return new CourseInstance(attrs)
    
  makeLevelCompleteAchievement: (attrs, sources={}) ->
    _id = _.uniqueId('achievement_')
    level = sources.level or @makeLevel()
    attrs = _.extend({}, {
      _id
      name: _.string.humanize(_id)
      query: {
        'state.complete': true,
        'level.original': level.get('original')
      }
      rewards: { gems: 10 }
      worth: 20
    }, attrs)
    return new Achievement(attrs)
    
  makeEarnedAchievement: (attrs, sources={}) ->
    _id = _.uniqueId('earned_achievement_')
    achievement = sources.achievement or @makeLevelCompleteAchievement()
    user = sources.user or @makeUser()
    attrs = _.extend({}, {
      _id,
      "achievement": achievement.id,
      "user": user.id,
      "earnedRewards": _.clone(achievement.get('rewards')),
      "earnedPoints": achievement.get('worth'),
      "achievementName": achievement.get('name'),
      "notified": true
    }, attrs)
    return new EarnedAchievement(attrs)
    
  makeThangType: (attrs) ->
    _id = _.uniqueId('thang_type_')
    attrs = _.extend({}, {
      _id
      name: _.string.humanize(_id)
    }, attrs)
    return new ThangType(attrs)
    
  makePayment: (attrs, sources={}) ->
    _id = _.uniqueId('payment_')
    attrs = _.extend({}, {
      _id
    }, attrs)
    return new ThangType(attrs)

  makePrepaid: (attrs, sources={}) ->
    _id = _.uniqueId('prepaid_')
    attrs = _.extend({}, {
      _id
      type: 'course'
      maxRedeemers: 10
      endDate: moment().add(1, 'month').toISOString()
      startDate: moment().subtract(1, 'month').toISOString()
    }, attrs)
    
    if not attrs.redeemers
      redeemers = sources.redeemers or new Users()
      attrs.redeemers = ({
        userID: redeemer.id
        date: moment().subtract(1, 'month').toISOString()
      } for redeemer in redeemers.models)
    
    return new Prepaid(attrs)
    
  makeTrialRequest: (attrs, sources={}) ->
    _id = _.uniqueId('trial_request_')
    attrs = _.extend({}, {
      _id
      properties: {
        firstName: 'Mr'
        lastName: 'Professorson'
        name: 'Mr Professorson'
        email: 'an@email.com'
        phoneNumber: '555-555-5555'
        organization: 'Greendale'
      }
    }, attrs)
} 
  

