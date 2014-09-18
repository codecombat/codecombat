RootView = require 'views/kinds/RootView'
template = require 'templates/front-view'
{me} = require '/lib/auth'
ModalView = require 'views/kinds/ModalView'

module.exports = class FrontView extends RootView
  id: 'front-view'
  template: template

  events:
    'click .platform-ios a': 'onIOSClicked'

  getRenderData: ->
    c = super()
    if $.browser
      majorVersion = $.browser.versionNumber
      c.isOldBrowser = true if $.browser.mozilla && majorVersion < 21
      c.isOldBrowser = true if $.browser.chrome && majorVersion < 17
      c.isOldBrowser = true if $.browser.safari && majorVersion < 6
    else
      console.warn 'no more jquery browser version...'
    c

  afterRender: ->
    super()

  onIOSClicked: (e) ->
    header = 'Sorry, the iPad app isn\'t ready yet'
    body = '''
      <p class="lead">We are working on it!</p>
      <p>For now, try playing on the web, and totally sign up (with emails enabled) so you can be the first to hear when it is ready.</p>
    '''
    notImplementedModal = new ModalView headerContent: header, bodyContent: body
    @openModalView notImplementedModal
