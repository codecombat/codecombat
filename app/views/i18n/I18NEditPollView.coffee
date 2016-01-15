I18NEditModelView = require './I18NEditModelView'
Poll = require 'models/Poll'

module.exports = class I18NEditPollView extends I18NEditModelView
  id: "i18n-edit-poll-view"
  modelClass: Poll

  buildTranslationList: ->
    lang = @selectedLanguage

    # name, description
    if i18n = @model.get('i18n')
      if name = @model.get('name')
        @wrapRow "Poll name", ['name'], name, i18n[lang]?.name, []
      if description = @model.get('description')
        @wrapRow "Poll description", ['description'], description, i18n[lang]?.description, []

    # answers
    for answer, index in @model.get('answers') ? []
      if i18n = answer.i18n
        @wrapRow 'Answer', ['text'], answer.text, i18n[lang]?.text, ['answers', index]
