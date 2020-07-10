<script>
  import { mapState } from 'vuex'

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

      classesTabSelected () {
        return this.$route.path.startsWith('/teachers/classes') || this.$route.path === '/teachers'
      },

      studentProjectsSelected () {
        return this.$route.path.startsWith('/teachers/projects')
      },

      licensesSelected () {
        return this.$route.path.startsWith('/teachers/licenses')
      },

      resourceHubSelected () {
        return this.$route.path.startsWith('/teachers/resources')
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
        :class="['dropdown-toggle', classesTabSelected ? 'current-route': '']"
        href="#"
        role="button"
        data-toggle="dropdown"
        aria-haspopup="true"
        aria-expanded="false"
      >
        <div id="IconMyClasses" />
        <span>MY CLASSES</span>
        <span class="caret" />
      </a>
      <ul
        class="dropdown-menu"
        aria-labelledby="ClassesDropdown"
      >
        <li :class="allClassesSelected ? 'selected': null">
          <router-link tag="a" to="/teachers" class="dropdown-item underline-item">ALL CLASSES</router-link>
        </li>
        <li
          v-for="classroom in classrooms"
          :key="classroom._id"
          :class="classesTabSelected && classroomSelected === classroom._id ? 'selected': null"
        >
          <router-link
            tag="a"
            :to="`/teachers/classes/${classroom._id}`"
            class="dropdown-item"
          >
            {{ classroom.name }}
          </router-link>
        </li>
      </ul>
    </li>
    <li
      role="presentation"
      class="dropdown"
    >
      <a
        id="ProjectsDropdown"
        :class="['dropdown-toggle', studentProjectsSelected ? 'current-route': '']"
        href="#"
        role="button"
        data-toggle="dropdown"
        aria-haspopup="true"
        aria-expanded="false"
      >
        <div id="IconCapstone" />
        <span>STUDENT PROJECTS</span>
        <span class="caret" />
      </a>
      <ul
        class="dropdown-menu"
        aria-labelledby="ProjectsDropdown"
      >
        <li
          v-for="classroom in classrooms"
          :key="classroom._id"
          :class="classroomSelected === classroom._id && studentProjectsSelected ? 'selected': null"
        >
          <router-link
            :to="`/teachers/projects/${classroom._id}`"
            class="dropdown-item"
          >
            {{ classroom.name }}
          </router-link>
        </li>
      </ul>
    </li>
    <li><router-link to="/teachers/licenses" id="LicensesAnchor" :class="{ 'current-route': licensesSelected }"><div id="IconLicense" />My Licenses</router-link></li>
    <li><router-link to="/teachers/resources" id="ResourceAnchor" :class="{ 'current-route': resourceHubSelected }"><div id="IconResourceHub" />Resource Hub</router-link></li>
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
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconMyClasses.svg);
  margin-top: -6px;
}

/* Need aria-expanded for when user has mouse in the dropdown */
#ProjectsDropdown:hover, #ProjectsDropdown.current-route, #ProjectsDropdown[aria-expanded="true"] {
  #IconCapstone {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_Capstone_Blue.svg);
  }
}

#ClassesDropdown:hover, #ClassesDropdown.current-route, #ClassesDropdown[aria-expanded="true"]  {
  #IconMyClasses {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconMyClasses_Blue.svg);
  }
}

#LicensesAnchor:hover , #LicensesAnchor.current-route {
  #IconLicense {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconLicense_Blue.svg);
  }
}

#ResourceAnchor:hover, #ResourceAnchor.current-route {
  #IconResourceHub {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconResourceHub_Blue.svg);
  }
}

#IconLicense {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconLicense.svg);
  margin-top: -2px;
}

#IconResourceHub{
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconResourceHub_White.svg);
  margin-top: -3px;
}

#IconCapstone, #IconMyClasses, #IconLicense, #IconResourceHub {
  height: 23px;
  width: 23px;
  display: inline-block;
  background-repeat: no-repeat;
  background-position: center;

  margin-right: 8px;
}

#secondaryNav {
  display: flex;
  flex-direction: row;
  justify-content: flex-start;
  padding-left: 23.5px;
  height: 35px;
  min-height: 35px;

  background-color: $pitch;

  & > li {
    height: 35px;
    width: 230px;
    text-align: center;
    margin: 0 6.5px;

    display: flex;
    justify-content: center;
    align-items: center;

    background-color: $twilight;
    border-radius: 10px 10px 0 0;

    a.current-route {
      background-color: $white;
      color: $twilight;
    }

    &.dropdown.open > a, & > a:hover {
      background-color: $white;
      color: $twilight;
    }

    a {
      @include font-h-4-navbar-uppercase-white;
      font-size: 14px;

      width: 100%;
      height: 100%;
      padding: 0;

      display:flex;
      flex-direction: row;
      align-items: center;
      justify-content: center;

      & > img {
        margin-top: -6px;
        margin-right: 13px;
      }
    }

    & > a {
      padding-top: 3px;
      border-radius: 10px 10px 0 0;
    }

    .dropdown-menu {
      a {
        color: $twilight;
        height: 35px;
        text-align: left;

        justify-content: start;
        justify-content: flex-start;
      }

      min-width: 230px;
      padding: 0 20px;
    }

    li.selected a {
      color: #979797
    }

    li .underline-item {
      border-bottom: 1px solid #ddd;
    }
  }
}
</style>
