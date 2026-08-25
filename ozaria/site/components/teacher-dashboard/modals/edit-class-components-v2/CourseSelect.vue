<template>
  <div
    v-if="isCodeCombat"
    class="col-xs-12 initial-free-courses"
  >
    <label for="initial-courses">
      <h5>
        {{ $t("teachers.select_initial_course") }}
      </h5>
    </label>
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
          <div class="option-content">
            <div class="option-title-row">
              <span class="option-name">{{ initialFreeCourse.name }}</span>
              <span
                class="grade-badge"
                :title="`Grades: ${getGradeBadge(initialFreeCourse.id)}`"
              >
                {{ getGradeBadge(initialFreeCourse.id) }}
              </span>
            </div>
            <span class="help-block small">{{ initialFreeCourse.blurb }}</span>
          </div>
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
  methods: {
    getGradeBadge (courseId) {
      if (utils.COCO_COURSE_IDS.includes(courseId)) {
        return '6-12'
      } else if (utils.JUNIOR_COURSE_IDS.includes(courseId)) {
        return 'K-5'
      } else if (utils.OZ_COURSE_IDS.includes(courseId)) {
        return '6-8'
      } else if (utils.HACKSTACK_COURSE_IDS.includes(courseId)) {
        return '6-12'
      }
      return null
    },
  },
}
</script>
<style lang="scss" scoped>
.option-block {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  border-radius: 5px;
  border: 1px dotted black;
  cursor: pointer;
  padding: 10px;

  .option-content {
    flex: 1;
  }

  .option-title-row {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .option-name {
    font-size: 18px;
    line-height: 20px;
    font-weight: bold;
  }

  .grade-badge {
    padding: 2px 8px;
    border-radius: 10px;
    background-color: #7a65fc;
    color: white;
    font-size: 11px;
    line-height: 14px;
    font-weight: bold;
  }
}
.help-block {
  display: block;
  margin-top: 5px;
  margin-bottom: 5px;
  font-size: 13px;
  color: black;
  line-height: 20px
}

.initial-courses {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
</style>
