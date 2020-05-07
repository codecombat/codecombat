require('app/styles/teachers/resource-hub-view.sass')
RootView = require 'views/core/RootView'

resources =
  'faq':
    url: '/teachers/resources/faq'
    i18nCoverage: ['zh-HANS', 'he', 'nl-NL', 'pt-BR']
  'getting-started':
    url: '/teachers/resources/getting-started'
    i18nCoverage: ['zh-HANS']
  '1fhUnitOverview':
    url: '/teachers/resources/1fhUnitOverview'
    i18nCoverage: ['zh-HANS']
  '1fhLessonPlan':
    url: '/teachers/resources/1fhLessonPlan'
    i18nCoverage: ['zh-HANS']
  '1fh_Rubric':
    url: '/teachers/resources/1fh_Rubric'
    i18nCoverage: ['zh-HANS']
  'chapter1module1overview':
    url: '/teachers/resources/chapter1module1overview'
    i18nCoverage: ['zh-HANS']
  'chapter1module1lp':
    url: '/teachers/resources/chapter1module1lp'
    i18nCoverage: ['zh-HANS']
  'chapter1module2overview':
    url: '/teachers/resources/chapter1module2overview'
    i18nCoverage: ['zh-HANS']
  'chapter1module2lp':
    url: '/teachers/resources/chapter1module2lp'
    i18nCoverage: ['zh-HANS']
  'chapter1module3overview':
    url: '/teachers/resources/chapter1module3overview'
    i18nCoverage: ['zh-HANS']
  'chapter1module3lp':
    url: '/teachers/resources/chapter1module3lp'
    i18nCoverage: ['zh-HANS']
  'chapter1module4overview':
    url: '/teachers/resources/chapter1module4overview'
    i18nCoverage: ['zh-HANS']
  'chapter1module4lp':
    url: '/teachers/resources/chapter1module4lp'
    i18nCoverage: ['zh-HANS']
  'chapter1module5overview':
    url: '/teachers/resources/chapter1module5overview'
    i18nCoverage: ['zh-HANS']
  'chapter1module5lp':
    url: '/teachers/resources/chapter1module5lp'
    i18nCoverage: ['zh-HANS']
  'chapter1module6overview':
    url: '/teachers/resources/chapter1module6overview'
    i18nCoverage: ['zh-HANS']
  'chapter1module6lp':
    url: '/teachers/resources/chapter1module6lp'
    i18nCoverage: ['zh-HANS']
  'chapter1rubric':
    url: '/teachers/resources/chapter1rubric'
    i18nCoverage: ['zh-HANS']
  'chapter1rubric':
    url: '/teachers/resources/chapter1rubric'
    i18nCoverage: ['zh-HANS']
  'dashboardGuide':
    url: 'https://s3.amazonaws.com/files.ozaria.com/Ozaria+Teacher+Dashboard+1.0+Guide+.pdf'
    i18nCoverage: ['zh-HANS']
    i18n:
      'zh-HANS': 'https://ozaria-assets.oss-cn-qingdao.aliyuncs.com/resource-hub/%E5%A5%A5%E4%BD%B3%E7%9D%BF%E6%95%99%E5%B8%88%E9%9D%A2%E6%9D%BF%E6%8C%87%E5%8D%97.pdf'

module.exports = class ResourceHubView extends RootView
  id: 'resource-hub-view'
  template: require 'templates/teachers/resource-hub-view'

  events:
    'click .resource-link': 'onClickResourceLink'

  getMeta: -> { title: "#{$.i18n.t('nav.resource_hub')} | #{$.i18n.t('common.ozaria')}" }

  resourceURLuseLang: (resource, lang) ->
    return resource.url unless lang in resource.i18nCoverage
    resource.i18n?[lang] ? resource.url + '-' + lang

  resourceURL: (item) ->
    @resourceURLuseLang resources[item], switch me.get('preferredLanguage')
      when 'nl-NL', 'nl-BE' then 'nl-NL'
      when 'he' then 'he'
      when 'pt-BR', 'pt-PT' then 'pt-BR'
      when 'zh-HANS', 'zh-HANT' then 'zh-HANS'
      else ''

  initialize: ->
    super()
    me.getClientCreatorPermissions()?.then(() => @render?())

  onClickResourceLink: (e) ->
    link = $(e.target).closest('a')?.attr('href')
    window.tracker?.trackEvent 'Teachers Click Resource Hub Link', { category: 'Teachers', label: link }
