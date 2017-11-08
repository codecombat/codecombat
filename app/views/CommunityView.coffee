require('app/styles/community.sass')
RootView = require 'views/core/RootView'
template = require 'templates/community-view'

module.exports = class CommunityView extends RootView
  id: 'community-view'
  template: template

  afterRender: ->
    super()
    @$el.find('.contribute-classes a').each ->
      characterClass = $(@).attr('href').split('/')[2]
      title = $.i18n.t("classes.#{characterClass}_title")
      titleDescription = $.i18n.t("classes.#{characterClass}_title_description")
      summary = $.i18n.t("classes.#{characterClass}_summary")
      explanation = "<h4>#{title} #{titleDescription}</h4>#{summary}"
      $(@).find('img').popover(placement: 'top', trigger: 'hover', container: 'body', content: explanation, html: true)

    @$el.find('.logo-row img').each ->
      $(@).popover(placement: 'top', trigger: 'hover', container: 'body')

  logoutRedirectURL: false
