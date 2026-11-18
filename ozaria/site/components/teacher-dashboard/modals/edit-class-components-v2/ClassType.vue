<template>
  <div
    class="form-group row"
  >
    <div class="col-md-12">
      <label for="type">
        <span class="control-label"> {{ $t("courses.class_type_label") }} </span>
      </label>
      <select
        id="type"
        v-model="classroomType"
        name="type"
        class="form-control"
      >
        <option value="">
          {{ $t('courses.avg_student_exp_select') }}
        </option>
        <option
          v-for="op in typeOptions"
          :key="`class-type-${op}`"
          :value="op"
        >
          {{ $t('courses.class_type_' + op.replaceAll('-', '_')) }}
        </option>
      </select>
    </div>
  </div>
</template>
<script>
export default {
  name: 'ClassType',
  props: {
    classType: {
      type: String,
      default: '',
    },
  },
  computed: {
    classroomType: {
      get () { return this.classType },
      set (v) { return this.$emit('input', v) },
    },
    isIdeaLab () {
      return me.isIdeaLab() && me.isTeacher()
    },
    typeOptions () {
      if (this.isIdeaLab) {
        return ['idea-lab-in-school', 'idea-lab-camp']
      } else {
        return ['in-school', 'after-school', 'online', 'camp', 'homeschool', 'other']
      }
    },
  },
}
</script>
