<script>
import { mapState, mapGetters } from 'vuex'
import utils from 'core/utils'
import DashboardToggle from 'ozaria/site/components/teacher-dashboard/common/DashboardToggle'
import sortClassroomMixin from '../mixins/sortClassroomMixin.js'
import ModalHackStackBeta from 'ozaria/site/components/teacher-dashboard/modals/ModalHackStackBeta.vue'
import ModalTestStudentPromotion from 'ozaria/site/components/teacher-dashboard/modals/ModalTestStudentPromotion.vue'
import ModalCurriculumPromotion from 'ozaria/site/components/teacher-dashboard/modals/ModalCurriculumPromotion.vue'
import ModalOzariaHackStack from 'ozaria/site/components/teacher-dashboard/modals/ModalOzariaHackStack'
import ModalOzariaAILeague from 'ozaria/site/components/teacher-dashboard/modals/ModalOzariaAILeague'
import IconAI from 'ozaria/site/components/teacher-dashboard/common/NavIconAI'
import IconAPCSP from 'ozaria/site/components/teacher-dashboard/common/NavIconAPCSP'
import IconAssessments from 'ozaria/site/components/teacher-dashboard/common/NavIconAssessments'

export default {
  components: {
    DashboardToggle,
    ModalHackStackBeta,
    ModalTestStudentPromotion,
    ModalCurriculumPromotion,
    ModalOzariaHackStack,
    ModalOzariaAILeague,
    IconAI,
    IconAPCSP,
    IconAssessments
  },

  mixins: [
    sortClassroomMixin
  ],

  props: {
    classrooms: {
      type: Array,
      default: () => []
    }
  },

  data: () => {
    return {
      curriculumPromoClicked: false,
    }
  },

  computed: {
    ...mapState('teacherDashboard', {
      currentSelectedClassroom: state => state.classroomId
    }),

    ...mapGetters({
      topModal: 'modals/getTopModal'
    }),

    isCodeCombat () {
      return utils.isCodeCombat
    },

    isOzaria () {
      return utils.isOzaria
    },

    classesTabSelected () {
      return this.$route.path.startsWith('/teachers/classes') || this.$route.path === '/teachers'
    },

    hackstackClassesTabSelected () {
      return this.$route.path.startsWith('/teachers/hackstack-classes')
    },

    // Check for the "All Classes" dropdown menu button in the classesTab.
    allClassesSelected () {
      return this.$route.path === '/teachers' || this.$route.path === '/teachers/classes'
    },

    classroomSelected () {
      if (this.allClassesSelected) {
        return undefined
      }
      return this.currentSelectedClassroom
    },

    showStudentProjects () {
      // TODO: do show the student projects if it is Code Ninjas, but not in a camp context
      if (utils.isCodeCombat) {
        return false
      }
      return true
    },

    hackStackClassrooms () {
      const classrooms = this.classrooms
        .filter(classroom => classroom.courses.map(course => course._id).includes(utils.courseIDs.HACKSTACK))
      classrooms.sort(this.classroomSortById)
      return classrooms
    },

    showHackStack () {
      return utils.isCodeCombat
    },

    showPD () {
      return !me.isCodeNinja()
    },

    showLicenses () {
      return !me.isCodeNinja()
    },

    showAssessments () {
      // TODO: do show the assessments if it is CodeNinjas, but not in a camp context
      return utils.isCodeCombat && !me.isCodeNinja()
    },

    showAIJunior () {
      return me.isAdmin()
    },

    sortedClasses () {
      const classrooms = [...this.classrooms]
      classrooms.sort(this.classroomSortById)
      return classrooms
    },

    isCurriculumModalVisible () {
      return this.topModal?.name === 'curriculum-sidebar-promotion-modal'
    }
  },

  methods: {
    isCurrentRoute (route) {
      return this.$route.path.startsWith(route)
    },

    setHackStackClassroom (classroomId) {
      this.$store.commit('teacherDashboard/setClassroomId', classroomId)
      this.$store.commit('teacherDashboard/setSelectedCourseIdCurrentClassroom', { courseId: utils.courseIDs.HACKSTACK })
    },

    onCurriculumClicked (e) {
      this.$refs.modalCurriculumPromotion.close()
      this.trackEvent(e)
    },

    trackEvent (e) {
      const eventName = e.target.dataset.action
      const eventLabel = e.target.dataset.label
      if (eventName) {
        if (eventLabel) {
          window.tracker?.trackEvent(eventName, { category: 'Teachers', label: eventLabel })
        } else {
          window.tracker?.trackEvent(eventName, { category: 'Teachers' })
        }
      }
    },
    hackstackClicked () {
      if (utils.isOzaria) {
        this.$refs.modalOzariaHackStack.openModal()
        return
      }
      if (this.hackStackClassrooms.length === 0) {
        noty({ text: $.i18n.t('teacher_dashboard.create_class_hackstack'), type: 'warning', layout: 'center', timeout: 5000 })
      }
    },
    AILeagueClicked () {
      if (utils.isOzaria) {
        this.$refs.ModalOzariaAILeague.openModal()
      }
    },
  }
}
</script>

