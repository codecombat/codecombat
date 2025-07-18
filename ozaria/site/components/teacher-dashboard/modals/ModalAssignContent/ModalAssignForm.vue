<script>
import { mapGetters, mapActions } from 'vuex'
import SecondaryButton from '../../common/buttons/SecondaryButton'
import TertiaryButton from '../../common/buttons/TertiaryButton'
import { i18n } from 'core/utils'

import { hasSharedWriteAccessPermission } from '../../../../../../app/lib/classroom-utils'

export default {
  components: {
    SecondaryButton,
    TertiaryButton
  },

  data: () => ({
    latestReleasedCourses: [],
    selected: '',
    coursesModel: undefined
  }),

  computed: {
    ...mapGetters({
      loading: 'teacherDashboard/getLoadingState',
      classroom: 'teacherDashboard/getCurrentClassroom',
      classroomCourses: 'teacherDashboard/getCoursesCurrentClassroom',
      classroomMembers: 'teacherDashboard/getMembersCurrentClassroom',
      selectedStudentIds: 'baseSingleClass/selectedStudentIds',
      courses: 'courses/sorted'
    }),
  },

  created () {
    if (!Array.isArray(this.selectedStudentIds) || this.selectedStudentIds.length === 0) {
      noty({ text: $.i18n.t('teacher_dashboard.select_student_first'), layout: 'center', type: 'information', killer: true, timeout: 8000 })
      this.$emit('close')
    }
  },

  methods: {
    ...mapActions({
      assignCourse: 'courseInstances/assignCourse',
      removeCourse: 'courseInstances/removeCourse',
      fetchData: 'baseSingleClass/fetchData'
    }),

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
        sharedClassroomId
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
      return i18n(course, 'name')
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
              v-for="course in courses"
              :key="course._id"
              :value="course.name"
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
</style>
