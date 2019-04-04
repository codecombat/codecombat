<style scoped>

</style>

<template>
    <div v-if="computedLoading" class="loading-screen loading-container">
        <h1>{{ $t('common.loading') }}</h1>
        <div class="progress">
            <div
                    class="progress-bar"
                    :style="{ width: `${computedPercent}%` }"
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
        loading: Boolean,
        progress: Number,

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

        statusPercent: function () {
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

        computedPercent: function () {
          if (this.statuses.length > 0) {
            return this.statusPercent
          }

          if (typeof this.$props.progress !== 'undefined') {
            return this.$props.progress
          }

          return 0
        },

        computedLoading: function () {
          if (this.statuses.length > 0) {
            return this.statusPercent < 100
          }

          if (typeof this.$props.loading !== 'undefined') {
            return this.$props.loading
          }

          return false
        }
      }
    }
</script>