<template>
  <ul
    id="secondaryNav"
    class="nav"
    role="navigation"
  >
    <li
      role="presentation"
      class="dropdown"
    >
      <a
        id="ClassesDropdown"
        :class="['dropdown-toggle', classesTabSelected ? 'current-route' : '']"
        href="#"
        role="button"
        data-toggle="dropdown"
        aria-haspopup="true"
        aria-expanded="false"
      >
        <div id="IconMyClasses" />
        <span>{{ $t('nav.my_classrooms') }}</span>
        <span class="caret" />
      </a>
      <ul
        class="dropdown-menu"
        aria-labelledby="ClassesDropdown"
      >
        <li :class="allClassesSelected ? 'selected' : null">
          <router-link
            tag="a"
            to="/teachers"
            class="dropdown-item underline-item"
            data-action="All Classes: Nav Clicked"
            data-toggle="dropdown"
            @click.native="trackEvent"
          >
            {{ $t('teacher_dashboard.all_classes') }}
          </router-link>
        </li>
        <li
          v-for="classroom in sortedClasses"
          :key="classroom._id"
          :class="classesTabSelected && classroomSelected === classroom._id ? 'selected' : null"
        >
          <router-link
            tag="a"
            :to="`/teachers/classes/${classroom._id}`"
            class="dropdown-item"
            data-action="Track Progress: Nav Clicked"
            data-toggle="dropdown"
            :data-label="$route.path"
            @click.native="trackEvent"
          >
            {{ classroom.name }}
          </router-link>
        </li>
      </ul>
    </li>

    <li
      v-if="showStudentProjects"
      role="presentation"
      class="dropdown"
    >
      <a
        id="ProjectsDropdown"
        :class="['dropdown-toggle', isCurrentRoute('/teachers/projects') ? 'current-route' : '']"
        href="#"
        role="button"
        data-toggle="dropdown"
        aria-haspopup="true"
        aria-expanded="false"
      >
        <div id="IconCapstone" />
        <span>{{ $t('teacher_dashboard.student_projects') }}</span>
        <span class="caret" />
      </a>
      <ul
        v-if="classrooms.length > 0"
        class="dropdown-menu"
        aria-labelledby="ProjectsDropdown"
      >
        <li
          v-for="classroom in sortedClasses"
          :key="classroom._id"
          :class="classroomSelected === classroom._id && isCurrentRoute('/teachers/projects') ? 'selected' : null"
        >
          <router-link
            :to="`/teachers/projects/${classroom._id}`"
            class="dropdown-item"
            data-action="Student Projects: Nav Clicked"
            data-toggle="dropdown"
            @click.native="trackEvent"
          >
            {{ classroom.name }}
          </router-link>
        </li>
      </ul>
      <ul
        v-else
        class="dropdown-menu"
        aria-labelledby="ProjectsDropdown"
      >
        <li>
          <a class="dropdown-item disabled-item">
            {{ $t('teacher_dashboard.no_classes_yet') }}
          </a>
        </li>
      </ul>
    </li>
    <li :class="{ 'modal-highlight': isCurriculumModalVisible }">
      <router-link
        id="CurriculumAnchor"
        to="/teachers/curriculum"
        :class="{ 'current-route': isCurrentRoute('/teachers/curriculum') || isCurriculumModalVisible }"
        data-action="Curriculum Guide: Nav Clicked"
        @click.native="onCurriculumClicked"
      >
        <div id="IconCurriculum" />
        {{ $t('teacher_dashboard.curriculum') }}
      </router-link>
    </li>
    <li>
      <router-link
        id="ResourceAnchor"
        to="/teachers/resources"
        :class="{ 'current-route': isCurrentRoute('/teachers/resources') }"
        data-action="Resource Hub: Nav Clicked"
        @click.native="trackEvent"
      >
        <div id="IconResourceHub" />
        <span>{{ $t('teacher_dashboard.resource_hub') }}</span>
      </router-link>
    </li>

    <li v-if="showLicenses">
      <router-link
        id="LicensesAnchor"
        to="/teachers/licenses"
        :class="{ 'current-route': isCurrentRoute('/teachers/licenses') }"
        data-action="My Licenses: Nav Clicked"
        @click.native="trackEvent"
      >
        <div id="IconLicense" />
        <span>{{ $t('teacher_dashboard.my_licenses') }}</span>
      </router-link>
    </li>

    <li v-if="showPD">
      <router-link
        id="PDAnchor"
        to="/teachers/professional-development"
        :class="{ 'current-route': isCurrentRoute('/teachers/professional-development') }"
        data-action="PD: Nav Clicked"
        @click.native="trackEvent"
      >
        <div id="IconPD" />
        <!-- <div id="IconNew">New!</div> -->
        {{ $t('teacher_dashboard.pd_short') }}
      </router-link>
    </li>

    <li v-if="showAssessments">
      <a
        id="AssessmentsDropdown"
        :class="['dropdown-toggle', isCurrentRoute('/teachers/assessments') ? 'current-route' : '']"
        href="#"
        role="button"
        data-toggle="dropdown"
        aria-haspopup="true"
        aria-expanded="false"
      >
        <IconAssessments class="icon-assessments svgicon default" />
        <IconAssessments
          class="icon-assessments svgicon hovered"
          theme="moon"
        />
        <IconAssessments
          class="icon-assessments svgicon selected"
          theme="blue"
        />
        <span>{{ $t('teacher_dashboard.assessments_tab') }}</span>
        <span class="caret" />
      </a>
      <ul
        v-if="classrooms.length > 0"
        class="dropdown-menu"
        aria-labelledby="AssessmentsDropdown"
      >
        <li
          v-for="classroom in classrooms"
          :key="classroom._id"
          :class="classroomSelected === classroom._id && isCurrentRoute('/teachers/assessments') ? 'selected' : null"
        >
          <router-link
            :to="`/teachers/assessments/${classroom._id}`"
            class="dropdown-item"
            data-action="Assessments: Nav Clicked"
            data-toggle="dropdown"
            @click.native="trackEvent"
          >
            {{ classroom.name }}
          </router-link>
        </li>
      </ul>
      <ul
        v-else
        class="dropdown-menu"
        aria-labelledby="AssessmentsDropdown"
      >
        <li>
          <a class="dropdown-item disabled-item">
            {{ $t('teacher_dashboard.no_classes_yet') }}
          </a>
        </li>
      </ul>
    </li>
    <li>
      <component
        :is="isCodeCombat ? 'router-link' : 'a'"
        id="AILeague"
        to="/teachers/ai-league"
        :class="{ 'current-route': isCurrentRoute('/teachers/ai-league') }"
        data-action="AI League: Nav Clicked"
        @click="AILeagueClicked"
      >
        <div id="IconKeepPlaying" />
        <img
          class="league-name league-name__gray"
          src="/images/pages/league/ai-league-name.svg"
        >
        <img
          class="league-name league-name__moon"
          src="/images/pages/league/ai-league-name_moon.svg"
        >
        <img
          class="league-name league-name__blue"
          src="/images/pages/league/ai-league-name_blue.svg"
        >
      </component>
    </li>
    <li
      role="presentation"
      class="dropdown"
      @click="hackstackClicked"
    >
      <a
        id="HackstackClassesDropdown"
        :class="['dropdown-toggle', hackstackClassesTabSelected ? 'current-route' : '']"
        href="#"
        role="button"
        data-toggle="dropdown"
        aria-haspopup="true"
        aria-expanded="false"
      >
        <IconAI class="icon-ai svgicon default" />
        <IconAI
          class="icon-ai svgicon hovered"
          theme="moon"
        />
        <IconAI
          class="icon-ai svgicon selected"
          theme="blue"
        />
        <span>{{ $t('nav.ai_hackstack') }}</span>
        <span
          v-if="showHackStack && hackStackClassrooms?.length > 0"
          class="caret"
        />
      </a>
      <ul
        v-if="showHackStack"
        class="dropdown-menu"
        aria-labelledby="HackstackClassesDropdown"
      >
        <li
          v-for="classroom in hackStackClassrooms"
          :key="classroom._id"
          :class="hackstackClassesTabSelected && classroomSelected === classroom._id ? 'selected' : null"
        >
          <router-link
            tag="a"
            :to="`/teachers/hackstack-classes/${classroom._id}`"
            class="dropdown-item"
            data-action="Track Progress: Nav Clicked"
            data-toggle="dropdown"
            :data-label="$route.path"
            @click.native="trackEvent($event); setHackStackClassroom(classroom._id)"
          >
            {{ classroom.name }}
          </router-link>
        </li>
      </ul>
    </li>

    <li v-if="showAIJunior">
      <a
        id="AIJuniorDropdown"
        :class="['dropdown-toggle', isCurrentRoute('/teachers/ai-junior') ? 'current-route' : '']"
        href="#"
        role="button"
        data-toggle="dropdown"
        aria-haspopup="true"
        aria-expanded="false"
      >
        <div id="IconAIJunior" />
        <span>{{ $t('teacher_dashboard.ai_hackstack_junior_tab') }}</span>
        <span class="caret" />
      </a>
      <ul
        v-if="classrooms.length > 0"
        class="dropdown-menu"
        aria-labelledby="AIJuniorDropdown"
      >
        <li
          v-for="classroom in classrooms"
          :key="classroom._id"
          :class="classroomSelected === classroom._id && isCurrentRoute('/teachers/ai-junior') ? 'selected' : null"
        >
          <router-link
            :to="`/teachers/ai-junior/${classroom._id}`"
            class="dropdown-item"
            data-action="AIJunior: Nav Clicked"
            data-toggle="dropdown"
            @click.native="trackEvent"
          >
            {{ classroom.name }}
          </router-link>
        </li>
      </ul>
      <ul
        v-else
        class="dropdown-menu"
        aria-labelledby="AIJuniorDropdown"
      >
        <li>
          <a class="dropdown-item disabled-item">
            {{ $t('teacher_dashboard.no_classes_yet') }}
          </a>
        </li>
      </ul>
    </li>

    <li v-if="showPD">
      <router-link
        id="PDAnchor"
        to="/teachers/apcsp"
        :class="{ 'current-route': isCurrentRoute('/teachers/apcsp') }"
        data-action="APCSP: Nav Clicked"
        @click.native="trackEvent"
      >
        <IconAPCSP class="icon-apcsp svgicon default" />
        <IconAPCSP
          class="icon-apcsp svgicon hovered"
          theme="moon"
        />
        <IconAPCSP
          class="icon-apcsp svgicon selected"
          theme="blue"
        />
        {{ $t('teacher_dashboard.apcsp') }}
      </router-link>
    </li>
    <li>
      <dashboard-toggle
        v-if="isCodeCombat"
        class="dashboard-toggle"
        size="sm"
        :show-title="true"
        reload-location="/teachers/classes"
      />
    </li>
    <ModalCurriculumPromotion ref="modalCurriculumPromotion" />
    <ModalHackStackBeta
      v-if="showHackStack"
      :href="hackStackClassrooms.length > 0 ? `/teachers/hackstack-classes/${hackStackClassrooms[0]._id}` : '#'"
      @tryClicked="hackstackClicked"
    />
    <ModalOzariaHackStack
      v-if="isOzaria"
      ref="modalOzariaHackStack"
    />
    <ModalOzariaAILeague
      v-if="isOzaria"
      ref="ModalOzariaAILeague"
    />
    <ModalTestStudentPromotion />
  </ul>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#IconCapstone {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_Capstone.svg);
  margin-top: -1px;
}

