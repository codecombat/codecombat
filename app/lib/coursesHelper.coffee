Levels = require 'collections/Levels'

module.exports =
  # Result: Each course instance gains a property, numCompleted, that is the
  #   number of students in that course instance who have completed ALL of
  #   the levels in thate course
  calculateDots: (classrooms, courses, courseInstances) ->
    for classroom in classrooms.models
      # map [user, level] => session so we don't have to do find TODO
      for course, courseIndex in courses.models
        instance = courseInstances.findWhere({ courseID: course.id, classroomID: classroom.id })
        continue if not instance
        instance.numCompleted = 0
        instance.started = false
        levels = classroom.getLevels({courseID: course.id})
        for userID in instance.get('members')
          instance.started ||= _.any levels.models, (level) ->
            session = _.find classroom.sessions.models, (session) ->
              session.get('creator') is userID and session.get('level').original is level.get('original')
            session?
          levelCompletes = _.map levels.models, (level) ->
            #TODO: Hella slow! Do the mapping first!
            sessions = _.filter classroom.sessions.models, (session) ->
              session.get('creator') is userID and session.get('level').original is level.get('original')
            # sessionMap[userID][level].completed()
            _.find(sessions, (s) -> s.completed())
          if _.every levelCompletes
            instance.numCompleted += 1

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
          return {
            courseNumber: courseIndex + 1
            levelNumber: levelIndex + 1
            levelName: level.get('name')
            users: users
          }
    null

  calculateLatestComplete: (classroom, courses, courseInstances, students) ->
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
          sessions = _.filter classroom.sessions.models, (session) ->
            session.get('creator') is userID and session.get('level').original is level.get('original')
          if _.find(sessions, (s) -> s.completed()) #
            userIDs.push userID
        if userIDs.length > 0
          users = _.map userIDs, (id) ->
            students.get(id)
          return {
            courseNumber: courseIndex + 1
            levelNumber: levelIndex + 1
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
        for level in levels.models
          levelID = level.get('original')
          progressData[classroom.id][course.id][levelID] = {
            completed: students.size() > 0,
            started: false
            numStarted: 0
            # numCompleted: 0
          }
          
          for user in students.models
            userID = user.id
            courseProgress = progressData[classroom.id][course.id]
            courseProgress[userID] ?= { completed: true, started: false, levelsCompleted: 0 } # Only set it the first time through a user
            courseProgress[levelID][userID] = { completed: true, started: false } # These don't matter, will always be set
            sessions = _.filter classroom.sessions.models, (session) ->
              session.get('creator') is userID and session.get('level').original is levelID
            
            courseProgress[levelID][userID].session = _.find(sessions, (s) -> s.completed()) or _.first(sessions)

            if _.size(sessions) is 0 # haven't gotten to this level yet, but might have completed others before
              courseProgress.started ||= false #no-op
              courseProgress.completed = false
              courseProgress[userID].started ||= false #no-op
              courseProgress[userID].completed = false
              courseProgress[levelID].started ||= false #no-op
              courseProgress[levelID].completed = false
              courseProgress[levelID][userID].started = false
              courseProgress[levelID][userID].completed = false
              
            if _.size(sessions) > 0 # have gotten to the level and at least started it
              courseProgress.started = true
              courseProgress[userID].started = true
              courseProgress[levelID].started = true
              courseProgress[levelID][userID].started = true
              courseProgress[levelID][userID].lastPlayed = new Date(Math.max(_.map(sessions, 'changed')))
              courseProgress[levelID].numStarted += 1
            
            if _.find(sessions, (s) -> s.completed()) # have finished this level
              courseProgress.completed &&= true #no-op
              courseProgress[userID].completed &&= true #no-op
              courseProgress[userID].levelsCompleted += 1
              courseProgress[levelID].completed &&= true #no-op
              # courseProgress[levelID].numCompleted += 1
              courseProgress[levelID][userID].completed = true
              dates = (s.get('dateFirstCompleted') || s.get('changed') for s in sessions)
              courseProgress[levelID][userID].dateFirstCompleted = new Date(Math.max(dates...))
            else # level started but not completed
              courseProgress.completed = false
              courseProgress[userID].completed = false
              courseProgress[levelID].completed = false
              courseProgress[levelID][userID].completed = false
              courseProgress[levelID].dateFirstCompleted = null
              courseProgress[levelID][userID].dateFirstCompleted = null

    _.assign(progressData, progressMixin)
    return progressData
  
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
