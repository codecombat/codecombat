// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const fetchJson = require('./fetch-json')
const { getInteractive } = require('ozaria/site/api/interactive.js')
const { getCinematic } = require('ozaria/site/api/cinematic.js')
const { getCutscene } = require('ozaria/site/api/cutscene.js')

module.exports = {
  getByOriginal (original, options) {
    if (options == null) { options = {} }
    return fetchJson(`/db/level/${original}/version`, _.merge({}, options))
  },

  getByIdOrSlug (idOrSlug, options) {
    if (options == null) { options = {} }
    return fetchJson(`/db/level/${idOrSlug}`, _.merge({}, options))
  },

  fetchForClassroom (classroomID, options = {}) {
    return fetchJson(`/db/classroom/${classroomID}/levels`, _.merge({}, options))
  },

  fetchNextForCourse ({ levelOriginalID, courseInstanceID, courseID, sessionID }, options) {
    let url
    if (options == null) { options = {} }

    if (courseInstanceID) {
      url = `/db/course_instance/${courseInstanceID}/levels/${levelOriginalID}/sessions/${sessionID}/next`
    } else {
      url = `/db/course/${courseID}/levels/${levelOriginalID}/next`
    }
    return fetchJson(url, options)
  },

  fetchNextForCampaign ({ campaignSlug, levelOriginal }, options) {
    if (options == null) { options = {} }
    const url = `/db/campaign/${campaignSlug}/levels/${levelOriginal}/next`
    return fetchJson(url, options)
  },

  save (level, options) {
    if (options == null) { options = {} }
    return fetchJson(`/db/level/${level._id}`, _.assign({}, options, {
      method: 'POST',
      json: level
    }))
  },

  upsertSession (levelId, options) {
    if (options == null) { options = {} }
    const data = {}
    if (options.courseInstanceId) {
      data.courseInstance = options.courseInstanceId
    }
    if (options.course) {
      data.course = options.course
    }
    if (options.codeLanguage) {
      data.codeLanguage = options.codeLanguage
    }
    const url = `/db/level/${levelId}/session`
    return fetchJson(url, { data })
  },

  // fetches interactive/cinematic/cutcsene data for the intro levels
  fetchIntroContent (introLevels) {
    const introLevelsContent = _.flatten(introLevels.map(l => l.get('introContent')))
    const introLevelsContentMap = {}
    const introContentPromises = []
    introLevelsContent.forEach(c => {
      if (c.type === 'avatarSelectionScreen') { return }
      // contentId can be an object if interactive is different for python/js
      if ((c.type === 'interactive') && (typeof c.contentId === 'object')) {
        return (Object.values(c.contentId) || []).forEach(id => introContentPromises.push(getInteractive(id)))
      } else {
        if (c.type === 'cinematic') { introContentPromises.push(getCinematic(c.contentId)) }
        if (c.type === 'interactive') { introContentPromises.push(getInteractive(c.contentId)) }
        if (c.type === 'cutscene-video') { return introContentPromises.push(getCutscene(c.contentId)) }
      }
    })

    return Promise.all(introContentPromises)
      .then(contentData => {
        contentData.forEach(c => {
          introLevelsContentMap[c._id] = c
        })
        return introLevelsContentMap
      })
  }
}
