<template>
  <div class="form-group row">
    <div class="col-xs-12">
      <label for="form-new-class-date-start">
        <span class="control-label"> {{ $t("courses.estimated_class_dates_label") }} </span>
      </label>
      <div class="estimated-date-fields">
        <input
          id="form-new-class-date-start"
          v-model="newClassDateStart"
          type="date"
          class="form-control"
        >
        <label for="form-new-class-date-end">
          <span class="spr">{{ $t("courses.student_age_range_to") }}</span>
        </label>
        <input
          id="form-new-class-date-end"
          v-model="newClassDateEnd"
          type="date"
          class="form-control"
        >
      </div>
    </div>
  </div>
</template>

<script>
export default Vue.extend({
  name: 'ClassStartEndDateComponent',
  props: {
    classDateStart: {
      type: String,
      required: false,
      default: '',
    },
    classDateEnd: {
      type: String,
      required: false,
      default: '',
    },
  },
  data () {
    return {
      newClassDateStart: this.classDateStart,
      newClassDateEnd: this.classDateEnd,
    }
  },
  watch: {
    newClassDateStart (newVal) {
      this.$emit('classDateStartUpdated', newVal)
    },
    newClassDateEnd (newVal) {
      this.$emit('classDateEndUpdated', newVal)
    },
  },
})
</script>
<style lang="scss" scoped>
.estimated-date-fields {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
  width: 100%;

  input {
    width: 45%;
  }
}
</style>