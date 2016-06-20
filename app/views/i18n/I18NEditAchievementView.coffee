I18NEditModelView = require './I18NEditModelView'
Achievement = require 'models/Achievement'

module.exports = class I18NEditAchievementView extends I18NEditModelView
  id: "i18n-edit-achievement-view"
  modelClass: Achievement

  buildTranslationList: ->
    lang = @selectedLanguage

    # name, description
    if i18n = @model.get('i18n')
      if name = @model.get('name')
        @wrapRow "Achievement name", ['name'], name, i18n[lang]?.name, []
      if description = @model.get('description')
        @wrapRow "Achievement description", ['description'], description, i18n[lang]?.description, []
