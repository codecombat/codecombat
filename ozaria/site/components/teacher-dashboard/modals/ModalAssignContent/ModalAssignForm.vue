<script>
  import { mapGetters, mapActions } from 'vuex'
  import SecondaryButton from '../../common/buttons/SecondaryButton'
  import TertiaryButton from '../../common/buttons/TertiaryButton'

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
        selectedStudentIds: 'baseSingleClass/selectedStudentIds'
      })
    },

    created () {
      if (!Array.isArray(this.selectedStudentIds) || this.selectedStudentIds.length === 0) {
        noty({ text: `You need to select student(s) first before performing that action.`, layout: 'center', type: 'information', killer: true, timeout: 8000 })
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
        const course = this.classroomCourses.find((v) => v.name === this.selected)

        await this.assignCourse({ classroom: this.classroom, course, members: this.selectedStudentIds.map(id => this.classroomMembers.find(({ _id }) => id === _id)) })
        this.fetchData()
        this.$emit('close')
      },

      async handleClickedUnassign () {
        if (!this.selected) {
          return
        }
        const course = this.classroomCourses.find((v) => v.name === this.selected)

        await this.removeCourse({ course, members: this.selectedStudentIds, classroom: this.classroom })
        this.fetchData()
        this.$emit('close')
      }
    }
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
          <span class="control-label">Select Chapter</span>
          <select
            class="form-control"
            name="classLanguage"
            v-model="selected"
          >
            <option
              disabled
              selected
              value=""
            >
              Click to Select from Dropdown
            </option>
            <option
              v-for="course in classroomCourses"
              :key="course._id"
              :value="course.name"
            >
              {{ course.name }}
            </option>
          </select>
          <span
            class="form-error"
          >
            {{ $t("form_validation_errors.required") }}
          </span>
        </div>
      </div>
      <div class="form-group row buttons-container">
        <div class="col-xs-12 buttons">
          <tertiary-button @click="handleClickedUnassign">
            Unassign
          </tertiary-button>
          <span class="or-text">or</span>
          <secondary-button @click="handleClickedAssign">
            Assign
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
