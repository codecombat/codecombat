<script>
  import { mapMutations, mapGetters } from 'vuex'
  export default {
    props: {
      studentName: {
        type: String,
        required: true
      },
      studentId: {
        type: String,
        required: true
      },
      checked: {
        type: Boolean,
        required: true
      },
      isEnrolled: {
        type: Boolean,
        default: false
      },
      studentSessions: {
        type: Array,
      },
    },

    computed: {
      ...mapGetters({
        classroom: 'teacherDashboard/getCurrentClassroom',
        selectedCourseId: 'teacherDashboard/getSelectedCourseIdCurrentClassroom',
        getCourseInstancesForClass: 'courseInstances/getCourseInstancesForClass'
      }),

      selectedCourseInstanceId () {
        const courseInstances = this.getCourseInstancesForClass(this.classroom.ownerID, this.classroom._id)
        const courseInstance = _.find(courseInstances, (ci) => ci.courseID === this.selectedCourseId)
        return (courseInstance || {})._id
      },
      hasCompletedCourse () {
        if (!this.studentSessions || this.studentSessions.length === 0) {
          return false
        }
        const completedSessions = this.studentSessions.filter(session => session.status === 'complete')
        return completedSessions.length === this.studentSessions.length
      }
    },
    methods: {
      ...mapMutations({
        openModalEditStudent: 'baseSingleClass/openModalEditStudent'
      }),
    }
  }
</script>
<template>
  <div class="cell-student">
    <div class="student-checkbox">
      <input
        type="checkbox"
        :checked="checked"

        @change="$emit('change')"
      >
      <p
        :title="studentName"
        @click="() => openModalEditStudent(studentId)"
      >
        {{ studentName }}
      </p>
    </div>
    <div class="student-status-icons">
      <a target='_blank' :href='`/certificates/${studentId}?class=${classroom._id}&course=${selectedCourseId}&course-instance=${selectedCourseInstanceId}`' v-if="hasCompletedCourse" title="View Course Completion Certificate">
        <img
          src="/images/pages/user/certificates/certificate-icon.png"
          class="certificate-icon"
          >
      </a>
      <img
        v-if="isEnrolled"
        src="/images/ozaria/teachers/dashboard/svg_icons/IconLicense_Gray.svg"
        title="Licensed"
        >
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  .student-checkbox {
    display: flex;
    flex-direction: row;

    justify-content: center;
    align-items: center;

    p, input {
      margin: 0;
    }

    p {
      margin-left: 10px;
      cursor: pointer;
      text-decoration: underline;

      @include font-p-4-paragraph-smallest-gray;
      color: #476fb1;

      max-width: 125px;
      overflow-x: hidden;
      white-space: nowrap;
      text-overflow: ellipsis;
    }
  }

  .cell-student {
    display: flex;
    flex-direction: row;

    justify-content: space-between;
    align-items: center;

    max-width: $studentNameWidth;
    width: $studentNameWidth;
    height: 29px;

    padding: 0 13px 0 20px;

    border-right: 1px solid #d8d8d8;
    border-bottom: 1px solid #d8d8d8;

    background-color: white;
    &:nth-child(even) {
      background-color: #f2f2f2;
    }

    .certificate-icon  {
      height: 22px;
      transition: filter 0.2s linear;
      filter: none;

      &:not(:hover) {
        filter: saturate(0);
      }
    }
  }

</style>
