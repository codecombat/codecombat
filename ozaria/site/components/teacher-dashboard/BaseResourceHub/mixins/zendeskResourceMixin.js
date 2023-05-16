import {
  getResourceHubResources,
  getResourceHubZendeskResources
} from '../../../../../../app/core/api/resource_hub_resource'
import utils from 'app/core/utils'
const _ = require('lodash')
const store = require('core/store')
const resourceSortFn = (a, b) => {
  if (a.priority > b.priority) return 1 // Resource Hub Resources should usually have priorities
  if (a.priority < b.priority) return -1
  if (a.section_id > b.section_id) return 1 // Zendesk articles have section_ids
  if (a.section_id < b.section_id) return -1
  if (!a.promoted && b.promoted) return 1 // Zendesk articles can be promoted within their sections
  if (a.promoted && !b.promoted) return -1
  if (a.position > b.position) return 1 // Zendesk articles can have positions
  if (a.position < b.position) return -1
  if (a.name > b.name) return 1
  if (a.name < b.name) return -1
  return 0
}

export default {
  computed: {
    relevantCategoryIds () {
      return {
        360004950774: 'Ozaria for Educators'
      }
    }
  },
  methods: {
    resourceHubLinksHelper (resources) {
      return (sectionName) => Object.values(resources).filter((r) => r.section === sectionName).sort(resourceSortFn)
    },
    async getZendeskResourcesMap () {
      const result = {}
      const allResources = await getResourceHubZendeskResources()
      if (!Array.isArray(allResources.articles) || allResources.articles.length === 0) {
        return
      }

      const relevantCategories = _.groupBy(_.filter(allResources.categories, (category) => this.relevantCategoryIds[category.id]), 'id')
      const relevantSections = _.groupBy(_.filter(allResources.sections, (section) => relevantCategories[section.category_id] && !section.outdated), 'id')
      const articlesBySection = _.groupBy(_.filter(allResources.articles, (article) => relevantSections[article.section_id] && !article.draft), 'section_id')

      for (const section of _.flatten(Object.values(relevantSections))) {
        const articles = articlesBySection[section.id] || []
        if (!articles.length) {
          delete relevantSections[section.id]
          continue
        }

        const resource = _.pick(section, ['name', 'description', 'position'])
        resource.link = section.html_url
        resource.section = 'faq'
        resource.icon = 'FAQ'
        resource.slug = 'zendesk-' + _.string.slugify(resource.name)
        resource.i18n = {}
        resource.source = 'Zendesk'

        resource.description = resource.description || ''
        for (const article of articles) {
          resource.description += `* [${article.name}](${article.html_url})\n`
        }

        result[resource.slug] = Object.freeze(resource)
      }
      return result
    },
    async getResourceHubResources () {
      const resources = await getResourceHubResources()

      for (const resource of resources) {
        if (resource.hidden === true) {
          continue
        }
        resource.name = utils.i18n(resource, 'name')
        resource.link = utils.i18n(resource, 'link')
        if (resource.slug === 'dashboard-tutorial') resource.link = '#'
        resource.description = utils.i18n(resource, 'description')
        resource.locked = resource.hidden === 'paid-only' && !store.getters['me/isPaidTeacher']
        resource.source = 'Resource Hub'
      }
      return resources
    }
  }
}
