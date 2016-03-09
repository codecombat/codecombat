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
          allComplete = _.every campaign.getLevels().models, (level) ->
            return true if level.isLadder()
            #TODO: Hella slow! Do the mapping first!
            session = _.find classroom.sessions.models, (session) ->
              session.get('creator') == userID and session.get('level').original == level.get('original')
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
      for level, levelIndex in campaign.getLevels().models
        continue if level.isLadder()
        userIDs = []
        for userID in instance.get('members')
          session = _.find classroom.sessions.models, (session) ->
            session.get('creator') == userID and session.get('level').original == level.get('original')
          if !session or !session.completed()
            userIDs.push userID
        console.log [userIDs.length, courseIndex, levelIndex, level.get('name')]
        if userIDs.length > 0
          users = _.map userIDs, (id) ->
            students._byId[id]
          return {
            courseNumber: courseIndex + 1
            levelNumber: levelIndex + 1
            levelName: level.get('name')
            users: users
          }
    return {}
          

  calculateLatestComplete: (classroom, courses, campaigns, courseInstances, students) ->
    # Loop through all the combinations of things in reverse order, return the level that anyone's finished
    for course, courseIndex in courses.models.reverse() #
      courseIndex = courses.models.length - courseIndex - 1 #compensate for reverse
      instance = courseInstances.getByCourseAndClassroom(course, classroom)
      continue if not instance
      campaign = campaigns.get(course.get('campaignID'))
      for level, levelIndex in campaign.getLevels().models.reverse() #
        levelIndex = campaign.getLevels().models.length - levelIndex - 1 #compensate for reverse
        continue if level.isLadder()
        userIDs = []
        for userID in instance.get('members')
          session = _.find classroom.sessions.models, (session) ->
            session.get('creator') == userID and session.get('level').original == level.get('original')
          if session?.completed() #
            userIDs.push userID
        console.log [userIDs.length, courseIndex, levelIndex, level.get('name')]
        if userIDs.length > 0
          users = _.map userIDs, (id) ->
            students._byId[id]
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
    
    completeness = {}
    for classroom in classrooms.models
      completeness[classroom.id] = {}

      for course in courses.models
        instance = courseInstances.getByCourseAndClassroom(course, classroom)
        if not instance
          completeness[classroom.id][course.id] = { completed: false, started: false }
          continue
        completeness[classroom.id][course.id] = { completed: true, started: false } # to be updated
        campaign = campaigns.get(course.get('campaignID'))

        for level in campaign.getLevels().models
          completeness[classroom.id][course.id][level.get('original')] = { completed: false, started: false }
          continue if level.isLadder()

          for userID in instance.get('members')
            completeness[classroom.id][course.id][userID] = {}
            completeness[classroom.id][course.id][level.get('original')][userID] = {}
            session = _.find classroom.sessions.models, (session) ->
              session.get('creator') == userID and session.get('level').original == level.get('original')
            if not session
              completeness[classroom.id][course.id].started ||= false #no-op
              completeness[classroom.id][course.id].completed ||= false #no-op
              completeness[classroom.id][course.id][userID].started = false
              completeness[classroom.id][course.id][userID].completed = false
              completeness[classroom.id][course.id][level.get('original')].started ||= false #no-op
              completeness[classroom.id][course.id][level.get('original')].completed ||= false #no-op
              completeness[classroom.id][course.id][level.get('original')][userID].started = false
              completeness[classroom.id][course.id][level.get('original')][userID].completed = false
            if session
              completeness[classroom.id][course.id].started = true
              completeness[classroom.id][course.id][userID].started = true
              completeness[classroom.id][course.id][level.get('original')].started = true
              completeness[classroom.id][course.id][level.get('original')][userID].started = true
            if session?.completed()
              completeness[classroom.id][course.id].complete &&= true #no-op
              completeness[classroom.id][course.id][level.get('original')].complete &&= true #no-op
              completeness[classroom.id][course.id][userID].complete = true
              completeness[classroom.id][course.id][level.get('original')][userID].complete = true
    return completeness
  
  getProgress: (progress, options={}) ->
    { classroom, course, level, user } = options
    throw "You must provide a classroom" unless classroom
    throw "You must provide a course" unless course
    if options.level
      if options.user
        return progress[classroom.id][course.id][level.original][user.id]
      else
        return progress[classroom.id][course.id][level.original]
    else
      if options.user
        return progress[classroom.id][course.id][user.id]
      else
        return progress[classroom.id][course.id]
