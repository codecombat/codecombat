utils = require 'core/utils'
RootView = require 'views/core/RootView'

# TODO: adjust opacity of student on level cell based on num users
# TODO: better variables between current course/levels and classroom versioned ones
# TODO: exclude archived classes?
# TODO: level cell widths based on level median playtime
# TODO: students in multiple classrooms with different programming languages?

# TODO: refactor, cleanup, perf, yikes

# Outline:
# 1. Get a bunch of data
# 2. Get latest course and level maps
# 3. Get user activity and licenses
# 4. Get classroom activity
# 5. Build classroom progress

module.exports = class AdminClassroomsProgressView extends RootView
  id: 'admin-classrooms-progress-view'
  template: require 'templates/admin/admin-classrooms-progress'
  courseAcronymMap: utils.courseAcronyms

  initialize: ->
    return super() unless me.isAdmin()
    @licenseEndMonths = utils.getQueryVariable('licenseEndMonths', 6)
    @buildProgressData(@licenseEndMonths)
    super()

  buildProgressData: ->

    Promise.all [
      Promise.resolve($.get('/db/course')),
      Promise.resolve($.get('/db/campaign')),
      Promise.resolve($.get("/db/prepaid/-/active-school-licenses?licenseEndMonths=#{@licenseEndMonths}"))
    ]
    .then (results) =>
      [courses, campaigns, {@classrooms, levelSessions, prepaids, teachers}] = results
      courses = courses.filter((c) => c.releasePhase is 'released')
      utils.sortCourses(courses)
      licenses = prepaids.filter((p) => p.redeemers?.length > 0)

      # console.log 'courses', courses
      # console.log 'campaigns', campaigns
      # console.log 'classrooms', @classrooms
      # console.log 'licenses', licenses
      # console.log 'levelSessions', levelSessions

      @teacherMap = {}
      @teacherMap[teacher._id] = teacher for teacher in teachers

      [@latestCourseMap, @latestLevelSlugMap, latestOrderedLevelOriginals] = @getLatestLevels(campaigns, courses)
      [userLatestActivityMap, userLevelOriginalCompleteMap, userLicensesMap] = @getUserActivity(levelSessions, licenses, latestOrderedLevelOriginals)
      [classroomLatestActivity, classroomLicenseCourseLevelMap, classroomLicenseFurthestLevelMap] = @getClassroomActivity(@classrooms, @latestCourseMap, userLatestActivityMap, userLicensesMap, userLevelOriginalCompleteMap)

      # Build classroom/license/course/level progress
      @classroomProgress = []
      for classroomId, licensesCourseLevelMap of classroomLicenseCourseLevelMap #when classroomId is '573ac4b48edc9c1f009cd6be'
        classroom = _.find(@classrooms, (c) -> c._id is classroomId)
        classroomLicenses = []
        
        for licenseId, courseLevelMap of licensesCourseLevelMap

          # Build full level list and individual course indexes
          courseLastLevelIndexes = []
          courseLastLevelIndexMap = {}
          levels = []
          for courseId, levelMap of courseLevelMap
            for levelOriginal, val of levelMap
              levels.push({levelOriginal, numUsers: val})
            courseLastLevelIndexes.push({courseId, index: levels.length - 1})
            courseLastLevelIndexMap[courseId] = levels.length - 1
          furthestLevelIndex = levels.indexOf(_.findLast(levels, (l) -> l.numUsers > 0))
          percentComplete = (furthestLevelIndex + 1) / levels.length * 100
          courseLastLevelIndexes.sort((a, b) => utils.orderedCourseIDs.indexOf(a.courseId) - utils.orderedCourseIDs.indexOf(b.courseId))

          # Check latest courses for missing courses and levels in current classroom
          # NOTE: Missing levels are injected directly into levels list with extra missing=true prop
          missingCourses = []
          for courseId, courseData of @latestCourseMap #when @latestCourseMap[courseId].slug is 'computer-science-3'
            if courseLevelMap[courseId]
              # Course is available in classroom
              # furthestLevelIndex > courseLastLevelIndexMap[courseId] means furthest level is after this course
              # furthestLevelIndex <= courseLastLevelIndexMap[courseId] means furthest level is at or before end of this course
              if furthestLevelIndex <= courseLastLevelIndexMap[courseId]
                # Course is available in classroom, and furthest student is not past this course
                @addAvailableCourseMissingLevels(classroomId, classroomLicenseFurthestLevelMap, courseId, courseLastLevelIndexes, courseLevelMap, courseData.levels, latestOrderedLevelOriginals, levels, licenseId)
            else
              # Course missing entirely from classroom
              missingCourses.push({courseId, levels: courseData.levels})
          license = _.find(licenses, (l) -> l._id is licenseId)
          classroomLicenses.push({courseLastLevelIndexes, license, levels, furthestLevelIndex, missingCourses, percentComplete})
          # console.log classroomId, licenseId, levels, levelMap
          # break
        @classroomProgress.push({classroom, licenses: classroomLicenses, latestActivity: classroomLatestActivity[classroom._id]})

      @sortClassroomProgress(@classroomProgress)

      console.log 'classroomProgress', @classroomProgress

      @render?()

  addAvailableCourseMissingLevels: (classroomId, classroomLicenseFurthestLevelMap, courseId, courseLastLevelIndexes, courseLevelMap, latestCourseLevelOriginals, latestOrderedLevelOriginals, levels, licenseId) ->
    # Add missing levels from available course to full level list

    # Find missing levels from the latest version of the course
    currentCourseLevelOriginals = (levelOriginal for levelOriginal, val of courseLevelMap[courseId])
    latestCourseMissingLevelOriginals = _.reject(latestCourseLevelOriginals, (l) -> l in currentCourseLevelOriginals)
    # console.log 'latestCourseMissingLevelOriginals', @latestCourseMap[courseId].slug, _.map(latestCourseMissingLevelOriginals, (l) => @latestLevelSlugMap[l] or l)

    # Find missing latest levels that can be safely added to current course
    currentFurthestCourseLevelIndex = currentCourseLevelOriginals.indexOf(classroomLicenseFurthestLevelMap[classroomId]?[licenseId])
    # Find current started level that is closest to furthest current course level and also in latest level list
    furthestCurrentAndLatestCourseLevelIndex = currentFurthestCourseLevelIndex
    while furthestCurrentAndLatestCourseLevelIndex >= 0 and
    latestOrderedLevelOriginals.indexOf(currentCourseLevelOriginals[furthestCurrentAndLatestCourseLevelIndex]) < 0
      furthestCurrentAndLatestCourseLevelIndex--
    # Find earliest index in latest levels list that missing levels could be inserted
    latestLevelEarliestInsertionLevelIndex = 0
    if furthestCurrentAndLatestCourseLevelIndex >= 0
      latestLevelEarliestInsertionLevelIndex = latestOrderedLevelOriginals.indexOf(currentCourseLevelOriginals[furthestCurrentAndLatestCourseLevelIndex]) + 1
    # Keep each missing latest level that ahead of furthest insertion point in latest level list
    latestLevelsToAdd = _.filter(latestCourseMissingLevelOriginals, (l) ->
      latestOrderedLevelOriginals.indexOf(l) >= latestLevelEarliestInsertionLevelIndex and not _.find(levels, {levelOriginal: l}))
    latestLevelsToAdd.sort((a, b) => latestOrderedLevelOriginals.indexOf(a) - latestOrderedLevelOriginals.indexOf(b))
    # console.log 'latestLevelsToAdd', @latestCourseMap[courseId].slug, currentFurthestCourseLevelIndex, latestLevelEarliestInsertionLevelIndex, levels.length, _.map(latestLevelsToAdd, (l) => @latestLevelSlugMap[l] or l)

    # Find a specific insertion point in current course levels for each missing latest level
    # Splicing each missing level directly into current full levels list and current course levels list
    # Options for adding this latest level to existing course levels:
      # no furthest current or latest prev, insert at beginning
      # no furthest current, insert after latest prev
      # furthest current is latest previous, then insert right after furthest
      # latest previous is before furthest current, then insert right after furthest
      # latest previous is not in current levels, then insert right after furthest
      # latest previous is after furthest current, then insert after found latest previous
    currentPreviousCourseLevelIndex = currentFurthestCourseLevelIndex
    for levelOriginal, i in latestLevelsToAdd #when @latestCourseMap[courseId].slug is 'computer-science-4'
      previousLatestOriginal = latestOrderedLevelOriginals[latestOrderedLevelOriginals.indexOf(levelOriginal) - 1]

      if currentPreviousCourseLevelIndex < 0
        # no furthest current
        currentPreviousCourseLevelIndex = currentCourseLevelOriginals.indexOf(previousLatestOriginal)
        if currentPreviousCourseLevelIndex < 0
          # no furthest current or latest prev, insert at beginning
          currentPreviousCourseLevelIndex = 0
          # console.log 'no furthest current or latest prev, insert at beginning', previousLatestOriginal, currentPreviousCourseLevelIndex, _.findIndex(levels, {levelOriginal: currentCourseLevelOriginals[currentPreviousCourseLevelIndex]}), @latestLevelSlugMap[levelOriginal]
          levels.splice(_.findIndex(levels, {levelOriginal: currentCourseLevelOriginals[currentPreviousCourseLevelIndex]}), 0, {levelOriginal, numusers: 0, missing: true})
          currentCourseLevelOriginals.splice(currentPreviousCourseLevelIndex, 0, levelOriginal)
        else
          # no furthest current, insert after latest prev
          # console.log 'no furthest current, insert after latest prev', previousLatestOriginal, currentPreviousCourseLevelIndex, _.findIndex(levels, {levelOriginal: currentCourseLevelOriginals[currentPreviousCourseLevelIndex]}) + 1, @latestLevelSlugMap[levelOriginal]
          levels.splice(_.findIndex(levels, {levelOriginal: currentCourseLevelOriginals[currentPreviousCourseLevelIndex]}) + 1, 0, {levelOriginal, numusers: 0, missing: true})
          currentCourseLevelOriginals.splice(currentPreviousCourseLevelIndex + 1, 0, levelOriginal)
          currentPreviousCourseLevelIndex++

      else if currentCourseLevelOriginals[currentPreviousCourseLevelIndex] is previousLatestOriginal or
      currentCourseLevelOriginals.indexOf(previousLatestOriginal) < 0 or
      currentCourseLevelOriginals.indexOf(previousLatestOriginal) < currentPreviousCourseLevelIndex
        # furthest current is latest previous, then insert right after furthest
        # latest previous is before furthest current, then insert right after furthest
        # latest previous is not in current levels, then insert right after furthest
        # console.log 'insert next to furthest', previousLatestOriginal, currentPreviousCourseLevelIndex, _.findIndex(levels, {levelOriginal: currentCourseLevelOriginals[currentPreviousCourseLevelIndex]}) + 1, @latestLevelSlugMap[levelOriginal]
        levels.splice(_.findIndex(levels, {levelOriginal: currentCourseLevelOriginals[currentPreviousCourseLevelIndex]}) + 1, 0, {levelOriginal, numusers: 0, missing: true})
        currentCourseLevelOriginals.splice(currentPreviousCourseLevelIndex + 1, 0, levelOriginal)
        currentPreviousCourseLevelIndex++

      else #if currentCourseLevelOriginals.indexOf(previousLatestOriginal) > currentPreviousCourseLevelIndex
        if currentCourseLevelOriginals.indexOf(previousLatestOriginal) <= currentPreviousCourseLevelIndex
          console.log "ERROR! current index #{currentCourseLevelOriginals.indexOf(previousLatestOriginal)} of prev latest #{previousLatestOriginal} is <= currentPreviousCourseLevelIndex #{currentPreviousCourseLevelIndex}"
        # latest previous is after furthest current, then insert after found latest previous
        currentPreviousCourseLevelIndex = currentCourseLevelOriginals.indexOf(previousLatestOriginal)
        # console.log 'no furthest current, insert at beginning', _.findIndex(levels, {levelOriginal: currentCourseLevelOriginals[currentPreviousCourseLevelIndex]}) + 1, @latestLevelSlugMap[levelOriginal]
        levels.splice(_.findIndex(levels, {levelOriginal: currentCourseLevelOriginals[currentPreviousCourseLevelIndex]}) + 1, 0, {levelOriginal, numusers: 0, missing: true})
        currentCourseLevelOriginals.splice(currentPreviousCourseLevelIndex + 1, 0, levelOriginal)
        currentPreviousCourseLevelIndex++

      # Update courseLastLevelIndexes
      for courseLastLevelIndexData in courseLastLevelIndexes
        if utils.orderedCourseIDs.indexOf(courseLastLevelIndexData.courseId) >= utils.orderedCourseIDs.indexOf(courseId)
          courseLastLevelIndexData.index++
          # console.log 'incremented last level course index', courseLastLevelIndexData.index, @latestCourseMap[courseLastLevelIndexData.courseId].slug, @latestLevelSlugMap[levelOriginal]
      # break if i >= 1
    # console.log 'levels', levels.length

  getClassroomActivity: (classrooms, latestCourseMap, userLatestActivityMap, userLicensesMap, userLevelOriginalCompleteMap) ->
    classroomLicenseFurthestLevelMap = {}
    classroomLatestActivity = {}
    classroomLicenseCourseLevelMap = {}
    for classroom in classrooms #when classroom._id is '573ac4b48edc9c1f009cd6be'
      for license in userLicensesMap[classroom.ownerID]
        licensedMembers = _.intersection(classroom.members, _.map(license.redeemers, 'userID'))
        continue if _.isEmpty(licensedMembers)
        classroomLicenseCourseLevelMap[classroom._id] ?= {}
        classroomLicenseCourseLevelMap[classroom._id][license._id] ?= {}
        courseOriginalLevels = []
        for course in utils.sortCourses(classroom.courses) when latestCourseMap[course._id]
          for level in course.levels
            courseOriginalLevels.push(level.original)
        userFurthestLevelOriginalMap = {}
        for userId, levelOriginalCompleteMap of userLevelOriginalCompleteMap when licensedMembers.indexOf(userId) >= 0
          userFurthestLevelOriginalMap[userId] ?= {}
          for levelOriginal, complete of levelOriginalCompleteMap
            if _.isEmpty(userFurthestLevelOriginalMap[userId]) or
            courseOriginalLevels.indexOf(levelOriginal) > courseOriginalLevels.indexOf(userFurthestLevelOriginalMap[userId])
              userFurthestLevelOriginalMap[userId] = levelOriginal
        # For each level, how many is that the furthest for?
        for course in utils.sortCourses(classroom.courses) when latestCourseMap[course._id]
          classroomLicenseCourseLevelMap[classroom._id][license._id][course._id] ?= {}
          for level in course.levels
            classroomLicenseCourseLevelMap[classroom._id][license._id][course._id][level.original] ?= 0
            for userId in licensedMembers
              if not classroomLatestActivity[classroom._id] or
              classroomLatestActivity[classroom._id] < userLatestActivityMap[userId]
                classroomLatestActivity[classroom._id] = userLatestActivityMap[userId]
              if userFurthestLevelOriginalMap[userId] is level.original
                classroomLicenseCourseLevelMap[classroom._id][license._id][course._id][level.original]++
                classroomLicenseFurthestLevelMap[classroom._id] ?= {}
                classroomLicenseFurthestLevelMap[classroom._id][license._id] ?= {}
                classroomLicenseFurthestLevelMap[classroom._id][license._id] = level.original
                # console.log 'furthest level setting', latestCourseMap[course._id].slug, @latestLevelSlugMap[level.original]
    # console.log 'classroomLicenseFurthestLevelMap', classroomLicenseFurthestLevelMap
    # console.log 'classroomLatestActivity', classroomLatestActivity
    # console.log 'classroomLicenseCourseLevelMap', classroomLicenseCourseLevelMap
    [classroomLatestActivity, classroomLicenseCourseLevelMap, classroomLicenseFurthestLevelMap]

  getLatestLevels: (campaigns, courses) ->
    courseLevelsMap = {}
    originalSlugMap = {}
    latestOrderedLevelOriginals = []
    for course in courses
      campaign = _.find(campaigns, _id: course.campaignID)
      courseLevelsMap[course._id] = {slug: course.slug, levels: []}
      for levelOriginal, level of campaign.levels
        originalSlugMap[levelOriginal] = level.slug
        latestOrderedLevelOriginals.push(levelOriginal)
        courseLevelsMap[course._id].levels.push(levelOriginal)
    # console.log 'latestOrderedLevelOriginals', latestOrderedLevelOriginals
    [courseLevelsMap, originalSlugMap, latestOrderedLevelOriginals]

  getUserActivity: (levelSessions, licenses, latestOrderedLevelOriginals) ->
    # TODO: need to do anything with level sessions not in latest classroom content?
    userLatestActivityMap = {}
    userLevelOriginalCompleteMap = {}
    for levelSession in levelSessions when latestOrderedLevelOriginals.indexOf(levelSession?.level?.original) >= 0
      userLevelOriginalCompleteMap[levelSession.creator] ?= {}
      userLevelOriginalCompleteMap[levelSession.creator][levelSession.level.original] = levelSession?.state?.complete ? false
      if not userLatestActivityMap[levelSession.creator] or
      userLatestActivityMap[levelSession.creator] < levelSession.changed
        userLatestActivityMap[levelSession.creator] = levelSession.changed
    # console.log 'userLatestActivityMap', userLatestActivityMap
    # console.log 'userLevelOriginalCompleteMap', userLevelOriginalCompleteMap

    userLicensesMap = {}
    for license in licenses
      userLicensesMap[license.creator] ?= []
      userLicensesMap[license.creator].push(license)
    # console.log 'userLicensesMap', userLicensesMap

    [userLatestActivityMap, userLevelOriginalCompleteMap, userLicensesMap]

  sortClassroomProgress: (classroomProgress) ->
    # Find least amount of content buffer by teacher
    # TODO: use classroom members instead of license redeemers?
    teacherContentBufferMap = {}
    for progress in classroomProgress
      teacherId = progress.classroom.ownerID
      teacherContentBufferMap[teacherId] ?= {}
      percentComplete = _.max(_.map(progress.licenses, 'percentComplete'))
      if not teacherContentBufferMap[teacherId].percentComplete? or
      percentComplete > teacherContentBufferMap[teacherId].percentComplete
        teacherContentBufferMap[teacherId].percentComplete = percentComplete
      if not teacherContentBufferMap[teacherId].latestActivity? or
      progress.latestActivity > teacherContentBufferMap[teacherId].latestActivity
        teacherContentBufferMap[teacherId].latestActivity = progress.latestActivity
      numUsers = _.max(_.map(progress.licenses, (l) -> l.license?.redeemers?.length ? 0))
      if not teacherContentBufferMap[teacherId].numUsers? or numUsers > teacherContentBufferMap[teacherId].numUsers
        teacherContentBufferMap[teacherId].numUsers = numUsers
    # console.log 'teacherContentBufferMap', teacherContentBufferMap

    classroomProgress.sort (a, b) ->
      idA = a.classroom.ownerID
      idB = b.classroom.ownerID
      if idA is idB
        percentCompleteA = _.max(_.map(a.licenses, 'percentComplete'))
        percentCompleteB = _.max(_.map(b.licenses, 'percentComplete'))
        if percentCompleteA > percentCompleteB
          return -1
        else if percentCompleteA < percentCompleteB
          return 1
        else
          latestActivityA = a.latestActivity
          latestActivityB = b.latestActivity
          if latestActivityA > latestActivityB
            return -1
          else if latestActivityA < latestActivityB
            return 1
          else
            numUsersA = _.max(_.map(a.licenses, (l) -> l.license?.redeemers?.length ? 0))
            numUsersB = _.max(_.map(b.licenses, (l) -> l.license?.redeemers?.length ? 0))
            if numUsersA > numUsersB
              return -1
            else if numUsersA < numUsersB
              return 1
            else
              return 0
      else
        percentCompleteA = teacherContentBufferMap[idA].percentComplete
        percentCompleteB = teacherContentBufferMap[idB].percentComplete
        if percentCompleteA > percentCompleteB
          return -1
        else if percentCompleteA < percentCompleteB
          return 1
        else
          latestActivityA = teacherContentBufferMap[idA].latestActivity
          latestActivityB = teacherContentBufferMap[idB].latestActivity
          if latestActivityA > latestActivityB
            return -1
          else if latestActivityA < latestActivityB
            return 1
          else
            numUsersA = teacherContentBufferMap[idA].numUsers
            numUsersB = teacherContentBufferMap[idB].numUsers
            if numUsersA > numUsersB
              return -1
            else if numUsersA < numUsersB
              return 1
            else
              return 0
