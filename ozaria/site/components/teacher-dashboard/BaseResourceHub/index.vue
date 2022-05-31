<script>
  import { mapGetters, mapActions, mapMutations } from 'vuex'
  import { COMPONENT_NAMES, PAGE_TITLES } from '../common/constants.js'
  import ButtonResourceIcon from './components/ButtonResourceIcon'
  import ModalOnboardingVideo from '../modals/ModalOnboardingVideo'
  import { getResourceHubResources, getResourceHubZendeskResources } from 'core/api/resource_hub_resource'
  import utils from 'app/core/utils'
  const store = require('core/store')

  const resourceSortFn = (a, b) => {
    if (a.priority > b.priority) return 1  // Resource Hub Resources should usually have priorities
    if (a.priority < b.priority) return -1
    if (a.section_id > b.section_id) return 1  // Zendesk articles have section_ids
    if (a.section_id < b.section_id) return -1
    if (!a.promoted && b.promoted) return 1  // Zendesk articles can be promoted within their sections
    if (a.promoted && !b.promoted) return -1
    if (a.position > b.position) return 1  // Zendesk articles can have positions
    if (a.position < b.position) return -1
    if (a.name > b.name) return 1
    if (a.name < b.name) return -1
    return 0
  }

  const resourceHubSections = [
    { sectionName: 'gettingStarted', slug: 'getting-started', i18nKey: 'teacher.getting_started' },
    { sectionName: 'educatorResources', slug: 'educator-resources', i18nKey: 'new_home.educator_resources' },
    { sectionName: 'studentResources', slug: 'student-resources', i18nKey: 'teacher.student_resources' },
    { sectionName: 'lessonSlides', slug: 'lesson-slides', i18nKey: 'teacher.lesson_slides' },
    { sectionName: 'faq', slug: 'faq', i18nKey: 'nav.faq' },
  ]

  export default {
    name: COMPONENT_NAMES.RESOURCE_HUB,
    components: {
      ButtonResourceIcon,
      ModalOnboardingVideo
    },

    data () {
      return {
        showVideoModal: false,
        resourceHubResources: {},
      }
    },

    computed: {
      ...mapGetters({
        loading: 'teacherDashboard/getLoadingState',
        activeClassrooms: 'teacherDashboard/getActiveClassrooms'
      }),

      resourceHubSections () {
        return resourceHubSections
      },

      resourceHubLinks () {
        return (sectionName) => Object.values(this.resourceHubResources).filter((r) => r.section === sectionName).sort(resourceSortFn)
      }
    },

    mounted () {
      this.setTeacherId(me.get('_id'))
      this.setPageTitle(PAGE_TITLES[this.$options.name])
      this.fetchData({ componentName: this.$options.name, options: { loadedEventName: 'Resource Hub: Loaded' } })

      getResourceHubResources().then(allResources => {
        if (!Array.isArray(allResources) || allResources.length === 0) {
          return
        }

        for (const resource of allResources) {
          if (resource.hidden === true) {
            continue
          }

          resource.name = utils.i18n(resource, 'name')
          resource.link = utils.i18n(resource, 'link')
          if (resource.slug === 'dashboard-tutorial')
            resource.link = '#'
          resource.description = utils.i18n(resource, 'description')
          resource.locked = resource.hidden === 'paid-only' && !store.getters['me/isPaidTeacher']
          resource.source = 'Resource Hub'

          this.$set(this.resourceHubResources, resource.slug, { ...resource })
        }
      })

      getResourceHubZendeskResources().then(allResources => {
        if (!Array.isArray(allResources.articles) || allResources.articles.length === 0) {
          return
        }

        const relevantCategoryIds = {
          360004950774: 'Ozaria for Educators',
        }
        const relevantCategories = _.groupBy(_.filter(allResources.categories, (category) => relevantCategoryIds[category.id]), 'id')
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

          this.$set(this.resourceHubResources, resource.slug, Object.freeze(resource))
        }
      })
    },

    destroyed () {
      this.resetLoadingState()
    },

    methods: {
      ...mapActions({
        fetchData: 'teacherDashboard/fetchData'
      }),
      ...mapMutations({
        resetLoadingState: 'teacherDashboard/resetLoadingState',
        setTeacherId: 'teacherDashboard/setTeacherId',
        setPageTitle: 'teacherDashboard/setPageTitle'
      }),
      trackEvent (eventName) {
        if (eventName) {
          window.tracker?.trackEvent(eventName, { category: 'Teachers' })
        }
      },
      openVideoModal () {
        this.showVideoModal = true
      },
      closeVideoModal () {
        this.showVideoModal = false
      }
    }
  }
