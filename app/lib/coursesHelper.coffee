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
