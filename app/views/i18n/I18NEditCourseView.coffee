I18NEditModelView = require './I18NEditModelView'
Course = require 'models/Course'
deltasLib = require 'core/deltas'
Patch = require 'models/Patch'
Patches = require 'collections/Patches'
PatchModal = require 'views/editor/PatchModal'

# TODO: Apply these changes to all i18n views if it proves to be more reliable

module.exports = class I18NEditCourseView extends I18NEditModelView
  id: "i18n-edit-course-view"
  modelClass: Course
    
  buildTranslationList: ->
    lang = @selectedLanguage

    # name, description, shortName
    if i18n = @model.get('i18n')
      if name = @model.get('name')
        @wrapRow 'Course short name', ['name'], name, i18n[lang]?.name, []
      if description = @model.get('description')
        @wrapRow 'Course description', ['description'], description, i18n[lang]?.description, []

      # Update the duration text that appears in the curriculum guide
      durationI18n = @model.get('duration').i18n
      if durationI18n
        if total = @model.get('duration').total
          this.wrapRow(
            'Duration Total',
            ['total'],
            total,
            durationI18n[lang]?.total,
            ['duration'])
        if inGame = @model.get('duration').inGame
          this.wrapRow(
            'Duration inGame',
            ['inGame'],
            inGame,
            durationI18n[lang]?.inGame,
            ['duration'])
        if totalTimeRange = @model.get('duration').totalTimeRange
          this.wrapRow(
            'Duration totalTimeRange',
            ['totalTimeRange'],
            totalTimeRange,
            durationI18n[lang]?.totalTimeRange,
            ['duration'])

      cstaStandards = @model.get('cstaStandards') || []
      for standard, i in cstaStandards
        i18n = standard['i18n']
        if i18n
          this.wrapRow('CSTA: Name', ['name'], standard.name, i18n[lang]?.name, ['cstaStandards', i])
          this.wrapRow('CSTA: Description', ['description'], standard.description, i18n[lang]?.description, ['cstaStandards', i])