</script>

<template>
  <div id="base-resource-hub">
    <modal-onboarding-video
      v-if="showVideoModal"
      @close="closeVideoModal"
    />

    <div class="flex-container">
      <div class="aside">
        <h4>{{ $t('common.table_of_contents') }}</h4>
        <ul>
          <li v-for="resourceHubSection in resourceHubSections">
            <a v-if="resourceHubLinks(resourceHubSection.sectionName).length" :href="'#' + resourceHubSection.slug">{{ $t(resourceHubSection.i18nKey) }}</a>
          </li>
        </ul>

        <h4>{{ $t('nav.contact') }}</h4>
        <div class="contact-icon">
          <img src="/images/ozaria/teachers/dashboard/svg_icons/IconMail.svg">
          <a
            :href="`mailto:${$t('teacher_dashboard.support_oz')}`"
            @click="trackEvent('Resource Hub: Support Email Clicked')"
          >
            {{ $t('teacher_dashboard.support_oz') }}
          </a>
        </div>
      </div>

      <div class="resource-hub">
        <div class="resource-hub-section" v-for="resourceHubSection in resourceHubSections" :id="resourceHubSection.slug">
        <h4 v-if="resourceHubLinks(resourceHubSection.sectionName).length">
          {{ $t(resourceHubSection.i18nKey) }}
        </h4>
          <div class="resource-contents-row">
            <button-resource-icon
              v-for="resourceHubLink in resourceHubLinks(resourceHubSection.sectionName)"
              :key="resourceHubLink.name"
              :icon="resourceHubLink.icon"
              :label="resourceHubLink.name"
              :link="resourceHubLink.link"
              :description="resourceHubLink.description"
              :locked="resourceHubLink.locked"
              :from="resourceHubLink.source || 'Resource Hub'"
              :section="resourceHubSection.slug"
              @click="() => { if (resourceHubLink.slug === 'dashboard-tutorial') { openVideoModal() } }"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
#base-resource-hub {
  margin-bottom: -50px;
}

.contact-icon {
  display: flex;
  flex-direction: row;

  img {
    margin-right: 10px;
  }

  a {
    font-size: 14px;
    line-height: 18px;
    letter-spacing: 0.2667px;
    text-decoration: none;
  }
}

.flex-container {
  display: flex;
  flex-direction: row;
}

.aside {
  margin-top: 3px;

  width: 285px;
  padding: 30px;

  background-color: #f2f2f2;
  box-shadow: -1px 0px 1px rgba(0, 0, 0, 0.06), 3px 0px 8px rgba(0, 0, 0, 0.15);

  h4 {
    color: #131b25;
    font-family: 'Work Sans';
    font-size: 18px;
    line-height: 30px;
    letter-spacing: 0.44px;
    font-weight: 600;
    text-transform: uppercase;
    margin-bottom: 15px;
  }

  ul a {
    text-decoration: underline;
  }
}

.aside ul {
  padding: 0;
  list-style: none;

  margin-bottom: 50px;
}

.resource-hub {
  padding: 40px 30px;

  .resource-hub-section {
    /* Offset by rough header height so that we don't underscroll the header */
    margin-top: -80px;
    padding-top: 80px;
  }

  h4 {
    color: #476fb1;
    font-family: 'Work Sans';
    font-size: 20px;
    line-height: 30px;
    letter-spacing: 0.44px;
    font-weight: 600;
  }
}

.resource-contents-row {
  width: 100%;
  display: flex;
  align-items: start;
  flex-wrap: wrap;
  clear: both;
  min-height: 50px;
  margin: 15px 0;
}
</style>
