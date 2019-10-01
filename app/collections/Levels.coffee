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

  getSolutionsMap: (languages) ->
    @models.reduce((map, level) =>
      targetLangs = if level.get('primerLanguage') then [level.get('primerLanguage')] else languages
      solutions = level.getSolutions().filter((s) => s.language in targetLangs)
      if 'html' in targetLangs
        solutions?.forEach (s) =>
          return unless s.language is 'html'
          strippedSource = utils.extractPlayerCodeTag(s.source or '')
          s.source = strippedSource if strippedSource
      map[level.get('original')] = solutions?.map((s) => {source: @fingerprint(s.source, s.language), description: s.description, capstoneStage: s.capstoneStage})
      map
    , {})

  fingerprint: (code, language) ->
    # Add a zero-width-space at the end of every comment line
    switch language
      when 'javascript' then code.replace /^(\/\/.*)/gm, "$1​"
      when 'lua' then code.replace /^(--.*)/gm, "$1​"
      when 'html' then code.replace /^(<!--.*)-->/gm, "$1​-->"
      else code.replace /^(#.*)/gm, "$1​"
