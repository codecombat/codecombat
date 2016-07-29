I18NEditModelView = require './I18NEditModelView'
Level = require 'models/Level'
LevelComponent = require 'models/LevelComponent'

module.exports = class I18NEditLevelView extends I18NEditModelView
  id: 'i18n-edit-level-view'
  modelClass: Level

  buildTranslationList: ->
    lang = @selectedLanguage

    # name, description
    if i18n = @model.get('i18n')
      if name = @model.get('name')
        @wrapRow 'Level name', ['name'], name, i18n[lang]?.name, []
      if description = @model.get('description')
        @wrapRow 'Level description', ['description'], description, i18n[lang]?.description, []
      if loadingTip = @model.get('loadingTip')
        @wrapRow 'Loading tip', ['loadingTip'], loadingTip, i18n[lang]?.loadingTip, []

    # goals
    for goal, index in @model.get('goals') ? []
      if i18n = goal.i18n
        @wrapRow 'Goal name', ['name'], goal.name, i18n[lang]?.name, ['goals', index]

    # documentation
    for doc, index in @model.get('documentation')?.specificArticles ? []
      if i18n = doc.i18n
        @wrapRow 'Guide article name', ['name'], doc.name, i18n[lang]?.name, ['documentation', 'specificArticles', index]
        @wrapRow "'#{doc.name}' body", ['body'], doc.body, i18n[lang]?.body, ['documentation', 'specificArticles', index], 'markdown'

    # hints
    for hint, index in @model.get('documentation')?.hints ? []
      if i18n = hint.i18n
        name = "Hint #{index+1}"
        @wrapRow "'#{name}' body", ['body'], hint.body, i18n[lang]?.body, ['documentation', 'hints', index], 'markdown'
    for hint, index in @model.get('documentation')?.hintsB ? []
      if i18n = hint.i18n
        name = "Hint #{index+1}"
        @wrapRow "'#{name}' body", ['body'], hint.body, i18n[lang]?.body, ['documentation', 'hints', index], 'markdown'

    # sprite dialogues
    for script, scriptIndex in @model.get('scripts') ? []
      for noteGroup, noteGroupIndex in script.noteChain ? []
        for spriteCommand, spriteCommandIndex in noteGroup.sprites ? []
          pathPrefix = ['scripts', scriptIndex, 'noteChain', noteGroupIndex, 'sprites', spriteCommandIndex, 'say']

          if i18n = spriteCommand.say?.i18n
            if spriteCommand.say.text
              @wrapRow 'Sprite text', ['text'], spriteCommand.say.text, i18n[lang]?.text, pathPrefix, 'markdown'
            if spriteCommand.say.blurb
              @wrapRow 'Sprite blurb', ['blurb'], spriteCommand.say.blurb, i18n[lang]?.blurb, pathPrefix

          for response, responseIndex in spriteCommand.say?.responses ? []
            if i18n = response.i18n
              @wrapRow 'Response button', ['text'], response.text, i18n[lang]?.text, pathPrefix.concat(['responses', responseIndex])

    # victory modal
    if i18n = @model.get('victory')?.i18n
      @wrapRow 'Victory text', ['body'], @model.get('victory').body, i18n[lang]?.body, ['victory'], 'markdown'

    # code comments
    for thang, thangIndex in @model.get('thangs') ? []
      for component, componentIndex in thang.components ? []
        continue unless component.original is LevelComponent.ProgrammableID
        for methodName, method of component.config?.programmableMethods ? {}
          if (i18n = method.i18n) and (context = method.context)
            for key, value of context
              path = ['thangs', thangIndex, 'components', componentIndex, 'config', 'programmableMethods', methodName]
              @wrapRow 'Code comment', ['context', key], value, i18n[lang]?.context?[key], path
