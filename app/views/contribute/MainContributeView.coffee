require('app/styles/contribute/contribute.sass')
ContributeClassView = require 'views/contribute/ContributeClassView'
template = require 'app/templates/contribute/contribute'
utils = require 'core/utils'

module.exports = class MainContributeView extends ContributeClassView
  id: 'contribute-view'
  template: template

  initialize: ->
    super()
    @apiLink = @getApiLink()
    @communityLink = @getCommunityLink()
    @forumLink = @getForumLink()

  events:
    'change input[type="checkbox"]': 'onCheckboxChanged'

  getLanguage: ->
    (me.get('preferredLanguage') or 'en').split('-')[0]

  getApiLink: ->
    link = 'https://github.com/codecombat/codecombat-api'
    if ['zh'].includes(@getLanguage()) or features.china
      link = utils.cocoBaseURL() + '/api-docs'
    return link

  getCommunityLink: ->
    return utils.cocoBaseURL() + '/community'

  getForumLink: ->
    link = 'https://discourse.codecombat.com/'
    if ['zh', 'ru', 'es', 'fr', 'pt', 'de', 'nl', 'lt'].includes(@getLanguage())
      link += "c/other-languages/#{@getLanguage()}"
    return link


