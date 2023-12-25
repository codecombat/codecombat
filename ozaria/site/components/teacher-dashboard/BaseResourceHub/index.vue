<script>
import { mapGetters, mapActions, mapMutations } from 'vuex'
import { COMPONENT_NAMES, PAGE_TITLES } from '../common/constants.js'
import ButtonResourceIcon from './components/ButtonResourceIcon'
import ModalOnboardingVideo from '../modals/ModalOnboardingVideo'
import { getResourceHubResources, getResourceHubZendeskResources } from 'core/api/resource_hub_resource'
import utils from 'app/core/utils'
import zendeskResourceMixin from './mixins/zendeskResourceMixin'
const store = require('core/store')

const resourceHubSections = [
  { sectionName: 'gettingStarted', slug: 'getting-started', i18nKey: 'teacher.getting_started' },
  { sectionName: 'educatorResources', slug: 'educator-resources', i18nKey: 'new_home.educator_resources' },
  { sectionName: 'lessonSlides', slug: 'lesson-slides', i18nKey: 'teacher.curriculum' },
  { sectionName: 'studentResources', slug: 'student-resources', i18nKey: 'teacher.student_resources' },
  { sectionName: 'faq', slug: 'faq', i18nKey: 'nav.faq' }
]

export default {
  name: COMPONENT_NAMES.RESOURCE_HUB,
  components: {
    ButtonResourceIcon,
    ModalOnboardingVideo
  },

  mixins: [
    zendeskResourceMixin
  ],

  data () {
    return {
      showVideoModal: false,
      resourceHubResources: {}
    }
  },

  computed: {
    ...mapGetters({
      loading: 'teacherDashboard/getLoadingState',
      activeClassrooms: 'teacherDashboard/getActiveClassrooms'
    }),

    supportEmail () {
      return utils.supportEmail
    },

    resourceHubSections () {
      return resourceHubSections
    },

    resourceHubLinks () {
      return this.resourceHubLinksHelper(this.resourceHubResources)
    }
  },

  async mounted () {
    this.setTeacherId(me.get('_id'))
    this.setPageTitle(PAGE_TITLES[this.$options.name])
    await this.fetchTeacherPrepaids({ teacherId: me.get('_id') })
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
        if (resource.slug === 'dashboard-tutorial') { resource.link = '#' }
        resource.description = utils.i18n(resource, 'description')
        resource.locked = resource.hidden === 'paid-only' && !store.getters['me/isPaidTeacher']
        resource.source = 'Resource Hub'

        this.$set(this.resourceHubResources, resource.slug, { ...resource })
      }
    })

    this.getZendeskResourcesMap()
      .then((result) => {
        for (const slug in result) {
          this.$set(this.resourceHubResources, slug, Object.freeze(result[slug]))
        }
      })
  },

  destroyed () {
    this.resetLoadingState()
  },

  methods: {
    ...mapActions({
      fetchData: 'teacherDashboard/fetchData',
      fetchTeacherPrepaids: 'prepaids/fetchPrepaidsForTeacher'
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
            <a
              v-if="resourceHubLinks(resourceHubSection.sectionName).length"
              :href="'#' + resourceHubSection.slug"
            >{{ $t(resourceHubSection.i18nKey) }}</a>
          </li>
        </ul>

        <h4>{{ $t('nav.contact') }}</h4>
        <div class="contact-icon">
          <img src="/images/ozaria/teachers/dashboard/svg_icons/IconMail.svg">
          <a
            :href="`mailto:${supportEmail}`"
            @click="trackEvent('Resource Hub: Support Email Clicked')"
          >
            {{ supportEmail }}
          </a>
        </div>
      </div>

      <div class="resource-hub">
        <div
          v-for="resourceHubSection in resourceHubSections"
          :id="resourceHubSection.slug"
          class="resource-hub-section"
        >
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
    text-transform: capitalize;
  }
}

.aside ul {
  padding: 0;
  list-style: none;

  margin-bottom: 50px;
}

.resource-hub {
  padding: 40px 30px 0;

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
    text-transform: capitalize;
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
