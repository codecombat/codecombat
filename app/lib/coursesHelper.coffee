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
            return true if level.get('type')?.indexOf('ladder') > -1
            #TODO: Hella slow! Do the mapping first!
            session = _.find classroom.sessions.models, (session) ->
              session.get('creator') == userID and session.get('level').original == level.get('original')
            # sessionMap[userID][level].completed()
            session?.completed()
          if allComplete
            instance.numCompleted += 1
