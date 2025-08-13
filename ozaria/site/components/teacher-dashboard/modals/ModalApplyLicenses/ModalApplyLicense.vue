<template>
  <div class="style-ozaria apply-license">
    <div class="form">
      <div class="licenses">
        <div class="title license-grid">
          <div /> <!-- checkbox -->
          <div /> <!-- name -->
          <div>{{ $t('outcomes.end_date') }}</div>
          <div
            v-for="course in utils.orderedCourseIDs"
            :key="`course-name-${course}`"
            :class="`title-course course-${course}`"
          >
            {{ utils.courseAcronyms[course] }}
          </div>
        </div>
        <div class="sub-title">
          <div>{{ $t('teacher_dashboard.pick_a_license') }}</div>
        </div>
        <div
          v-for="license in licenses"
          :key="`license-${license._id}`"
          class="license-grid"
        >
          <div>
            <input
              v-model="selectedLicenseId"
              name="license"
              type="radio"
              :value="license._id"
            >
          </div>
          <div>
            {{ licenseName(license) }}
          </div>
          <div class="endDate">
            {{ moment(license.endDate).format('ll') }}
          </div>
          <div
            v-for="(course, index) in utils.orderedCourseIDs"
            :key="`license-course-${course}`"
          >
            <input
              type="checkbox"
              class="checkbox-course license-course"
              :checked="(license.courseBits & Math.pow(2, index)) ? 'checked' : undefined"
              onclick="return false"
            >
          </div>
        </div>
      </div>
      <div class="students">
        <div class="sub-title student-title">
          <div>{{ $t('teacher.select_students') }}</div>
        </div>
        <div class="select-all all-user-grid">
          <div>
            <input
              type="checkbox"
              :checked="selectedStudentIds.length > 0 && selectedStudentIds.length === students.length"
              @change="toggleAllStudents"
            >
          </div>
          <div>
            {{ $t('teacher.all_students') }}
          </div>
          <div />
          <div class="color-box">
            <input
              class="student-having-course"
              type="checkbox"
              checked
              onclick="return false"
            >
            <span>{{ $t('teacher_dashboard.having_access') }}</span>
          </div>
          <div class="color-box">
            <input
              class="license-preview"
              type="checkbox"
              checked
              onclick="return false"
            >
            <span>{{ $t('teacher_dashboard.course_preview') }}</span>
          </div>
        </div>
        <div
          v-for="student in students"
          :key="`student-${student._id}`"
          class="students user-grid"
        >
          <div>
            <input
              type="checkbox"
              :checked="selectedStudentIds.includes(student._id)"
              @change="changeCheckBox(student._id)"
            >
          </div>
          <div>
            {{ student.name }}
          </div>
          <div class="endDate" />
          <div
            v-for="(course, index) in utils.orderedCourseIDs"
            :key="`student-course-${index}`"
            class="student-course"
          >
            <input
              type="checkbox"
              class="checkbox-course student-course"
              :class="{'license-preview': selectedCourses.includes(course) && selectedStudentIds.includes(student._id),
                       'student-having-course': student.courseBits & Math.pow(2, index)}"
              :checked="((student.courseBits & Math.pow(2, index)) || (selectedCourses.includes(course)&& selectedStudentIds.includes(student._id)))? 'checked' : undefined"
              onclick="return false"
            >
          </div>
        </div>
      </div>
    </div>
    <div class="buttons">
      <tertiary-button @click="handleClickedCancel">
        {{ $t('modal.cancel') }}
      </tertiary-button>
      <span class="or-text">{{ $t('general.or') }}</span>
      <secondary-button @click="handleClickedApply">
        {{ $t('teacher.apply_licenses') }}
      </secondary-button>
    </div>
  </div>
</template>

<script>
import utils from 'app/core/utils'
import { mapGetters, mapActions } from 'vuex'
import moment from 'moment'

import SecondaryButton from '../../common/buttons/SecondaryButton'
import TertiaryButton from '../../common/buttons/TertiaryButton'

