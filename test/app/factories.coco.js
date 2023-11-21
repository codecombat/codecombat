/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Level = require('models/Level');
const Levels = require('collections/Levels');
const Course = require('models/Course');
const Courses = require('collections/Courses');
const Campaign = require('models/Campaign');
const User = require('models/User');
const Classroom = require('models/Classroom');
const LevelSession = require('models/LevelSession');
const CourseInstance = require('models/CourseInstance');
const Achievement = require('models/Achievement');
const EarnedAchievement = require('models/EarnedAchievement');
const ThangType = require('models/ThangType');
const Users = require('collections/Users');
const Prepaid = require('models/Prepaid');
const LevelComponent = require('models/LevelComponent');
const LevelSystem = require('models/LevelSystem');

const makeVersion = () => ({
  major: 0,
  minor: 0,
  isLatestMajor: true,
  isLatestMinor: true
});

module.exports = {

  makeCourse(attrs, sources) {
    if (sources == null) { sources = {}; }
    const _id = _.uniqueId('course_');
    attrs = _.extend({}, {
      _id,
      name: _.string.humanize(_id),
      releasePhase: 'released',
      concepts: []
    }, attrs);
    
    if (attrs.campaignID == null) { attrs.campaignID = (sources.campaign != null ? sources.campaign.id : undefined) || _.uniqueId('campaign_'); }
    return new Course(attrs);
  },

  makeCourseObject(attrs, sources) {
    if (sources == null) { sources = {}; }
    sources = _.clone(sources);
    if (sources.campaign) {
      sources.campaign = new Campaign(sources.campaign);
    }
    const course = this.makeCourse(attrs, sources);
    return course.toJSON();
  },

  makeCampaign(attrs, sources) {
    if (sources == null) { sources = {}; }
    const _id = _.uniqueId('campaign_');
    attrs = _.extend({}, {
      _id,
      name: _.string.humanize(_id),
      levels: [this.makeLevel(), this.makeLevel()]
    }, attrs);

    if (sources.levels) {
      const levelsMap = {};
      sources.levels.each(level => levelsMap[level.get('original')] = level.toJSON());
      attrs.levels = levelsMap;
    }

    return new Campaign(attrs);
  },

  makeCampaignObject(attrs, sources) {
    if (sources == null) { sources = {}; }
    sources = _.clone(sources);
    if (sources.levels) {
      sources.levels = new Levels(sources.levels);
    }
    const campaign = this.makeCampaign(attrs, sources);
    return campaign.toJSON();
  },

  makeLevel(attrs) {
    const _id = _.uniqueId('level_');
    attrs = _.extend({}, {
      _id,
      name: _.string.humanize(_id),
      slug: _.string.dasherize(_id),
      original: _id+'_original',
      version: makeVersion()
    }, attrs);
    return new Level(attrs);
  },
    
  makeLevelObject(attrs) {
    const level = this.makeLevel(attrs);
    return level.toJSON();
  },
  
  makeUser(attrs, sources) {
    if (sources == null) { sources = {}; }
    const _id = _.uniqueId('user_');
    attrs = _.extend({
      _id,
      permissions: [],
      email: _id+'@email.com',
      anonymous: false,
      name: _.string.humanize(_id)
    }, attrs);
    
    if (sources.prepaid) {
      attrs.products = [sources.prepaid.convertToProduct()];
    }
    
    return new User(attrs);
  },
  
  makeClassroom(attrs, sources) {
    let courseAttrs;
    let course;
    if (sources == null) { sources = {}; }
    let levels = sources.levels || []; // array of Levels collections
    let courses = sources.courses || new Courses();
    let members = sources.members || new Users();
  
    const _id = _.uniqueId('classroom_');
    attrs = _.extend({}, {
      _id,
      name: _.string.humanize(_id),
      aceConfig: { language: 'python' }
    }, attrs);
  
    // populate courses
    if (!attrs.courses) {
      courses = sources.courses || new Courses();
      attrs.courses = ((() => {
        const result = [];
        for (course of Array.from(courses.models)) {           result.push(course.pick('_id'));
        }
        return result;
      })());
    }
  
    // populate levels
    for ([courseAttrs, levels] of Array.from(_.zip(attrs.courses, levels))) {
      if (!courseAttrs) { break; }
      if (course == null) { course = this.makeCourse(); }
      if (levels == null) { levels = new Levels(); }
      courseAttrs.levels = (Array.from(levels.models).map((level) => level.pick('_id', 'slug', 'name', 'original', 'primerLanguage', 'type', 'practice')));
    }
  
    // populate members
    if (!attrs.members) {
      members = members || new Users();
      attrs.members = (Array.from(members.models).map((member) => member.id));
    }
  
    return new Classroom(attrs);
  },
  
  makeLevelSession(attrs, sources) {
    if (sources == null) { sources = {}; }
    const level = sources.level || this.makeLevel();
    const creator = sources.creator || this.makeUser();
    attrs = _.extend({}, {
      level: {
        original: level.get('original'),
        majorVersion: 1
      },
      creator: creator.id,
    }, attrs);
    if (level.get('primerLanguage')) { attrs.level.primerLanguage = level.get('primerLanguage'); }
    return new LevelSession(attrs);
  },
  
  makeCourseInstance(attrs, sources) {
    if (sources == null) { sources = {}; }
    const _id = _.uniqueId('course_instance_');
    const course = sources.course || this.makeCourse();
    const classroom = sources.classroom || this.makeClassroom();
    const owner = sources.owner || this.makeUser();
    const members = sources.members || new Users();
    attrs = _.extend({}, {
      _id,
      courseID: course.id,
      classroomID: classroom.id,
      ownerID: owner.id,
      members: members.pluck('_id')
    }, attrs);
    return new CourseInstance(attrs);
  },
    
  makeLevelCompleteAchievement(attrs, sources) {
    if (sources == null) { sources = {}; }
    const _id = _.uniqueId('achievement_');
    const level = sources.level || this.makeLevel();
    attrs = _.extend({}, {
      _id,
      name: _.string.humanize(_id),
      query: {
        'state.complete': true,
        'level.original': level.get('original')
      },
      rewards: { gems: 10 },
      worth: 20
    }, attrs);
    return new Achievement(attrs);
  },
    
  makeEarnedAchievement(attrs, sources) {
    if (sources == null) { sources = {}; }
    const _id = _.uniqueId('earned_achievement_');
    const achievement = sources.achievement || this.makeLevelCompleteAchievement();
    const user = sources.user || this.makeUser();
    attrs = _.extend({}, {
      _id,
      "achievement": achievement.id,
      "user": user.id,
      "earnedRewards": _.clone(achievement.get('rewards')),
      "earnedPoints": achievement.get('worth'),
      "achievementName": achievement.get('name'),
      "notified": true
    }, attrs);
    return new EarnedAchievement(attrs);
  },
    
  makeThangType(attrs) {
    const _id = _.uniqueId('thang_type_');
    attrs = _.extend({}, {
      _id,
      name: _.string.humanize(_id),
      version: makeVersion(),
      original: _id
    }, attrs);
    return new ThangType(attrs);
  },
    
  makePayment(attrs, sources) {
    if (sources == null) { sources = {}; }
    const _id = _.uniqueId('payment_');
    attrs = _.extend({}, {
      _id
    }, attrs);
    return new ThangType(attrs);
  },

  makePrepaid(attrs, sources) {
    if (sources == null) { sources = {}; }
    const _id = _.uniqueId('prepaid_');
    attrs = _.extend({}, {
      _id,
      type: 'course',
      maxRedeemers: 10,
      endDate: moment().add(1, 'month').toISOString(),
      startDate: moment().subtract(1, 'month').toISOString()
    }, attrs);
    
    if (!attrs.redeemers) {
      const redeemers = sources.redeemers || new Users();
      attrs.redeemers = (Array.from(redeemers.models).map((redeemer) => ({
        userID: redeemer.id,
        date: moment().subtract(1, 'month').toISOString()
      })));
    }
    
    return new Prepaid(attrs);
  },
    
  makeTrialRequest(attrs, sources) {
    if (sources == null) { sources = {}; }
    const _id = _.uniqueId('trial_request_');
    return attrs = _.extend({}, {
      _id,
      properties: {
        firstName: 'Mr',
        lastName: 'Professorson',
        name: 'Mr Professorson',
        email: 'an@email.com',
        phoneNumber: '555-555-5555',
        organization: 'Greendale',
        district: 'Green District'
      }
    }, attrs);
  },
    
  makeLevelComponent(attrs, sources) {
    if (sources == null) { sources = {}; }
    const _id = _.uniqueId('level_component_');
    attrs = _.extend({}, {
      _id,
      system: 'action',
      codeLanguage: 'coffeescript',
      name: _.uniqueId('Level Component '),
      version: makeVersion(),
      original: _id
    }, attrs);
    return new LevelComponent(attrs);
  },

  makeLevelSystem(attrs, sources) {
    if (sources == null) { sources = {}; }
    const _id = _.uniqueId('level_system_');
    attrs = _.extend({}, {
      _id,
      codeLanguage: 'coffeescript',
      name: _.uniqueId('Level System '),
      version: makeVersion(),
      original: _id
    }, attrs);
    return new LevelSystem(attrs);
  }
      
    
};
  
