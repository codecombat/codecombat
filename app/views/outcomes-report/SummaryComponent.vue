<template>
  <div class="outcome-summary">
    <div
      v-if="students"
      class="item"
    >
      <stat-item-component
        img-path="/images/pages/library/icon-users.png"
        :name="$t('outcomes.students')"
        :value="students"
      />
    </div>
    <div
      v-if="teachers"
      class="item"
    >
      <stat-item-component
        img-path="/images/pages/library/icon-code.png"
        :name="$t('outcomes.teachers')"
        :value="teachers"
      />
    </div>
    <div
      v-if="schools"
      class="item"
    >
      <stat-item-component
        img-path="/images/pages/library/icon-programs.png"
        :name="$t('outcomes.schools')"
        :value="schools"
      />
    </div>
    <div
      v-if="licensesUsed"
      class="item"
    >
      <stat-item-component
        img-path="/images/pages/library/icon-code.png"
        :name="$t('outcomes.licensesUsed')"
        :value="licensesUsed"
      />
    </div>
  </div>
</template>
<script>
import StatItemComponent from '../library/dashboard/components/helpers/StatItemComponent.vue'
export default Vue.extend({
  components: {
    StatItemComponent
  },
  props: {
    students: {
      type: Number,
      default: 0
    },
    teachers: {
      type: Number,
      default: 0
    },
    schools: {
      type: Number,
      default: 0
    },
    licensesUsed: {
      type: Number,
      default: 0
    },
  }
})
</script>
<style scoped lang="scss">
.outcome-summary {
  display: flex;
  justify-content: space-around;
  width: 100%;

  background: #f7d047 !important;
  -webkit-print-color-adjust: exact !important;
  padding: 2rem;

  :deep(.stat__img) {
    height: 5rem;
  }

  :deep(.stat__info) {
    font-size: 2rem;
  }
}
</style>