#IconMyClasses {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconMyClasses_Gray.svg);
  margin-top: -6px;
}

.svgicon {
  background-image: none;
  width: 37px;
  height: 37px;
}

.icon-ai {
  margin-top: -6px;
  margin-left: -2px;
}

.icon-apcsp {
  margin-top: -3px;
  transform: scale(1.6);
}

.icon-assessments {
  transform: scale(0.75) translateX(-4px);
}

.svgicon {
  display: block;
  &.hovered,
  &.selected {
    display: none;
  }
}

li:hover:not(.open)>*,
li:not(.open)>*:hover:not(.current-route) {
  > .svgicon {
    display: block;
    &.default,
    &.selected {
      display: none;
    }
  }
}

li.open>*,
li>*.current-route {
 > .svgicon {
    display: block;
    &.default,
    &.hovered {
      display: none;
    }
  }
}

/* Need aria-expanded for when user has mouse in the dropdown */
#ProjectsDropdown:hover {
  #IconCapstone {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_Capstone_Moon.svg);
  }
}

li.open>#ProjectsDropdown,
#ProjectsDropdown.current-route,
#ProjectsDropdown[aria-expanded="true"] {
  #IconCapstone {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_Capstone_Blue.svg);
  }
}

#ClassesDropdown:hover {
  #IconMyClasses {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconMyClasses_Moon.svg);
  }
}

