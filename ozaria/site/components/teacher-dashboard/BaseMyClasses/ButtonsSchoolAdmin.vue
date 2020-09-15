<script>
  import IconButtonWithTextTwilight from 'ozaria/site/components/school-admin-dashboard/common/buttons/IconButtonWithTextTwilight'

  export default {
    components: {
      IconButtonWithTextTwilight
    },

    props: {
      progressUrl: {
        type: String,
        default: ''
      },
      projectsUrl: {
        type: String,
        default: ''
      },
      inactive: {
        type: Boolean,
        default: false
      }
    },

    computed: {
      progressIcon () {
        if (this.inactive) {
          return '/images/ozaria/teachers/dashboard/svg_icons/Icon_Progress_Black.svg'
        } else {
          return '/images/ozaria/teachers/dashboard/svg_icons/Icon_Progress_Moon.svg'
        }
      },
      projectsIcon () {
        if (this.inactive) {
          return '/images/ozaria/teachers/dashboard/svg_icons/Icon_Capstone_Black.svg'
        } else {
          return '/images/ozaria/teachers/dashboard/svg_icons/Icon_Capstone_Moon.svg'
        }
      }
    },

    methods: {
      trackEvent (eventName) {
        if (eventName) {
          window.tracker?.trackEvent(eventName, { category: 'SchoolAdmin' })
        }
      }
    }
  }
</script>

<template>
  <div
    class="buttons-container"
  >
    <icon-button-with-text-twilight
      text="Class Progress"
      :icon-url="progressIcon"
      :inactive="inactive"
      :link="progressUrl"
      @click="trackEvent('All Classes: Class Progress Clicked')"
    />
    <icon-button-with-text-twilight
      text="Student Projects"
      :icon-url="projectsIcon"
      :inactive="inactive"
      :link="projectsUrl"
      @click="trackEvent('All Classes: Student Projects Clicked')"
    />
  </div>
</template>

<style lang="scss" scoped>
  .buttons-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: space-evenly;
    border: 0.5px solid #D8D8D8;
    border-left: 0;
    background: #FFFFFF;
    button {
      width: 172px;
    }
  }
</style>
