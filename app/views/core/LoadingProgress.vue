<style scoped>

</style>

<template>
    <div v-if="loading" class="loading-screen loading-container">
        <h1>{{ $t('common.loading') }}</h1>
        <div class="progress">
            <div
                    class="progress-bar"
                    :style="{ width: `${loadingPercent}%` }"
            >
            </div>
        </div>

        <div class="errors">
        </div>
    </div>

    <div v-else>
        <slot></slot>
    </div>
</template>

<script>
    export default {
      props: {
        loadingStatus: [ Array, Boolean ]
      },

      computed: {
        statuses: function () {
          const statuses = this.loadingStatus || [];

          if (!Array.isArray(statuses)) {
            return [ statuses ]
          }

          return statuses
        },

        loadingPercent: function () {
          const statuses = this.statuses

          if (statuses.length === 0) {
            return 100
          }

          let finishedCount = 0
          for (var status of statuses) {
            if (!status) {
              finishedCount += 1
            }
          }

          return finishedCount / statuses.length * 100
        },

        loading: function () {
          return this.loadingPercent < 100
        }
      }
    }
</script>
