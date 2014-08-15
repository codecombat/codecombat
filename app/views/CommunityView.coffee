RootView = require 'views/kinds/RootView'
template = require 'templates/community'

module.exports = class CommunityView extends RootView
  id: 'community-view'
  template: template

  afterRender: ->
    super()
    @$el.find('.contribute-classes a').each ->
      characterClass = $(@).attr('href').split('#')[1]
      title = $.i18n.t("classes.#{characterClass}_title")
      titleDescription = $.i18n.t("classes.#{characterClass}_title_description")
      if characterClass is 'artisan'
        summary = $.i18n.t("contribute.#{characterClass}_summary_pref") + ' Mondo Bizarro' + $.i18n.t("contribute.#{characterClass}_summary_suf")
      else if characterClass is 'scribe'
        summary = $.i18n.t("contribute.#{characterClass}_summary_pref") + 'Mozilla Developer Network' + $.i18n.t("contribute.#{characterClass}_summary_suf")
      else
        summary = $.i18n.t("contribute.#{characterClass}_summary")
      explanation = "<h4>#{title} #{titleDescription}</h4>#{summary}"
      $(@).find('img').popover(placement: 'bottom', trigger: 'hover', container: 'body', content: explanation, html: true)

    @$el.find('.logo-row img').each ->
      $(@).popover(placement: 'bottom', trigger: 'hover', container: 'body')
