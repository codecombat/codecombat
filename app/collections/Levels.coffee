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
      solutions = level.getSolutions()
      # TODO: this doesn't work yet
      for lang in targetLangs
        if lang is 'html'
          for s in solutions ? []
            return unless s.language is 'html'
            strippedSource = utils.extractPlayerCodeTag(s.source or '')
            s.source = strippedSource if strippedSource
        else if lang isnt 'javascript' and not _.find(solutions, language: lang)
          for s in solutions ? []
            return unless s.language is 'javascript'
            s.language = lang
            s.source = aetherUtils.translateJS(s.source, lang)
      map[level.get('original')] = solutions?.map((s) => {source: @fingerprint(s.source, s.language), description: s.description})
      map
    , {})

  fingerprint: (code, language) ->
    # Add a zero-width-space at the end of every comment line
    switch language
      when ['javascript', 'java', 'cpp'] then code.replace /^(\/\/.*)/gm, "$1​"
      when 'lua' then code.replace /^(--.*)/gm, "$1​"
      when 'html' then code.replace /^(<!--.*)-->/gm, "$1​-->"
      else code.replace /^(#.*)/gm, "$1​"
