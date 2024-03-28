<template>
  <div
    class="details"
  >
    <div
      v-if="loading"
      class="loading"
    >
      Loading...
    </div>
    <div
      v-else
      class="details__data"
    >
      <div class="coco">
        <h2 class="coco__heading">
          Coco
        </h2>
        <div
          v-for="item in formatData(cocoData)"
          :key="item.key"
          class="item"
        >
          <div class="item__key">
            {{ item.key }}:
          </div>
          <div class="item__value">
            {{ item.value }}
          </div>
        </div>
      </div>
      <div class="oz">
        <h2 class="oz__heading">
          Oz
        </h2>
        <div
          v-for="item in formatData(ozData)"
          :key="item.key"
          class="item"
        >
          <div class="item__key">
            {{ item.key }}:
          </div>
          <div class="item__value">
            {{ item.value }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { getLowUsageData } from '../../../core/api/users'
export default {
  name: 'DataDetailsComponent',
  props: {
    user: {
      type: Object,
      default: () => {}
    }
  },
  data () {
    return {
      loading: false,
      cocoData: null,
      ozData: null
    }
  },
  watch: {
    showDetails (newVal) {
      if (newVal) {
        this.fetchDetails()
      }
    }
  },
  created () {
    this.fetchDetails()
  },
  methods: {
    async fetchDetails () {
      this.loading = true
      const promises = []
      promises.push(getLowUsageData(this.user.userId))
      promises.push(getLowUsageData(this.user.userId, { callOz: true }))
      const data = await Promise.all(promises)
      this.cocoData = data[0].data
      this.ozData = data[1].data
      this.loading = false
    },
    formatData (data) {
      const result = []
      for (const [key, value] of Object.entries(data)) {
        if (['lastLicenseApplied', 'lastVisitedSite', 'lastClickedToolkit', 'lastClickedCourseGuide'].includes(key)) {
          result.push({
            key,
            value: value ? new Date(value).toDateString() : '-'
          })
        } else {
          result.push({
            key,
            value: value || '-'
          })
        }
      }
      return result
    }
  }
}
</script>

<style scoped lang="scss">
.details {
  &__data {
    display: flex;
    justify-content: space-evenly;
  }

  .item {
    display: flex;
    font-size: 1.5rem;

    &__key {
      font-weight: bold;
      margin-right: 5px;
    }
  }

  .loading {
    text-align: center;
  }
}
</style>
