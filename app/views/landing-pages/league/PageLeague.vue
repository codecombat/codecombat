<style scoped>
</style>

<template>
    <div id="page-league">
      <!-- Key ensures any change of url re-renders component -->
      <router-view :key="$route.fullPath"></router-view>
    </div>
</template>

<script>
    import { mapGetters, mapActions } from 'vuex'

    export default {
      metaInfo () {
        return {
          title: 'Competitive AI coding esports from CodeCombat',
          meta: [
            { name: 'viewport', content: 'width=device-width, initial-scale=1' }
          ]
        }
      },

      created () {
        this.fetchRequiredInitialData({ optionalIdOrSlug: this.$route.params.idOrSlug })
      },

      computed: {
        ...mapGetters({
          isLoading: 'seasonalLeague/isLoading'
        }),
      },

      methods: {
        ...mapActions({
          fetchRequiredInitialData: 'clans/fetchRequiredInitialData'
        })
      }
    }
</script>

<style lang="scss" scoped>
$background: #0C1016;
#page-league {
  background-color: $background;

  padding-bottom: 50px;
  margin-bottom: -50px;
}
</style>

<style lang="scss">
/* Global navigation styles */
nav#main-nav.navbar.dark-mode {
  background-color: #0C1016;

  .nav > li > a {
    color: #FCBB00;

    &:hover {
      color: #FF39A6;
    }
  }

  .dashboard-toggle {
    border: 1px solid #FCBB00;

    & > .show-divider {
      border-right: 1px solid #FCBB00 !important;
    }
  }

  .dashboard-toggle .dashboard-button a {
    color: #FCBB00;
  }

  .dropdown-menu {
    background-color: white;
  }

  #create-account-link {
    background-color: #FCBB00;
    border: 1px solid #FCBB00;
    color: #0C1016;

    &:hover {
      background-color: #FF39A6;
      border: 1px solid #FF39A6;
    }
  }

  #login-link {
    color: #FCBB00;
    border: 1px solid #FCBB00;

    &:hover {
      background-color: #FF39A6;
      border: 1px solid #FF39A6;
      color: #0C1016;
    }
  }
}
</style>