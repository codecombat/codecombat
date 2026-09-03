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
          :min="guardDate.min"
          :max="guardDate.max"
        >
        <label for="form-new-class-date-end">
          <span class="spr">{{ $t("courses.student_age_range_to") }}</span>
        </label>
        <input
          id="form-new-class-date-end"
          v-model="newClassDateEnd"
          type="date"
          class="form-control"
          :min="guardDate.min"
          :max="guardDate.max"
        >
      </div>
    </div>
  </div>
</template>

<script>
import dayjs from 'dayjs'
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
  computed: {
    guardDate () {
      const currentYear = new Date().getFullYear()
      const minYear = currentYear - 100
      const maxYear = currentYear + 100

      return {
        min: `${minYear}-01-01`,
        max: `${maxYear}-12-31`,
      }
    },
    newClassDateStart: {
      get () {
        return this.classDateStart
      },
      set (newV) {
        this.$emit('classDateStartUpdated', this.checkAndSetDate(new Date(newV)))
      },
    },
    newClassDateEnd: {
      get () {
        return this.classDateEnd
      },
      set (newV) {
        this.$emit('classDateEndUpdated', this.checkAndSetDate(new Date(newV)))
      },
    },
  },
  methods: {
    checkAndSetDate (d) {
      if (isNaN(d.getTime())) {
        return ''
      }
      if (d < new Date(this.guardDate.min)) {
        d = this.guardDate.min
      }
      if (d > new Date(this.guardDate.max)) {
        d = this.guardDate.max
      }
      return dayjs(d).format('YYYY-MM-DD')
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