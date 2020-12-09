<style scoped>
</style>

<template>
    <div>
        <div class="container">
            <h1>Loading: {{  isLoading }}</h1>
            <router-view></router-view>
        </div>
    </div>
</template>

<script>
    import { mapGetters, mapActions } from 'vuex'

    export default {
      metaInfo () {
        return {
          title: 'League'
        }
      },

      created () {
        if (this.$route.params.idOrSlug) {
          alert(`Not implemented: Received clanID: ${this.$route.params.idOrSlug}`)
        } else {
          this.fetchGlobalLeaderboard()
        }
      },

      computed: {
        ...mapGetters({
          isLoading: 'seasonalLeague/isLoading'
        }),
      },

      methods: {
        ...mapActions({
          fetchGlobalLeaderboard: 'seasonalLeague/fetchGlobalLeaderboard'
        })
      }
    }
</script>
