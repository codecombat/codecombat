fetchJson = require './fetch-json'
{ getInteractive } = require('ozaria/site/api/interactive.js')
{ getCinematic } = require('ozaria/site/api/cinematic.js')
{ getCutscene } = require('ozaria/site/api/cutscene.js')

module.exports = {
  getByOriginal: (original, options={}) ->
    return fetchJson("/db/level/#{original}/version", _.merge({}, options))

  getByIdOrSlug: (idOrSlug, options={}) ->
    return fetchJson("/db/level/#{idOrSlug}", _.merge({}, options))

  fetchForClassroom: (classroomID, options={}) ->
    return fetchJson("/db/classroom/#{classroomID}/levels", _.merge({}, options))

  fetchNextForCourse: ({ levelOriginalID, courseInstanceID, courseID, sessionID }, options={}) ->
    if courseInstanceID
      url = "/db/course_instance/#{courseInstanceID}/levels/#{levelOriginalID}/sessions/#{sessionID}/next"
    else
      url = "/db/course/#{courseID}/levels/#{levelOriginalID}/next"
    return fetchJson(url, options)

  save: (level, options={}) ->
    fetchJson("/db/level/#{level._id}", _.assign({}, options, {
      method: 'POST'
      json: level
    }))

  upsertSession: (levelId, options={}) ->
    data = {}
    if options.courseInstanceId
      data.courseInstance = options.courseInstanceId
    if options.course
      data.course = options.course
    if options.codeLanguage
      data.codeLanguage = options.codeLanguage
    url = "/db/level/#{levelId}/session"
    return fetchJson(url, {data})

  # fetches interactive/cinematic/cutcsene data for the intro levels
  fetchIntroContent: (introLevels) ->
    introLevelsContent = _.flatten(introLevels.map((l) => l.get('introContent')))
    introLevelsContentMap = {}
    introContentPromises = []
    introLevelsContent.forEach((c) =>
      return if c.type == 'avatarSelectionScreen'
      # contentId can be an object if interactive is different for python/js
      if c.type == 'interactive' && typeof c.contentId == 'object'
        (Object.values(c.contentId) || []).forEach((id) => introContentPromises.push(getInteractive(id)))
      else
        introContentPromises.push(getCinematic(c.contentId)) if c.type == 'cinematic'
        introContentPromises.push(getInteractive(c.contentId)) if c.type == 'interactive'
        introContentPromises.push(getCutscene(c.contentId)) if c.type == 'cutscene-video'
    )

    Promise.all(introContentPromises)
    .then (contentData) =>
      contentData.forEach((c) =>
        introLevelsContentMap[c._id] = c
      )
      return introLevelsContentMap
}
