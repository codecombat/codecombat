<template>
  <div id="page-league">
    <!-- Key ensures any change of url re-renders component -->
    <router-view :key="$route.fullPath" />
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
    })
  },

  methods: {
    ...mapActions({
      fetchRequiredInitialData: 'clans/fetchRequiredInitialData'
    })
  }
}
</script>

<style scoped>
</style>

<style lang="scss" scoped>
$background: #0C1016;
#page-league {
  background-color: $background;

  padding-bottom: 50px;
  margin-bottom: -50px;
}
</style>
