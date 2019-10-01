I18NEditModelView = require './I18NEditModelView'
ThangType = require 'models/ThangType'

module.exports = class I18NEditThangTypeView extends I18NEditModelView
  id: 'i18n-thang-type-view'
  modelClass: ThangType

  buildTranslationList: ->
    lang = @selectedLanguage
    @model.markToRevert() unless @model.hasLocalChanges()
    i18n = @model.get('i18n')
    if i18n
      name = @model.get('name')
      @wrapRow('Name', ['name'], name, i18n[lang]?.name, [])
      @wrapRow('Description', ['description'], @model.get('description'), i18n[lang]?.description, [], 'markdown')
      if extendedName = @model.get('extendedName')
        @wrapRow('Extended Hero Name', ['extendedName'], extendedName, i18n[lang]?.extendedName, [])
      if shortName = @model.get('shortName')
        @wrapRow('Short Hero Name', ['shortName'], shortName, i18n[lang]?.shortName, [])
      if unlockLevelName = @model.get('unlockLevelName')
        @wrapRow('Unlock Level Name', ['unlockLevelName'], unlockLevelName, i18n[lang]?.unlockLevelName, [])
