<script>
  import Panel from '../Panel/index.vue'
  import ModalNewClass from '../modals/ModalNewClass/index'
  import ModalAssignContent from '../modals/ModalAssignContent/index'
  import ModalAddStudents from '../modals/ModalAddStudents'
  import ModalRemoveStudents from '../modals/ModalRemoveStudents'
  import ModalOnboardingVideo from '../modals/ModalOnboardingVideo'

  import BaseSingleClass from '../../../store/BaseSingleClass'
  import BaseCurriculumGuide from '../BaseCurriculumGuide'
  import BaseCurriculumGuideModule from '../../../store/BaseCurriculumGuide'

  import { mapMutations } from 'vuex'

  export default {
    components: {
      Panel,
      ModalNewClass,
      ModalAssignContent,
      ModalAddStudents,
      ModalRemoveStudents,
      BaseCurriculumGuide,
      ModalOnboardingVideo
    },

    data () {
      // TODO: move the logic to open/close modals to teacherDashboard store instead of driving by events,
      // as it might grow a lot and become hard to maintain.
      return {
        showNewClassModal: false,
        showAssignContentModal: false,
        showAddStudentsModal: false,
        showRemoveStudentsModal: false,
        showOnboardingModal: !me.get('seenNewDashboardModal')
      }
    },

    watch: {
      $route (to, from) {
        if (to.params.classroomId !== from.params.classroomId && to.params.classroomId) {
          this.updateStoreOnNavigation()
        }
      }
    },

    beforeCreate () {
      this.$store.registerModule('baseSingleClass', BaseSingleClass)
      this.$store.registerModule('baseCurriculumGuide', BaseCurriculumGuideModule)
    },

    created () {
      this.updateStoreOnNavigation()
    },

    destroyed () {
      this.$store.unregisterModule('baseSingleClass')
      this.$store.unregisterModule('baseCurriculumGuide')
    },

    metaInfo () {
      return {
        title: 'ADMIN ONLY - Teacher Dashboard'
      }
    },

    beforeRouteUpdate (to, from, next) {
      // Ensures we close curriculum guide when navigating between pages in the
      // teacher dashboard.
      this.closeCurriculumGuide()
      next()
    },

    methods: {
      ...mapMutations({
        setClassroomId: 'teacherDashboard/setClassroomId',
        setTeacherId: 'teacherDashboard/setTeacherId',
        closeCurriculumGuide: 'baseCurriculumGuide/closeCurriculumGuide'
      }),

      updateStoreOnNavigation () {
        if (this.$route.params.classroomId) {
          this.setClassroomId(this.$route.params.classroomId)
        }
        this.setTeacherId(me.get('_id'))
      },

      closeOnboardingModal () {
        me.set('seenNewDashboardModal', true)
        me.save()
        this.showOnboardingModal = false
      }
    }
  }
</script>

<template>
  <div>
    <base-curriculum-guide />
    <panel />
    <router-view
      @newClass="showNewClassModal = true"
      @assignContent="showAssignContentModal = true"
      @addStudents="showAddStudentsModal = true"
      @removeStudents="showRemoveStudentsModal = true"
    />
    <modal-onboarding-video
      v-if="showOnboardingModal"
      @close="closeOnboardingModal"
    />
    <modal-new-class
      v-if="showNewClassModal"
      @close="showNewClassModal = false"
    />
    <modal-assign-content
      v-if="showAssignContentModal"
      @close="showAssignContentModal = false"
    />
    <modal-add-students
      v-if="showAddStudentsModal"
      @close="showAddStudentsModal = false"
    />
    <modal-remove-students
      v-if="showRemoveStudentsModal"
      @close="showRemoveStudentsModal = false"
    />
  </div>
</template>

