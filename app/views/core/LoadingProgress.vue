<style scoped>
    .hide {
        display: none;
    }
</style>

<template>
    <div>
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

        <div v-if="!computedLoading || alwaysRender">
            <!-- Applying class to the parent div causes styles rendered within the slot to break -->
            <div :class="{ hide: computedLoading }">
                <slot></slot>
            </div>
        </div>
    </div>
</template>

<script>
    export default {
      props: {
        alwaysRender: false,

        loadingStatus: [ Number, Boolean, Array ]
      },

      computed: {
        statuses: function () {
          const statuses = this.loadingStatus || [];

          if (!Array.isArray(statuses)) {
            return [ statuses ]
          }

          return statuses
        },

        computedPercent: function () {
          if (this.statuses.length === 0) {
            return 100
          }

          const toPercent = val => {
            if (_.isBoolean(val)) {
              return val ? 0 : 100
            } else if (!_.isNumber(val)) {
              throw new Error('Percent must be array, boolean or percent')
            }

            return val
          }

          const statuses = this.statuses.map((status) => {
            if (!_.isArray(status)) {
              return toPercent(status)
            } else if (status.length === 0) {
              return 100
            }

            // The reduce function will sum up an initial boolean as 1,
            // so we make sure it is following our concept of boolean percent instead.
            status[0] = toPercent(status[0])

            const loadingSum = status.reduce((total, toAdd) => total + toPercent(toAdd))
            return loadingSum / status.length
          })

          const statusSum = statuses.reduce((s, i) => s + i, 0)
          return statusSum / (statuses.length * 100) * 100
        },

        computedLoading: function () {
          return this.computedPercent < 100
        }
      }
    }
</script>