li.open>#ClassesDropdown,
#ClassesDropdown.current-route,
#ClassesDropdown[aria-expanded="true"] {
  #IconMyClasses {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconMyClasses_Blue.svg);
  }
}

#LicensesAnchor:hover {
  #IconLicense {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconLicense_Moon.svg);
  }
}

li.open>#LicensesAnchor,
#LicensesAnchor.current-route {
  #IconLicense {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconLicense_Blue.svg);
  }
}

#CurriculumAnchor:hover {
  #IconCurriculum {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_Assessments_Moon.svg);
  }
}

li.open>#CurriculumAnchor,
#CurriculumAnchor.current-route {
  #IconCurriculum {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_Assessments_Blue.svg);
  }
}

#ResourceAnchor:hover {
  #IconResourceHub {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconResourceHub_Moon.svg);
  }
}

li.open>#ResourceAnchor,
#ResourceAnchor.current-route {
  #IconResourceHub {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconResourceHub_Blue.svg);
  }
}

#PDAnchor:hover {
  #IconPD {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconPD_Moon.svg);
  }
}

li.open>#PDAnchor,
#PDAnchor.current-route {
  #IconPD {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconPD_Blue.svg);
  }
}

#AILeague {
  .league-name {
    display: none;

    &__gray {
      display: block;
    }
  }
}

