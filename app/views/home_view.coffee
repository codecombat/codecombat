View = require 'views/kinds/RootView'
template = require 'templates/home'
WizardSprite = require 'lib/surface/WizardSprite'
ThangType = require 'models/ThangType'
Simulator = require 'lib/simulator/Simulator'
{me} = require '/lib/auth'
application  = require 'application'

module.exports = class HomeView extends View
  id: 'home-view'
  template: template

  events:
    'click .code-language': 'onCodeLanguageSelected'

  constructor: ->
    super(arguments...)
    ThangType.loadUniversalWizard()

  getRenderData: ->
    c = super()
    if $.browser
      majorVersion = $.browser.versionNumber
      c.isOldBrowser = true if $.browser.mozilla && majorVersion < 21
      c.isOldBrowser = true if $.browser.chrome && majorVersion < 17
      c.isOldBrowser = true if $.browser.safari && majorVersion < 6
    else
      console.warn 'no more jquery browser version...'
    c.isEnglish = (me.get('preferredLanguage') or 'en').startsWith 'en'
    c.languageName = me.get('preferredLanguage')
    c.codeLanguage = (me.get('aceConfig') ? {}).language or 'javascript'
    c

  afterRender: ->
    super()
    @$el.find('.modal').on 'shown.bs.modal', ->
      $('input:visible:first', @).focus()

    # Try to find latest level and set "Play" link to go to that level
    lastLevel = me.get("lastLevel")
    lastLevel ?= localStorage?["lastLevel"]  # Temp, until it's migrated to user property
    if lastLevel
      playLink = @$el.find("#beginner-campaign")
      if playLink[0]?
        href = playLink.attr("href").split("/")
        href[href.length-1] = lastLevel if href.length isnt 0
        href = href.join("/")
        playLink.attr("href", href)

    codeLanguage = (me.get('aceConfig') ? {}).language or 'javascript'
    @$el.find(".code-language[data-code-language=#{codeLanguage}]").addClass 'selected-language'

  onCodeLanguageSelected: (e) ->
    target = $(e.target).closest('.code-language')
    codeLanguage = target.data('code-language')
    @$el.find('.code-language').removeClass 'selected-language'
    target.addClass 'selected-language'
    aceConfig = me.get('aceConfig') ? {}
    return if (aceConfig.language or 'javascript') is codeLanguage
    aceConfig.language = codeLanguage
    me.set 'aceConfig', aceConfig
    me.save()  # me.patch() doesn't work if aceConfig previously existed and we switched just once
