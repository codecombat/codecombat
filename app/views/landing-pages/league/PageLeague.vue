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
      title: this.$t('schools_page.practice_enrichment_1_title'),
      meta: [
        { name: 'viewport', content: 'width=device-width, initial-scale=1, viewport-fit=cover' },
        { vmid: 'meta-description', name: 'description', content: this.$t('league.codecombat_ai_league_description') },
      ],
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
