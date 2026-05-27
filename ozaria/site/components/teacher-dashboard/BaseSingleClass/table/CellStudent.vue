<script>
import { isOzaria, courseIDs, OZ_COURSE_IDS, courseAcronyms } from 'core/utils'
import { mapMutations, mapGetters } from 'vuex'
export default {
  props: {
    studentName: {
      type: String,
      required: true,
    },
    studentId: {
      type: String,
      required: true,
    },
    studentObj: {
      type: Object,
      default: null,
    },
    checked: {
      type: Boolean,
      required: true,
    },
    isEnrolled: {
      type: Boolean,
      default: false,
    },
    studentSessions: {
      type: Array,
    },
  },

  computed: {
    ...mapGetters({
      classroom: 'teacherDashboard/getCurrentClassroom',
      selectedCourseId: 'teacherDashboard/getSelectedCourseIdCurrentClassroom',
      getCourseInstancesOfClass: 'courseInstances/getCourseInstancesOfClass',
    }),

    selectedCourseInstanceId () {
      const courseInstances = this.getCourseInstancesOfClass(this.classroom._id)
      const courseInstance = _.find(courseInstances, (ci) => ci.courseID === this.selectedCourseId)
      return (courseInstance || {})._id
    },
    hasCompletedCourse () {
      if (this.selectedCourseId === courseIDs.HACKSTACK) {
        return false
      }
      if (!this.studentSessions || this.studentSessions.length === 0) {
        return false
      }

      if (isOzaria) {
        const completedSessions = this.studentSessions.filter(session => session.status === 'complete')
        return completedSessions.length === this.studentSessions.length
      }
      let courseFinished = true
      for (const session of this.studentSessions) {
        if (!session.isPractice && !session.isCourseLadder) {
          courseFinished = courseFinished && (session.status === 'complete')
          if (!courseFinished) {
            break
          }
        }
      }
      return courseFinished
    },
    isOzCourse () {
      return OZ_COURSE_IDS.includes(this.selectedCourseId)
    },
    student () {
      const User = require('models/User')
      return new User(this.studentObj)
    },
    licenseImg () {
      if (this.student.prepaidIncludesCourse(this.selectedCourseId)) {
        return '/images/ozaria/teachers/dashboard/svg_icons/IconLicense_Gray.svg'
      }
      return '/images/ozaria/teachers/dashboard/svg_icons/IconLicense_Moon.svg'
    },
    licensedStatus () {
      let title
      const covers = $.i18n.t('teacher.license_is')
      if (this.student.prepaidIncludesCourse(this.selectedCourseId)) {
        title = $.i18n.t('teacher.owned_license')
      } else {
        title = $.i18n.t('teacher.course_not_covered', { course: courseAcronyms[this.selectedCourseId] })
      }
      return title + ` \n${covers}${this.student.prepaidTypeDescription()}`
    },
  },
  methods: {
    ...mapMutations({
      openModalEditStudent: 'baseSingleClass/openModalEditStudent',
    }),
    certUrl (studentId) {
      let urlStarts = '/certificates'
      if (this.isOzCourse) {
        urlStarts += '/ozaria'
      }
      return `${urlStarts}/${studentId}?class=${this.classroom._id}&course=${this.selectedCourseId}&course-instance=${this.selectedCourseInstanceId}`
    },
  },
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
      <a
        v-if="hasCompletedCourse"
        target="_blank"
        :href="certUrl(studentId)"
        title="View Course Completion Certificate"
      >
        <img
          src="/images/pages/user/certificates/certificate-icon.png"
          class="certificate-icon"
        >
      </a>
      <img
        v-if="isEnrolled"
        :src="licenseImg"
        :title="licensedStatus"
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

    .student-status-icons {
      white-space: nowrap;
      .certificate-icon  {
        height: 22px;
        transition: filter 0.2s linear;
        filter: none;

        &:not(:hover) {
          filter: saturate(0);
        }
      }
    }

  }

</style>
