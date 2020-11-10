<script>
  import { mapGetters, mapActions, mapMutations } from 'vuex'
  import { COMPONENT_NAMES, PAGE_TITLES, resourceHubLinks } from '../common/constants.js'
  import ButtonResourceIcon from './components/ButtonResourceIcon'
  import ModalOnboardingVideo from '../modals/ModalOnboardingVideo'
  import { createNewResourceHubResource, getResourceHubResources } from '../../../api/resource_hub_resource'
  import utils from 'app/core/utils'

  // Temporarily added this allowing us to create resources using the console (whilst logged in as admin).
  window.createNewResourceHubResource = createNewResourceHubResource

  export default {
    name: COMPONENT_NAMES.RESOURCE_HUB,
    components: {
      ButtonResourceIcon,
      ModalOnboardingVideo
    },

    data () {
      return {
        showVideoModal: false,
        resourceHubResources: resourceHubLinks
      }
    },

    computed: {
      ...mapGetters({
        loading: 'teacherDashboard/getLoadingState',
        activeClassrooms: 'teacherDashboard/getActiveClassrooms'
      }),

      gettingStartedLinks () {
        return Object.values(this.resourceHubResources).filter((r) => r.section === 'gettingStarted').sort((a, b) => (a.name > b.name) ? 1 : -1)
      },

      educatorResourcesLinks () {
        return Object.values(this.resourceHubResources).filter((r) => r.section === 'educatorResources').sort((a, b) => (a.name > b.name) ? 1 : -1)
      }
    },

    mounted () {
      this.setTeacherId(me.get('_id'))
      this.setPageTitle(PAGE_TITLES[this.$options.name])
      this.fetchData({ componentName: this.$options.name, options: { loadedEventName: 'Resource Hub: Loaded' } })

      // Replace hard coded resources with those in database.
      getResourceHubResources().then(allResources => {
        const fetchedResources = {}

        if (!Array.isArray(allResources)) {
          return
        }
        if (allResources.length === 0) {
          return
        }

        for (const resource of allResources) {
          if (resource.hidden) {
            continue
          }

          resource.name = utils.i18n(resource, 'name')
          resource.link = utils.i18n(resource, 'link')

          fetchedResources[resource.slug] = {
            ...resource
          }
        }

        this.resourceHubResources = fetchedResources
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
          <li><a href="#getting-started">{{ $t('teacher.getting_started') }}</a></li>
          <li><a href="#educator-resources">{{ $t('new_home.educator_resources') }}</a></li>
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
        <h4 id="getting-started">
          {{ $t('teacher.getting_started') }}
        </h4>
        <div class="resource-contents-row">
          <button-resource-icon
            v-for="resourceHubLink in gettingStartedLinks"
            :key="resourceHubLink.name"
            :icon="resourceHubLink.icon"
            :label="resourceHubLink.name"
            :link="resourceHubLink.link"
            @click="() => { if (resourceHubLink.slug === 'dashboard-tutorial') { openVideoModal() } }"
          />
        </div>

        <h4 id="educator-resources">
          {{ $t('new_home.educator_resources') }}
        </h4>
        <div class="resource-contents-row">
          <button-resource-icon
            v-for="resourceHubLink in educatorResourcesLinks"
            :key="resourceHubLink.name"
            :icon="resourceHubLink.icon"
            :label="resourceHubLink.name"
            :link="resourceHubLink.link"
          />
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
}
</style>
