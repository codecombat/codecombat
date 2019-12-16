Levels = require 'collections/Levels'
utils = require 'core/utils'

# Returns whether a user has started a course as well as if they've completed
# all the required levels in the course.
#
# @param {Object<key=string, value=bool> | undefined} userLevels - Key value store of level original and completion state.
# @param {Set<string>} levelsInCourse - *Required* level originals in the course.
# @return {[bool, bool, int]} - user started value, allcomplete state and total levels completed.
hasUserCompletedCourse = (userLevels, levelsInCourse) ->
  userStarted = false
  allComplete = true
  completed = 0
  userLevelsSeen = 0
  for level, complete of userLevels when levelsInCourse.has level
    userStarted = true
    if complete
      completed++
    else
      allComplete = false
    userLevelsSeen++
  allComplete = false unless userStarted

  [userStarted, allComplete and userLevelsSeen == levelsInCourse.size, completed]

module.exports =
  # Result: Each course instance gains a property, numCompleted, that is the
  #   number of students in that course instance who have completed ALL of
  #   the levels in that course
  calculateDots: (classrooms, courses, courseInstances) ->
    userLevelsCompleted = {}
    sessions = _.flatten (classroom.sessions?.models || [] for classroom in classrooms.models)
    for session in sessions
      user = session.get 'creator'
      userLevelsCompleted[user] ?= {}
      level = session.get('level').original
      userLevelsCompleted[user][level] ||= session.completed()
    for classroom in classrooms.models
      for course, courseIndex in courses.models
        instance = courseInstances.findWhere({ courseID: course.id, classroomID: classroom.id })
        continue if not instance
        unless classroom.sessions?.loaded
          instance.sessionsLoaded = false
          continue
        instance.sessionsLoaded = true
        instance.numCompleted = 0
        instance.started = false
        levelsInVersionedCourse = new Set (level.get('original') for level in classroom.getLevels({courseID: course.id}).models when not
          (level.get('practice') or level.get('assessment')))

        levelsCompletedByStudents = 0
        for userID in instance.get('members')
          [userStarted, allComplete, levelsCompleted] = hasUserCompletedCourse(userLevelsCompleted[userID], levelsInVersionedCourse)
          levelsCompletedByStudents += levelsCompleted
          instance.started ||= userStarted
          ++instance.numCompleted if allComplete
        instance.percentLevelCompletion = Math.floor(levelsCompletedByStudents / (levelsInVersionedCourse.size * instance.get('members').length) * 100)

  calculateEarliestIncomplete: (classroom, courses, courseInstances, students) ->
    # Loop through all the combinations of things, return the first one that somebody hasn't finished
    for course, courseIndex in courses.models
      instance = courseInstances.findWhere({ courseID: course.id, classroomID: classroom.id })
      continue if not instance
      levels = classroom.getLevels({courseID: course.id})
      for level, levelIndex in levels.models
        userIDs = []
        for user in students.models
          userID = user.id
          sessions = _.filter classroom.sessions.models, (session) ->
            session.get('creator') is userID and session.get('level').original is level.get('original')
          if not _.find(sessions, (s) -> s.completed())
            userIDs.push userID
        if userIDs.length > 0
          users = _.map userIDs, (id) ->
            students.get(id)
          levelNumber = classroom.getLevelNumber(level.get('original'), levelIndex + 1)
          return {
            courseName: utils.i18n(course.attributes, 'name')
            courseNumber: courseIndex + 1
            levelNumber
            levelName: level.get('name')
            users: users
          }
    null

  calculateLatestComplete: (classroom, courses, courseInstances, students, userLevelCompletedMap) ->
    # Loop through all the combinations of things in reverse order, return the level that anyone's finished
    courseModels = courses.models.slice()
    for course, courseIndex in courseModels.reverse() #
      courseIndex = courses.models.length - courseIndex - 1 #compensate for reverse
      instance = courseInstances.findWhere({ courseID: course.id, classroomID: classroom.id })
      continue if not instance
      levels = classroom.getLevels({courseID: course.id})
      levelModels = levels.models.slice()
      for level, levelIndex in levelModels.reverse() #
        levelIndex = levelModels.length - levelIndex - 1 #compensate for reverse
        userIDs = []
        for user in students.models
          userID = user.id
          if userLevelCompletedMap[userID]?[level.get('original').toString()]
            userIDs.push userID
        if userIDs.length > 0
          users = _.map userIDs, (id) ->
            students.get(id)
          levelNumber = classroom.getLevelNumber(level.get('original'), levelIndex + 1)
          return {
            courseName: utils.i18n(course.attributes, 'name')
            courseNumber: courseIndex + 1
            levelNumber
            levelName: level.get('name')
            users: users
          }
    null

  calculateConceptsCovered: (classrooms, courses, campaigns, courseInstances, students) ->
    # Loop through all level/user combination and record
    #   whether they've started, and completed, each concept
    conceptData = {}
    for classroom in classrooms.models
      conceptData[classroom.id] = {}

      for course, courseIndex in courses.models
        levels = classroom.getLevels({courseID: course.id})

        for level in levels.models
          levelID = level.get('original')

          for concept in level.get('concepts')
            unless conceptData[classroom.id][concept]
              conceptData[classroom.id][concept] = { completed: true, started: false }

          for concept in level.get('concepts')
            for userID in classroom.get('members')
              sessions = _.filter classroom.sessions.models, (session) ->
                session.get('creator') is userID and session.get('level').original is levelID

              if _.size(sessions) is 0 # haven't gotten to this level yet, but might have completed others before
                for concept in level.get('concepts')
                  conceptData[classroom.id][concept].completed = false
              if _.size(sessions) > 0 # have gotten to the level and at least started it
                for concept in level.get('concepts')
                  conceptData[classroom.id][concept].started = true
              if not _.find(sessions, (s) -> s.completed()) # level started but not completed
                for concept in level.get('concepts')
                  conceptData[classroom.id][concept].completed = false
    conceptData

  calculateAllProgress: (classrooms, courses, courseInstances, students) ->
    # Loop through all combinations and record:
    #   Completeness for each student/course
    #   Completeness for each student/level
    #   Completeness for each class/course (across all students)
    #   Completeness for each class/level (across all students)

    # class -> course
    #   class -> course -> student
    #   class -> course -> level
    #     class -> course -> level -> student

    progressData = {}
    for classroom in classrooms.models
      progressData[classroom.id] = {}

      for course, courseIndex in courses.models
        instance = courseInstances.findWhere({ courseID: course.id, classroomID: classroom.id })
        if not instance
          progressData[classroom.id][course.id] = { completed: false, started: false }
          continue
        progressData[classroom.id][course.id] = { completed: true, started: false } # to be updated

        levels = classroom.getLevels({courseID: course.id})
        progressData[classroom.id][course.id].levelCount = levels.models.length
        progressData[classroom.id][course.id].userCount = students.models.length
        for level in levels.models
          levelID = level.get('original')
          progressData[classroom.id][course.id][levelID] = {
            completed: students.size() > 0,
            started: false
            numStarted: 0
            # numCompleted: 0
          }
          isOptional = level.get('practice') or level.get('assessment') or level.isLadder()
          sessionsForLevel = _.filter classroom.sessions.models, (session) ->
            session.get('level').original is levelID

          for user in students.models
            userID = user.id
            courseProgress = progressData[classroom.id][course.id]
            courseProgress[userID] ?= { completed: true, started: false, levelsCompleted: 0 } # Only set it the first time through a user
            courseProgress[levelID][userID] = { completed: true, started: false } # These don't matter, will always be set
            sessions = _.filter sessionsForLevel, (session) ->
              session.get('creator') is userID

            courseProgress[levelID][userID].session = (_.find(sessions, (s) -> s.completed()) or _.first(sessions))?.toJSON()

            if _.size(sessions) is 0 # haven't gotten to this level yet, but might have completed others before
              courseProgress.started ||= false unless isOptional #no-op
              courseProgress.completed = false unless isOptional
              courseProgress[userID].started ||= false unless isOptional #no-op
              courseProgress[userID].completed = false unless isOptional
              courseProgress[levelID].started ||= false #no-op
              courseProgress[levelID].completed = false
              courseProgress[levelID][userID].started = false
              courseProgress[levelID][userID].completed = false

            if _.size(sessions) > 0 # have gotten to the level and at least started it
              courseProgress.started = true unless isOptional
              courseProgress[userID].started = true unless isOptional
              courseProgress[levelID].started = true
              courseProgress[levelID][userID].started = true
              dates = _.map(sessions, (s) -> new Date(s.get('changed')))
              courseProgress[levelID][userID].lastPlayed = new Date(Math.max(dates...))
              courseProgress[levelID].numStarted += 1
              courseProgress[levelID][userID].codeConcepts = _.flatten(_.map(sessions, (s) -> s.get('codeConcepts') or []))

            if _.find(sessions, (s) -> s.completed()) # have finished this level
              courseProgress.completed &&= true unless isOptional #no-op
              courseProgress[userID].completed &&= true unless isOptional #no-op
              courseProgress[userID].levelsCompleted += 1 unless isOptional
              courseProgress[levelID].completed &&= true #no-op
              # courseProgress[levelID].numCompleted += 1
              courseProgress[levelID][userID].completed = true
              dates = (new Date(s.get('dateFirstCompleted') || s.get('changed')) for s in sessions)
              courseProgress[levelID][userID].dateFirstCompleted = new Date(Math.max(dates...))
            else # level started but not completed
              courseProgress.completed = false unless isOptional
              courseProgress[userID].completed = false unless isOptional
              if isOptional
                # Weird behavior! Since practice levels are optional, the level is considered 'incomplete'
                # for the class as a whole only if any started-but-not-completed sessions exist
                courseProgress[levelID].completed = false if courseProgress[levelID][userID].started
              else
                courseProgress[levelID].completed = false
              courseProgress[levelID][userID].completed = false
              courseProgress[levelID].dateFirstCompleted = null
              courseProgress[levelID][userID].dateFirstCompleted = null

          if isOptional and courseProgress and not courseProgress[levelID].started
            courseProgress[levelID].completed = false # edge for practice levels, not considered complete if never started either

    _.assign(progressData, progressMixin)
    return progressData

  courseLabelsArray: (courses) ->
    courses.map((course) -> course.acronym())

  hasUserCompletedCourse: hasUserCompletedCourse

progressMixin =
  get: (options={}) ->
    { classroom, course, level, user } = options
    throw new Error "You must provide a classroom" unless classroom
    throw new Error "You must provide a course" unless course
    defaultValue = { completed: false, started: false }
    if options.level
      levelID = level.get('original')
      if options.user
        return @[classroom.id]?[course.id]?[levelID]?[user.id] or defaultValue
      else
        return @[classroom.id]?[course.id]?[levelID] or defaultValue
    else
      if options.user
        return @[classroom.id]?[course.id]?[user.id] or defaultValue
      else
        return @[classroom.id]?[course.id] or defaultValue
