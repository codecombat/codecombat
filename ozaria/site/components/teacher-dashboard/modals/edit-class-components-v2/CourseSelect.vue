<template>
  <div
    v-if="isCodeCombat"
    class="col-xs-12 initial-free-courses"
  >
    <span class="control-label">
      {{ $t("teachers.select_initial_course") }}
    </span>
    <div class="initial-courses options">
      <div
        v-for="initialFreeCourse in initialFreeCourses"
        :key="initialFreeCourse.id"
        class="initial-course option"
      >
        <label
          class="option-block"
        >
          <input
            v-model="newCourse"
            :value="initialFreeCourse.id"
            type="radio"
            name="initialFreeCourses"
          >
          <span class="option-name">
            {{ initialFreeCourse.name }}
          </span>
          <br>
          <span class="help-block small">{{ initialFreeCourse.blurb }}</span>
        </label>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import utils from 'core/utils'
export default {
  name: 'EditClassCourseSelect',
  props: {
    value: {
      type: String,
      default: '',
    },
  },
  data () {
    return {
      newCourse: this.value,
    }
  },
  computed: {
    ...mapGetters({
      courses: 'courses/sorted',
    }),
    isCodeCombat () {
      return utils.isCodeCombat
    },
    initialFreeCourses () {
      if (!this.isCodeCombat) {
        return []
      }
      const freeCocoCourseIDs = [...utils.freeCocoCourseIDs, utils.OZ_COURSE_IDS_MAP.CHAPTER_ONE]
      return [
        ...freeCocoCourseIDs.map(id => {
          const course = this.courses.find(({ _id }) => _id === id)
          if (!course) {
            // computed value uses in template before mounted, so no courses yet
            return null
          }
          return {
            id,
            name: $.i18n.t(`teachers.course_title_${course.slug}`),
            blurb: $.i18n.t(`teachers.free_course_blurb_${course.slug}`),
          }
        }).filter(Boolean),
      ]
    },
  },
  watch: {
    newCourse (newV) {
      this.$emit('input', newV)
    },
  },
}
</script>
<style lang="scss" scoped>
.option-block {
  display: block;
  border-radius: 5px;
  border: 1px dotted black;
  cursor: pointer;
  padding: 5px 10px;

  .option-name {
    font-size: 18px;
    line-height: 20px;
    font-weight: bold;
  }
}
.help-block {
  display: block;
  margin-top: 2px;
  margin-bottom: 5px;
  font-size: 13px;
  color: black;
  line-height: 20px
}
</style>