#AILeague:hover {
  .league-name {
    display: none;

    &__moon {
      display: block;
    }
  }

  #IconKeepPlaying {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconKeepPlaying_Moon.svg);
  }
}

li.open>#AILeague,
#AILeague.current-route {
  .league-name {
    display: none;

    &__blue {
      display: block;
    }
  }

  #IconKeepPlaying {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconKeepPlaying_Blue.svg);
  }
}

#IconKeepPlaying {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconKeepPlaying_Gray.svg);
  margin-top: -2px;
}

#IconCurriculum {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_Assessments_Gray.svg);
  margin-top: -3px;
}

#IconLicense {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconLicense_Gray.svg);
  margin-top: -3px;
}

#IconResourceHub {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconResourceHub_Gray.svg);
  margin-top: -3px;
}

#IconPD {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconPD_Gray.svg);
  margin-top: -3px;
}

#IconAssessments {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_Assessments_Gray.svg);
  margin-top: -3px;
}

#IconAIJunior {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_Capstone.svg);
  margin-top: -1px;
}

#AIJuniorDropdown:hover,
#AIJuniorDropdown.current-route,
#AIJuniorDropdown[aria-expanded="true"] {
  #IconAIJunior {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_Capstone_Blue.svg);
  }
}

#IconNew {
  height: 32px;
  width: 32px;
  position: absolute;
  right: 1px;
  top: 1px;
  border-radius: 32px;
  background-color: #e83027;
  color: white;
  font-size: 12px;
  transform: rotate(-20deg);
  text-transform: capitalize;
}

