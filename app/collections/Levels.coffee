CocoCollection = require 'collections/CocoCollection'
Level = require 'models/Level'

module.exports = class LevelCollection extends CocoCollection
  url: '/db/level'
  model: Level

  fetchForClassroom: (classroomID, options={}) ->
    options.url = "/db/classroom/#{classroomID}/levels"
    @fetch(options)

  fetchForClassroomAndCourse: (classroomID, courseID, options={}) ->
    options.url = "/db/classroom/#{classroomID}/courses/#{courseID}/levels"
    @fetch(options)

  fetchForCampaign: (campaignSlug, options={}) ->
    options.url = "/db/campaign/#{campaignSlug}/levels"
    @fetch(options)
