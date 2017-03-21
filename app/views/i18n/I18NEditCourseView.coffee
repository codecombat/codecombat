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

    # name, description
    if i18n = @model.get('i18n')
      if name = @model.get('name')
        @wrapRow 'Course short name', ['name'], name, i18n[lang]?.name, []
      if description = @model.get('description')
        @wrapRow 'Course description', ['description'], description, i18n[lang]?.description, []