<style lang="scss">
  /* Default tooltip styles so they work. */
  .tooltip {
    display: block !important;
    z-index: 10000;

    .tooltip-inner {
      background: black;
      color: white;
      border-radius: 16px;
      padding: 5px 10px 4px;
    }

    .tooltip-arrow {
      width: 0;
      height: 0;
      border-style: solid;
      position: absolute;
      margin: 5px;
      border-color: black;
      z-index: 1;
    }

    &[x-placement^="top"] {
      margin-bottom: 5px;

      .tooltip-arrow {
        border-width: 10px 20px 0 20px;
        border-left-color: transparent !important;
        border-right-color: transparent !important;
        border-bottom-color: transparent !important;
        bottom: -5px;
        left: calc(50% - 5px);
        margin-top: 0;
        margin-bottom: 0;
      }
    }

    &[x-placement^="bottom"] {
      margin-top: 5px;

      .tooltip-arrow {
        border-width: 0 5px 5px 5px;
        border-left-color: transparent !important;
        border-right-color: transparent !important;
        border-top-color: transparent !important;
        top: -5px;
        left: calc(50% - 5px);
        margin-top: 0;
        margin-bottom: 0;
      }
    }

    &[x-placement^="right"] {
      margin-left: 5px;

      .tooltip-arrow {
        border-width: 5px 5px 5px 0;
        border-left-color: transparent !important;
        border-top-color: transparent !important;
        border-bottom-color: transparent !important;
        left: -5px;
        top: calc(50% - 5px);
        margin-left: 0;
        margin-right: 0;
      }
    }

    &[x-placement^="left"] {
      margin-right: 5px;

      .tooltip-arrow {
        border-width: 5px 0 5px 5px;
        border-top-color: transparent !important;
        border-right-color: transparent !important;
        border-bottom-color: transparent !important;
        right: -5px;
        top: calc(50% - 5px);
        margin-left: 0;
        margin-right: 0;
      }
    }

    /*
      We already have a popover component in the global styles. Thus we need to pair
      it with teacher-dashboard-tooltip to avoid breaking styles elsewhere on the site.
    */
    &.popover.teacher-dashboard-tooltip {
      border-image: unset;
      border-width: unset;
      border-style: unset;
      max-width: unset;

      box-shadow: -2px -4px 20px rgba(0, 0, 0, 0.25), 2px 4px 20px rgba(0, 0, 0, 0.25);
      -webkit-box-shadow: -2px -4px 20px rgba(0, 0, 0, 0.25), 2px 4px 20px rgba(0, 0, 0, 0.25);

      .popover-inner {
        box-shadow: unset;
        padding: 18px;
      }

      .popover-arrow {
        border-color: white;
      }
    }

    &[aria-hidden='true'] {
      visibility: hidden;
      opacity: 0;
      transition: opacity .15s, visibility .15s;
    }

    &[aria-hidden='false'] {
      visibility: visible;
      opacity: 1;
      transition: opacity .15s;
    }
  }

  /* Tooltip style overrides */
  .tooltip.teacher-dashboard-tooltip {

    &.getting-started-all-classes {
      z-index: 500;

      .tooltip-arrow {
        /* Center the arrow between the two buttons */
        transform: translateX(-15px);
      }
    }

    .tooltip-arrow {
      border-color: white;
    }

    .tooltip-inner {
      text-align: left;

      border-radius: 5px;
      background-color: white;
      color: #131b25;
      box-shadow: -2px -4px 20px rgba(0, 0, 0, 0.25), 2px 4px 20px rgba(0, 0, 0, 0.25);
      max-width: 378px;
      padding: 22px;

      font-family: "Work Sans";
      font-style: normal;
      font-size: 14px;
      letter-spacing: 0.26667px;

      p {
        margin: 0 0 5px 0;
        line-height: 18px;
      }

      p:last-child {
        margin: 0;
      }

      p.small {
        line-height: 14px;
        font-size: 12px;
      }

      h3 {
        margin: 0;
        color: #131b25;
        font-family: "Work Sans";
        font-style: normal;
        font-size: 17px;
        line-height: 22px;
        margin-bottom: 5px;

        font-variant: unset;
      }
    }
  }

  .tooltip.lighter-p {
    .tooltip-inner p {
      color: #656565;
    }
  }

  .tooltip.large-width {
    .tooltip-inner {
      width: 492px;
      max-width: unset;
    }
  }

  /* Tooltip style overrides */
  .tooltip.dark-teacher-dashboard {
    .tooltip-inner {
      font-family: "Work Sans";
      font-style: normal;
      font-size: 14px;
      line-height: 16px;
      letter-spacing: 0.26667px;

      padding: 10px 14px;
      border-radius: 2px;

      background-color: #131b25;
      max-width: 216px;
    }

    .tooltip-arrow {
      border-color: #131b25;
    }
  }
</style>
