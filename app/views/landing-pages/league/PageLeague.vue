<style scoped>
</style>

<template>
    <div>
        <div class="container">
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
        this.fetchRequiredInitialData({ optionalIdOrSlug: this.$route.params.idOrSlug })
        this.loadGlobalRequiredData()
      },

      computed: {
        ...mapGetters({
          isLoading: 'seasonalLeague/isLoading'
        }),
      },

      methods: {
        ...mapActions({
          loadGlobalRequiredData: 'seasonalLeague/loadGlobalRequiredData',
          fetchRequiredInitialData: 'clans/fetchRequiredInitialData'
        })
      }
    }
</script>
