<script>
import { mapState } from 'vuex'
import utils from 'core/utils'

export default {
  props: {
    classrooms: {
      type: Array,
      default: () => []
    }
  },

  computed: {
    ...mapState('teacherDashboard', {
      currentSelectedClassroom: state => state.classroomId
    }),

    isCodeCombat () {
      return utils.isCodeCombat
    },

    classesTabSelected () {
      return this.$route.path.startsWith('/teachers/classes') || this.$route.path === '/teachers'
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
      if (utils.isCodeCombat && me.isCodeNinja()) {
        return false
      }
      return true
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
  },

  methods: {
    isCurrentRoute (route) {
      return this.$route.path.startsWith(route)
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
    }
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
          v-for="classroom in classrooms"
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
          v-for="classroom in classrooms"
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
    <li>
      <router-link
        id="ResourceAnchor"
        to="/teachers/resources"
        :class="{ 'current-route': isCurrentRoute('/teachers/resources') }"
        data-action="Resource Hub: Nav Clicked"
        @click.native="trackEvent"
      >
        <div id="IconResourceHub" />
        {{ $t('teacher_dashboard.resource_hub') }}
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
        {{ $t('teacher_dashboard.my_licenses') }}
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
        :class="['dropdown-toggle', isCurrentRoute('/teachers/projects') ? 'current-route' : '']"
        href="#"
        role="button"
        data-toggle="dropdown"
        aria-haspopup="true"
        aria-expanded="false"
      >
        <div id="IconAssessments" />
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
            data-action="Student Assessments: Nav Clicked"
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
      <router-link
        id="AILeague"
        to="/teachers/ai-league"
        :class="{ 'current-route': isCurrentRoute('/teachers/ai-league') }"
        data-action="AI League: Nav Clicked"
        @click.native="trackEvent"
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
      </router-link>
    </li>
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

/* Need aria-expanded for when user has mouse in the dropdown */
#ProjectsDropdown:hover {
  #IconCapstone {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_Capstone_Moon.svg);
  }
}

li.open > #ProjectsDropdown,
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

li.open > #ClassesDropdown,
#ClassesDropdown.current-route,
#ClassesDropdown[aria-expanded="true"] {
  #IconMyClasses {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconMyClasses_Blue.svg);
  }
}

#LicensesAnchor:hover{
  #IconLicense {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconLicense_Moon.svg);
  }
}

li.open > #LicensesAnchor,
#LicensesAnchor.current-route {
  #IconLicense {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconLicense_Blue.svg);
  }
}

#ResourceAnchor:hover{
  #IconResourceHub {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconResourceHub_Moon.svg);
  }
}

li.open > #ResourceAnchor,
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

li.open > #PDAnchor,
#PDAnchor.current-route {
  #IconPD {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconPD_Blue.svg);
  }
}

#AssessmentsDropdown:hover {
  #IconAssessments {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_Assessments_Moon.svg);
  }
}

li.open > #AssessmentsDropdown,
#AssessmentsDropdown.current-route,
#AssessmentsDropdown[aria-expanded="true"] {
  #IconAssessments {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_Assessments_Blue.svg);
  }
}

#AILeague{
  .league-name {
    display: none;
    &__gray {
      display: block;
    }
  }
}

#AILeague:hover{
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

li.open > #AILeague,
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
#IconLicense,
#IconResourceHub,
#IconPD,
#IconAssessments,
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

    &:hover{
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

      a {
        color: #131B25;
        height: 50px;
        text-align: left;

        padding-left: 30px;

        justify-content: start;
        justify-content: flex-start;
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
</style>