export default {
  components: {
    SecondaryButton,
    TertiaryButton,
  },
  data () {
    return {
      selectedLicenseId: null,
    }
  },
  computed: {
    ...mapGetters({
      selectedStudentIds: 'baseSingleClass/selectedStudentIds',
      classroomMembers: 'teacherDashboard/getMembersCurrentClassroom',
      getPrepaids: 'prepaids/getPrepaidsByTeacher',
    }),
    selectedLicense () {
      if (!this.selectedLicenseId) return null
      return _.find(this.licenses, (license) => license._id === this.selectedLicenseId)
    },
    selectedCourses () {
      if (!this.selectedLicense) return []
      return this.selectedLicense.includedCourseIDs || utils.orderedCourseIDs
    },
    utils () {
      return utils
    },
    moment () {
      return moment
    },
    licenses () {
      return this.getPrepaids(me.id)?.available?.map(prepaid => ({
        ...prepaid,
        courseBits: this.numericalCourses(prepaid, 'prepaid'),
      }))
    },
    students () {
      return this.classroomMembers.map(member => ({
        ...member,
        courseBits: this.numericalCourses(member, 'member'),
      }))
    },
  },
  mounted () {
    this.selectedLicenseId = this.licenses?.[0]?._id
  },
  methods: {
    ...mapActions({
      toggleStudentSelectedId: 'baseSingleClass/toggleStudentSelectedId',
      clearSelectedStudents: 'baseSingleClass/clearSelectedStudents',
      addStudentSelectedId: 'baseSingleClass/addStudentSelectedId',
      applyLicenses: 'baseSingleClass/applyLicenses',
    }),
    toggleAllStudents (event) {
      if (event.target.checked) {
        for (const { _id } of this.students) {
          this.addStudentSelectedId({ studentId: _id })
        }
      } else {
        this.clearSelectedStudents()
      }
    },
    changeCheckBox (id) {
      this.toggleStudentSelectedId({ studentId: id })
    },
    handleClickedApply () {
      this.applyLicenses({ selectedPrepaidId: this.selectedLicenseId }).then(
        () => setTimeout(() => this.$emit('close'), 3000),
      )
    },
    handleClickedCancel () {
      this.$emit('close')
    },
    licenseName (license) {
      let name = ''
      if (license.type === 'starter_license') {
        name += $.i18n.t('teacher.starter_license')
      } else {
        const includedCourseIDs = license.includedCourseIDs
        if (includedCourseIDs) {
          name += $.i18n.t('teacher.customized_license')
        } else {
          name += $.i18n.t('teacher.full_license')
        }
      }
      name += ` (${license.maxRedeemers - (license.redeemers?.length || 0)})`
      return name
    },
    numericalCourses (object, oType) {
      if (oType === 'prepaid') {
        if (!(object.includedCourseIDs?.length)) {
          return utils.courseNumericalStatus.FULL_ACCESS
        }
        const fun = (s, k) => {
          return s + utils.courseNumericalStatus[k]
        }
        return _.reduce(object.includedCourseIDs, fun, 0)
      } else if (oType === 'member') {
        const now = new Date()
        const courseProducts = object.products?.filter(p => p.product === 'course' && (new Date(p.endDate) > now || !p.endDate))
        if (!courseProducts?.length) {
          return utils.courseNumericalStatus.NO_ACCESS
        }
        if (_.some(courseProducts, p => (p.productOptions?.includedCourseIDs == null))) { return utils.courseNumericalStatus.FULL_ACCESS }
        const union = (res, prepaid) => _.union(res, prepaid.productOptions?.includedCourseIDs != null ? prepaid.productOptions?.includedCourseIDs : [])
        const courses = _.reduce(courseProducts, union, [])
        const fun = (s, k) => s + utils.courseNumericalStatus[k]
        return _.reduce(courses, fun, 0)
      }
    },
  },
}
</script>

<style lang="scss" scoped>
@import "app/styles/ozaria/_ozaria-style-params.scss";
.apply-license {
  width: 1200px;

  .form {
    overflow-y: hide;
  }
}
.license-grid, .user-grid {
  display: grid;
  // checkbox, name, endDate, cs1, gd1, wd1, cs2, gd2, gd3, cs3, cs4, cs5, cs6, wd2, junior, hackstack
  grid-template-columns: 3% 19% 13% repeat(13, 5%);
  grid-template-rows: 100%;
}

.all-user-grid {
  display: grid;
  grid-template-columns: 5% 20% 15% 15% 30%;
  grid-template-rows: 100%;
}

.title-course {

}
.sub-title {
  div {
    border-bottom: 1px solid black;
  }
}
.student-title {
  margin-top: 20px;
}
.student-course {
  position: relative;

  .selected-mask {
    position: absolute;
    top: 0;
    width: 100%;
    height: 100%;
    border: 1px solid $color-intro-title-bar-complete;
    background: rgba($color-progress-status-complete, 0.4);
  }

}
.buttons {
  margin-top: 40px;
  float: right;

  button {
    width: 150px;
    height: 40px;
  }
  .or-text {
    @include font-p-3-small-button-text-dusk-dark;
    font-size: 14px;
    letter-spacing: 0.333px;
  }
}
input[type='checkbox'] {
  &.license-course {
    accent-color: #2dcd38;
  }

  &.license-preview {
    accent-color: #1ad0ff;
  }

  &.student-having-course {
    accent-color: #c8cdcc;
  }
}

.color-box {
  display: flex;
  align-items: center;
}
</style>