<script>
import { mapGetters, mapActions } from 'vuex'
import SecondaryButton from '../../common/buttons/SecondaryButton'
import TertiaryButton from '../../common/buttons/TertiaryButton'
import utils from 'core/utils'

import { hasSharedWriteAccessPermission } from '../../../../../../app/lib/classroom-utils'

export default {
  components: {
    SecondaryButton,
    TertiaryButton,
  },

  data: () => ({
    latestReleasedCourses: [],
    selected: '',
    coursesModel: undefined,
    groupedCourses: [],
  }),

  computed: {
    ...mapGetters({
      loading: 'teacherDashboard/getLoadingState',
      classroom: 'teacherDashboard/getCurrentClassroom',
      classroomCourses: 'teacherDashboard/getCoursesCurrentClassroom',
      classroomMembers: 'teacherDashboard/getMembersCurrentClassroom',
      selectedStudentIds: 'baseSingleClass/selectedStudentIds',
      courses: 'courses/sorted',
    }),
  },

  created () {
    if (!Array.isArray(this.selectedStudentIds) || this.selectedStudentIds.length === 0) {
      noty({ text: $.i18n.t('teacher_dashboard.select_student_first'), layout: 'center', type: 'information', killer: true, timeout: 8000 })
      this.$emit('close')
    }
    this.generateCourses()
  },

  methods: {
    ...mapActions({
      assignCourse: 'courseInstances/assignCourse',
      removeCourse: 'courseInstances/removeCourse',
      fetchData: 'baseSingleClass/fetchData',
    }),
    generateCourses () {
      let cocoIds = Object.values(utils.courseIDs)
      let ozarIds = Object.values(utils.otherCourseIDs)
      if (utils.isOzaria) {
        [cocoIds, ozarIds] = [ozarIds, cocoIds]
      }
      console.log('cocoids?', cocoIds, ozarIds)
      const cocoCourses = [
        { _id: 'junior', name: $.i18n.t('teacher_dashboard.curriculum_junior'), disabled: true }, // group name
        this.courses.find(c => c._id === utils.allCourseIDs.JUNIOR),
        { _id: 'codecombat', name: $.i18n.t('teacher_dashboard.curriculum_coco'), disabled: true }, // group name
        ...this.courses.filter(c => cocoIds.includes(c._id) && ![utils.allCourseIDs.JUNIOR, utils.allCourseIDs.HACKSTACK].includes(c._id)),
        { _id: 'ai', name: $.i18n.t('teacher_dashboard.curriculum_ai'), disabled: true }, // group name
        this.courses.find(c => c._id === utils.allCourseIDs.HACKSTACK),
      ]
      const ozarCourses = [
        { _id: 'ozaria', name: $.i18n.t('teacher_dashboard.curriculum_ozaria'), disabled: true }, // group name
        ...this.courses.filter(c => ozarIds.includes(c._id)),
      ]
      const otherCourses = [
        { _id: 'beta', name: $.i18n.t('teacher_dashboard.curriculum_beta'), disabled: true },
        ...this.courses.filter(c => !Object.values(utils.allCourseIDs).includes(c._id)),
      ]
      if (otherCourses.length === 1) {
        otherCourses.length = 0 // if no beta courses
      }
      if (utils.isOzaria) {
        this.groupedCourses = [...ozarCourses, ...otherCourses]
      } else {
        const cs = [...cocoCourses]
        if (me.showOzCourses()) {
          cs.push(...ozarCourses)
        }
        cs.push(...otherCourses)
        this.groupedCourses = cs
      }
    },
    async handleClickedAssign () {
      if (!this.selected) {
        return
      }
      const course = this.courses.find((v) => v.name === this.selected)

      const sharedClassroomId = hasSharedWriteAccessPermission(this.classroom) ? this.classroom._id : null
      await this.assignCourse({
        classroom: this.classroom,
        course,
        members: this.selectedStudentIds.map(id => this.classroomMembers.find(({ _id }) => id === _id)),
        sharedClassroomId,
      })
      if (this.classroomCourses.find((c) => c._id === course._id)) {
        this.fetchData()
      } else {
        this.fetchData({ forceGameContentFetch: true }) // new course that didnt exist when classroom was created
      }
      this.$emit('close')
    },

    async handleClickedUnassign () {
      if (!this.selected) {
        return
      }
      const course = this.courses.find((v) => v.name === this.selected)

      await this.removeCourse({ course, members: this.selectedStudentIds, classroom: this.classroom })
      this.fetchData()
      this.$emit('close')
    },

    i18nName (course) {
      return utils.i18n(course, 'name')
    },
  },
}
</script>

<template>
  <div class="style-ozaria teacher-form">
    <form
      class="form-container"
      @submit.prevent="() => {}"
    >
      <div
        class="form-group row select-chapter"
      >
        <div class="col-xs-12">
          <span class="control-label">{{ $t('teacher_dashboard.select_chapter') }}</span>
          <select
            id="course-select"
            v-model="selected"
            class="form-control"
            name="courseList"
          >
            <option
              disabled
              selected
              value=""
            >
              {{ $t("teacher_dashboard.choose_course") }}
            </option>
            <option
              v-for="course in groupedCourses"
              :key="course._id"
              :value="course.name"
              :disabled="course.disabled"
            >
              {{ i18nName(course) }}
            </option>
          </select>
        </div>
      </div>
      <div class="form-group row buttons-container">
        <div class="col-xs-12 buttons">
          <tertiary-button @click="handleClickedUnassign">
            {{ $t('teacher_dashboard.unassign') }}
          </tertiary-button>
          <span class="or-text">{{ $t('general.or') }}</span>
          <secondary-button @click="handleClickedAssign">
            {{ $t('courses.assign') }}
          </secondary-button>
        </div>
      </div>
    </form>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/ozaria/_ozaria-style-params.scss";
  .style-ozaria.teacher-form {
    width: 608px;
    padding: 26px 40px;
  }

  .row.select-chapter {
    margin-bottom: 228px;
  }

  .buttons-container {
    float: right;
  }

  .buttons > button {
    width: 150px;
    height: 40px;
  }

  .or-text {
    @include font-p-3-small-button-text-dusk-dark;
    font-size: 14px;
    letter-spacing: 0.333px;
  }

  #course-select {
    option {
      color: black;

      &:disabled {
        color: grey;
      }
    }
  }
</style>