#IconCapstone,
#IconMyClasses,
#IconCurriculum,
#IconLicense,
#IconResourceHub,
#IconPD,
#IconAssessments,
#IconAIJunior,
#IconKeepPlaying {
  height: 23px;
  width: 29px;
  display: inline-block;
  background-repeat: no-repeat;
  background-position: center;

  margin-right: 8px;
}

#secondaryNav {
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  height: min-content;

  &>li {

    &:hover {
      >a {
        background-color: #355EA0;
        color: #f7d047;
      }
    }

    &.dropdown.open>a,
    a.current-route {
      border: none;
      background: #E2EBFA;
      color: #476FB1;
    }

    a {
      height: 60px;
      color: #545B64;
      background-color: transparent;
      font-size: 18px;
      font-weight: 600;
      font-family: "Work Sans", sans-serif;

      width: 100%;
      padding: 0;

      padding-left: 10px;

      display: flex;
      gap: 10px;
      flex-direction: row;
      align-items: center;
      justify-content: flex-start;

      &>img {
        margin-top: -6px;
        margin-right: 13px;
      }

      &>span {
        max-width: 180px;
        text-wrap: wrap;
      }
    }

    &>a {
      white-space: nowrap;
    }

    .dropdown-menu {
      position: relative;
      padding: 0;
      margin: 0;
      width: 100%;
      border: none;
      border-radius: none;
      background: transparent;
      box-shadow: none;

      li:hover {
        background-color: #C5D4ED;
      }

      li {
        height: 50px;
        display: flex;
        align-items: center;
        justify-content: flex-start;
      }

      a {
        color: #131B25;
        line-height: 50px;
        height: auto;
        text-align: left;
        display: block;
        overflow: hidden;
        text-overflow: ellipsis;
        padding-left: 30px;

        &:hover {
          background-color: transparent;
        }
      }
    }

    li.selected a {
      color: #476FB1;
      background: #E2EBFA;
    }

    li .underline-item {
      border-bottom: 1px solid #ddd;
    }

    li .disabled-item {
      color: #979797;
      cursor: default;
    }

  }
}

.modal-highlight {
  z-index: 10000;
}

.dashboard-toggle {
  margin: 5px 0 10px;
}

.beta {
  font-size: 12px;
  line-height: 15px;
  position: relative;
  bottom: 5px;
}
</style>
