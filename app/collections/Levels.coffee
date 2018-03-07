CocoCollection = require 'collections/CocoCollection'
Level = require 'models/Level'
utils = require 'core/utils'

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

  getSolutionsMap: (language) ->
    @models.reduce((map, level) =>
      targetLang = level.get('primerLanguage') or language
      solutions = level.getSolutions().filter((s) => s.language is targetLang)
      map[level.get('original')] = solutions?.map((s) => @fingerprint(s.source, s.language))
      map
    , {})

  fingerprint: (code, language) ->
    # Add a zero-width-space at the end of every comment line
    switch language
      when 'javascript' then code.replace /^(\/\/.*)/gm, "$1​"
      when 'lua' then code.replace /^(--.*)/gm, "$1​"
      when 'html' then code.replace /^(<!--.*)-->/gm, "$1​-->"
      else code.replace /^(#.*)/gm, "$1​"
