I18NEditModelView = require './I18NEditModelView'
LevelComponent = require 'models/LevelComponent'

module.exports = class I18NEditComponentView extends I18NEditModelView
  id: 'i18n-edit-component-view'
  modelClass: LevelComponent

  buildTranslationList: ->
    lang = @selectedLanguage

    propDocs = @model.get('propertyDocumentation')

    for propDoc, propDocIndex in propDocs

      #- Component property descriptions
      if i18n = propDoc.i18n
        path = ['propertyDocumentation', propDocIndex]
        @wrapRow "#{propDoc.name} name value", ['name'], propDoc.name, i18n[lang]?.name, path
        if _.isObject propDoc.description
          for progLang, description of propDoc.description
            @wrapRow "#{propDoc.name} description (#{progLang})", ['description', progLang], description, i18n[lang]?[progLang]?.description, path, 'markdown'
        else if _.isString propDoc.description
          @wrapRow "#{propDoc.name} description", ['description'], propDoc.description, i18n[lang]?.description, path, 'markdown'
        if context = propDoc.context
          for key, value of context
            @wrapRow "#{propDoc.name} context value", ['context', key], value, i18n[lang]?.context?[key], path

      #- Component return value descriptions
      if i18n = propDoc.returns?.i18n
        path = ['propertyDocumentation', propDocIndex, 'returns']
        d = propDoc.returns.description
        if _.isObject d
          for progLang, description of d.description
            @wrapRow "#{propDoc.name} return val (#{progLang})", ['description', progLang], description, i18n[lang]?[progLang]?.description, path, 'markdown'
        else if _.isString d
          @wrapRow "#{propDoc.name} return val", ['description'], d, i18n[lang]?.description, path, 'markdown'

      #- Component argument descriptions
      if propDoc.args
        for argDoc, argIndex in propDoc.args
          if i18n = argDoc.i18n
            path = ['propertyDocumentation', propDocIndex, 'args', argIndex]
            if _.isObject argDoc.description
              for progLang, description of argDoc.description
                @wrapRow "#{propDoc.name} arg description #{argDoc.name} (#{progLang})", ['description', progLang], description, i18n[lang]?[progLang]?.description, path, 'markdown'
            else if _.isString argDoc.description
              @wrapRow "#{propDoc.name} arg description #{argDoc.name}", ['description'], argDoc.description, i18n[lang]?.description, path, 'markdown'

    # Code context
    i18n = @model.get("i18n")
    context = @model.get("context")
    if i18n and context
      for key, value of context
        @wrapRow "Code context value", ['context', key], value, i18n[lang]?.context?[key], []
