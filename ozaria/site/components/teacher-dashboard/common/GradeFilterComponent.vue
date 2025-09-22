<template>
  <div
    class="chips"
    role="tablist"
    aria-label="Grade band filter"
  >
    <button
      v-for="option in gradeBandOptions"
      :key="option"
      type="button"
      role="tab"
      :aria-selected="gradeBand === option"
      :class="['chip', { selected: gradeBand === option }]"
      @click.stop="emitChange(option)"
    >
      {{ option }}
    </button>
  </div>
</template>

<script>
export default {
  name: 'GradeFilterComponent',
  props: {
    gradeBand: {
      type: String,
      default: '',
    },
    gradeBandOptions: {
      type: Array,
      default: () => [],
    },
  },
  methods: {
    emitChange (band) {
      const next = this.gradeBand === band ? '' : band
      window.tracker?.trackEvent('Grade Band: Selected', { category: 'Teachers', label: next })
      this.$emit('change', next)
    },
  },
}
</script>

<style lang="scss" scoped>
.chips {
  display: flex;
  gap: 8px;
}

.chip {
  appearance: none;
  border: 1px solid #d0d5dd;
  background: #ffffff;
  color: #344054;
  border-radius: 9999px;
  padding: 6px 12px;
  font-size: 12px;
  font-weight: 600;
  line-height: 16px;
  cursor: pointer;
  transition: background-color 0.15s ease, color 0.15s ease, border-color 0.15s ease, box-shadow 0.15s ease;

  &:hover {
    border-color: #98a2b3;
    background: #f9fafb;
  }

  &.selected {
    background: #EEF4FF;
    border-color: #4461A0;
    color: #2F4F8F;
    box-shadow: 0 0 0 1px rgba(68, 97, 160, 0.2) inset;
  }
}
</style>
