module.exports = 
  # Result: Each course instance gains a property, numCompleted, that is the
  #   number of students in that course instance who have completed ALL of
  #   the levels in thate course
  calculateDots: (classrooms, courses, courseInstances, campaigns) ->
    for classroom in classrooms.models
      # map [user, level] => session so we don't have to do find TODO
      for course, courseIndex in courses.models
        instance = courseInstances.getByCourseAndClassroom(course, classroom)
        continue if not instance
        instance.numCompleted = 0
        campaign = campaigns.get(course.get('campaignID'))
        for userID in instance.get('members')
          allComplete = _.every campaign.getNonladderLevels().models, (level) ->
            return true if level.isLadder()
            #TODO: Hella slow! Do the mapping first!
            session = _.find classroom.sessions.models, (session) ->
              session.get('creator') is userID and session.get('level').original is level.get('original')
            # sessionMap[userID][level].completed()
            session?.completed()
          if allComplete
            instance.numCompleted += 1

  calculateEarliestIncomplete: (classroom, courses, campaigns, courseInstances, students) ->
    # Loop through all the combinations of things, return the first one that somebody hasn't finished
    for course, courseIndex in courses.models
      instance = courseInstances.getByCourseAndClassroom(course, classroom)
      continue if not instance
      campaign = campaigns.get(course.get('campaignID'))
      for level, levelIndex in campaign.getNonladderLevels().models
        userIDs = []
        for userID in instance.get('members')
          session = _.find classroom.sessions.models, (session) ->
            session.get('creator') is userID and session.get('level').original is level.get('original')
          if not session?.completed()
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
    return {}

  calculateLatestComplete: (classroom, courses, campaigns, courseInstances, students) ->
    # Loop through all the combinations of things in reverse order, return the level that anyone's finished
    courseModels = courses.models.slice()
    for course, courseIndex in courseModels.reverse() #
      courseIndex = courses.models.length - courseIndex - 1 #compensate for reverse
      instance = courseInstances.getByCourseAndClassroom(course, classroom)
      continue if not instance
      campaign = campaigns.get(course.get('campaignID'))
      levelModels = campaign.getNonladderLevels().models.slice()
      for level, levelIndex in levelModels.reverse() #
        levelIndex = levelModels.length - levelIndex - 1 #compensate for reverse
        userIDs = []
        for userID in instance.get('members')
          session = _.find classroom.sessions.models, (session) ->
            session.get('creator') is userID and session.get('level').original is level.get('original')
          if session?.completed() #
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
    return {}
    
  calculateAllProgress: (classrooms, courses, campaigns, courseInstances, students) ->
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
        instance = courseInstances.getByCourseAndClassroom(course, classroom)
        if not instance
          progressData[classroom.id][course.id] = { completed: false, started: false }
          continue
        progressData[classroom.id][course.id] = { completed: true, started: false } # to be updated
        
        # For debugging
        progressData[classroom.id][course.id]

        campaign = campaigns.get(course.get('campaignID'))
        for level in campaign.getNonladderLevels().models
          levelID = level.get('original')
          progressData[classroom.id][course.id][levelID] = { completed: true, started: false }
          
          for userID in classroom.get('members')
            progressData[classroom.id][course.id][userID] ?= { completed: true, started: false } # Only set it the first time through a user
            progressData[classroom.id][course.id][levelID][userID] = { completed: true, started: false } # These don't matter, will always be set
            session = _.find classroom.sessions.models, (session) ->
              session.get('creator') is userID and session.get('level').original is levelID

            if not session # haven't gotten to this level yet, but might have completed others before
              progressData[classroom.id][course.id].started ||= false #no-op
              progressData[classroom.id][course.id].completed = false
              progressData[classroom.id][course.id][userID].started ||= false #no-op
              progressData[classroom.id][course.id][userID].completed = false
              progressData[classroom.id][course.id][levelID].started ||= false #no-op
              progressData[classroom.id][course.id][levelID].completed = false
              progressData[classroom.id][course.id][levelID][userID].started = false
              progressData[classroom.id][course.id][levelID][userID].completed = false
            if session # have gotten to the level and at least started it
              progressData[classroom.id][course.id].started = true
              progressData[classroom.id][course.id][userID].started = true
              progressData[classroom.id][course.id][levelID].started = true
              progressData[classroom.id][course.id][levelID][userID].started = true
            if session?.completed() # have finished this level
              progressData[classroom.id][course.id].completed &&= true #no-op
              progressData[classroom.id][course.id][userID].completed = true
              progressData[classroom.id][course.id][levelID].completed &&= true #no-op
              progressData[classroom.id][course.id][levelID][userID].completed = true
            else # level started but not completed
              progressData[classroom.id][course.id].completed = false
              progressData[classroom.id][course.id][userID].completed = false
              progressData[classroom.id][course.id][levelID].completed = false
              progressData[classroom.id][course.id][levelID][userID].completed = false

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
        return @[classroom.id][course.id][levelID][user.id] or defaultValue
      else
        return @[classroom.id][course.id][levelID] or defaultValue
    else
      if options.user
        return @[classroom.id][course.id][user.id] or defaultValue
      else
        return @[classroom.id][course.id] or defaultValue
