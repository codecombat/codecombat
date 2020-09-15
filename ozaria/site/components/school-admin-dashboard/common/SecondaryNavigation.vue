<script>
  import { COMPONENT_NAMES, PAGE_TITLES } from './constants'
  export default {
    computed: {
      schoolsTabSelected () {
        return this.$route.path === '/school-administrator' || this.$route.path.startsWith('/school-administrator/teacher')
      },

      licensesTabSelected () {
        return this.$route.path.startsWith('/school-administrator/licenses')
      },

      schoolTabsTitle () {
        return PAGE_TITLES[COMPONENT_NAMES.MY_SCHOOLS]
      },

      licensesTabTitle () {
        return PAGE_TITLES[COMPONENT_NAMES.SCHOOL_ADMIN_LICENSES]
      }
    },

    methods: {
      trackEvent (e) {
        const eventName = e.target.dataset['action']
        const eventLabel = e.target.dataset['label']
        if (eventName) {
          if (eventLabel) {
            window.tracker?.trackEvent(eventName, { category: 'SchoolAdmin', label: eventLabel })
          } else {
            window.tracker?.trackEvent(eventName, { category: 'SchoolAdmin' })
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
    <li>
      <router-link
        id="SchoolsAnchor"
        to="/school-administrator"
        :class="{ 'current-route': schoolsTabSelected } "
        data-action="My Schools: Nav Clicked"
        @click.native="trackEvent"
      >
        <div id="IconSchools" /> {{ schoolTabsTitle }}
      </router-link>
    </li>
    <li>
      <router-link
        id="LicensesAnchor"
        to="/school-administrator/licenses"
        :class="{ 'current-route': licensesTabSelected }"
        data-action="Admin Licenses: Nav Clicked"
        @click.native="trackEvent"
      >
        <div id="IconLicense" /> {{ licensesTabTitle }}
      </router-link>
    </li>
  </ul>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#LicensesAnchor:hover , #LicensesAnchor.current-route {
  #IconLicense {
    background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconLicense_Blue.svg);
  }
}

#IconLicense {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconLicense.svg);
  margin-top: -2px;
}

#SchoolsAnchor:hover , #SchoolsAnchor.current-route {
  #IconSchools {
    background-image: url(/images/ozaria/school-admins/dashboard/svg_icons/IconSchools_Blue.svg);
  }
}

#IconSchools {
  background-image: url(/images/ozaria/school-admins/dashboard/svg_icons/IconSchools.svg);
  margin-top: -2px;
}

#IconLicense, #IconSchools {
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

    & > a:hover {
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

    li.selected a {
      color: #979797
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
