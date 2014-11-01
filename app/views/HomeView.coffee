RootView = require 'views/kinds/RootView'
template = require 'templates/home'
WizardLank = require 'lib/surface/WizardLank'
ThangType = require 'models/ThangType'
Simulator = require 'lib/simulator/Simulator'

PlayItemsModal = require 'views/play/modal/PlayItemsModal' # TEST

{me} = require '/lib/auth'

module.exports = class HomeView extends RootView
  id: 'home-view'
  template: template

  events:
    'click #beginner-campaign': 'onClickBeginnerCampaign'

  constructor: ->
    super()
    window.tracker?.trackEvent 'Homepage', Action: 'Loaded'

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
    c

  onClickBeginnerCampaign: (e) ->
    e.preventDefault()
    e.stopImmediatePropagation()
    window.tracker?.trackEvent 'Homepage', Action: 'Play'
    window.open '/play', '_blank'

  # TEST
  afterInsert: ->
    super()
    @openModalView new PlayItemsModal()
