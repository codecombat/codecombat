I18NEditModelView = require './I18NEditModelView'
ThangType = require 'models/ThangType'

module.exports = class ThangTypeI18NView extends I18NEditModelView
  id: 'thang-type-i18n-view'
  modelClass: ThangType

  buildTranslationList: ->
    lang = @selectedLanguage
    @model.markToRevert() unless @model.hasLocalChanges()
    i18n = @model.get('i18n')
    if i18n
      name = @model.get('name')
      @wrapRow('Name', ['name'], name, i18n[lang]?.name, [])
      @wrapRow('Description', ['description'], @model.get('description'), i18n[lang]?.description, [], 'markdown')
      @wrapRow('Extended Hero Name', ['extendedName'], @model.get('extendedName'), i18n[lang]?.extendedName, [])
      @wrapRow('Unlock Level Name', ['unlockLevelName'], @model.get('unlockLevelName'), i18n[lang]?.unlockLevelName, [])
