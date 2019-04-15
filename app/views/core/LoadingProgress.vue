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

          const statuses = this.statuses.map((status) => {
            if (typeof status === 'boolean') {
              return status ? 0 : 100
            } else if (typeof status === 'object' && status.length > 0) {
              const reducedArray = status.reduce((total, toAdd) => {
                if (typeof status === 'boolean') {
                  return total + (toAdd ? 0 : 100)
                } else {
                  return total + toAdd
                }
              })

              return reducedArray / status.length
            } else if (typeof status !== 'number') {
              throw new Error('Status must be boolean or percent')
            }

            return status
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
