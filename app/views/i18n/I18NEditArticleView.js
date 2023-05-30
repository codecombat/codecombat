I18NEditModelView = require './I18NEditModelView'
Article = require 'models/Article'

module.exports = class I18NEditArticleView extends I18NEditModelView
  id: 'i18n-edit-article-view'
  modelClass: Article

  buildTranslationList: ->
    lang = @selectedLanguage

    # name, content
    if i18n = @model.get('i18n')
      if name = @model.get('name')
        @wrapRow 'Article name', ['name'], name, i18n[lang]?.name, []
      if body = @model.get('body')
        @wrapRow 'Article body', ['body'], body, i18n[lang]?.body, [], 'markdown'
