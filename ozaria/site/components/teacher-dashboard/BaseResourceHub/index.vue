<script>
  import { mapGetters, mapActions, mapMutations } from 'vuex'
  import { COMPONENT_NAMES, resourceHubLinks } from '../common/constants.js'
  import SecondaryTeacherNavigation from '../common/SecondaryTeacherNavigation'
  import TitleBar from '../common/TitleBar'
  import LoadingBar from '../common/LoadingBar'
  import ButtonResourceIcon from './components/ButtonResourceIcon'
  import ModalOnboardingVideo from '../modals/ModalOnboardingVideo'

  export default {
    name: COMPONENT_NAMES.RESOURCE_HUB,
    components: {
      'secondary-teacher-navigation': SecondaryTeacherNavigation,
      'title-bar': TitleBar,
      'loading-bar': LoadingBar,
      ButtonResourceIcon,
      ModalOnboardingVideo
    },

    data () {
      return {
        showVideoModal: false
      }
    },

    computed: {
      ...mapGetters({
        loading: 'teacherDashboard/getLoadingState',
        activeClassrooms: 'teacherDashboard/getActiveClassrooms'
      }),
      gettingStartedLinks () {
        return Object.values(resourceHubLinks).filter((r) => r.resourceHubSection === 'gettingStarted').sort((a, b) => (a.label > b.label) ? 1 : -1)
      },
      educatorResourcesLinks () {
        return Object.values(resourceHubLinks).filter((r) => r.resourceHubSection === 'educatorResources').sort((a, b) => (a.label > b.label) ? 1 : -1)
      }
    },

    mounted () {
      this.setTeacherId(me.get('_id'))
      this.fetchData({ componentName: this.$options.name, options: { loadedEventName: 'Resource Hub: Loaded' } })
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
        setTeacherId: 'teacherDashboard/setTeacherId'
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
  <div id='base-resource-hub'>
    <secondary-teacher-navigation
      :classrooms="activeClassrooms"
    />
    <title-bar
      title="Resource Hub"
      @newClass="$emit('newClass')"
    />
    <loading-bar
      :key="loading"
      :loading="loading"
    />

    <modal-onboarding-video
      v-if="showVideoModal"
      @close="closeVideoModal"
    />

    <div class='flex-container'>
      <div class="aside">
        <h4>Table of Contents</h4>
        <ul>
          <li><a href="#getting-started">Getting Started</a></li>
          <li><a href="#educator-resources">Educator Resources</a></li>
        </ul>

        <h4>Contact</h4>
        <div class="contact-icon">
          <img src="/images/ozaria/teachers/dashboard/svg_icons/IconMail.svg" /><a href="mailto:support@codecombat.com" @click="trackEvent('Resource Hub: Support Email Clicked')">support@codecombat.com</a>
        </div>
      </div>

      <div class="resource-hub">
        <h4 id="getting-started">Getting Started</h4>
        <div class="resource-contents-row">
          <button-resource-icon
            v-for="resourceHubLink in gettingStartedLinks" 
            :key="resourceHubLink.label"
            :icon="resourceHubLink.icon"
            :label="resourceHubLink.label"
            :link="resourceHubLink.link"
            @click="() => { if (resourceHubLink.label === 'Dashboard Tutorial') { openVideoModal() } }"
          />
        </div>

        <h4 id="educator-resources">Educator Resources</h4>
        <div class="resource-contents-row">
          <button-resource-icon
            v-for="resourceHubLink in educatorResourcesLinks" 
            :key="resourceHubLink.label"
            :icon="resourceHubLink.icon"
            :label="resourceHubLink.label"
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
