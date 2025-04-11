<template>
  <div class="style-ozaria apply-license">
    <div class="form">
      <div class="licenses">
        <div class="title license-grid">
          <div /> <!-- checkbox -->
          <div /> <!-- name -->
          <div>endDate</div>
          <div
            v-for="course in utils.orderedCourseIDs"
            :key="`course-${course}`"
          >
            {{ utils.courseAcronyms[course] }}
          </div>
        </div>
        <div>
          <div>Pick a License</div>
        </div>
        <div
          v-for="license in licenses"
          :key="`license-${license.id}`"
          class="license-grid"
        >
          <div>
            <input
              name="license"
              type="radio"
              value="license"
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
            :key="`course-${index}`"
          >
            <input
              type="checkbox"
              class="checkbox-course"
              :checked="(license.courseBits & Math.pow(2, index)) ? 'checked' : undefined"
              onclick="return false"
            >
          </div>
        </div>
      </div>
      <div class="students">
        <div>
          <div>Select your students</div>
        </div>
        <div
          v-for="student in students"
          :key="`student-${student.id}`"
          class="students user-grid"
        >
          <div>
            <input type="checkbox">
          </div>
          <div>
            {{ student.name }}
          </div>
          <div class="endDate" />
          <div
            v-for="(course, index) in utils.orderedCourseIDs"
            :key="`student-course-${index}`"
          >
            <input
              type="checkbox"
              class="checkbox-course"
              :checked="(student.courseBits & Math.pow(2, index)) ? 'checked' : undefined"
              onclick="return false"
            >
          </div>
        </div>
      </div>
    </div>
    <div class="buttons" />
  </div>
</template>

<script>
import utils from 'app/core/utils'
import { mapGetters } from 'vuex'
import moment from 'moment'
export default {
  data () {
    return {
    }
  },

  computed: {
    ...mapGetters({
      selectedStudentIds: 'baseSingleClass/selectedStudentIds',
      classroomMembers: 'teacherDashboard/getMembersCurrentClassroom',
      getPrepaids: 'prepaids/getPrepaidsByTeacher',
    }),
    utils () {
      return utils
    },
    moment () {
      return moment
    },
    licenses () {
      return this.getPrepaids(me.id)?.available?.map(prepaid => {
        prepaid.courseBits = this.numericalCourses(prepaid, 'prepaid')
        return prepaid
      })
    },
    students () {
      return this.classroomMembers.map(member => {
        member.courseBits = this.numericalCourses(member, 'member')
        return member
      })
    },
  },
  methods: {
    licenseName (license) {
      if (license.type === 'starter_license') {
        return $.i18n.t('teacher.starter_license')
      }
      const includedCourseIDs = license.includedCourseIDs
      if (includedCourseIDs) {
        return $.i18n.t('teacher_customized_license')
      } else {
        return $.i18n.t('teacher.full_license')
      }
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
.apply-license {
  width: 1200px;
}
 .license-grid, .user-grid {
   display: grid;
   // checkbox, name, endDate, cs1, gd1, cs2, gd2, gd3 cs3, cs4, cs5, cs6, wd2, junior, hackstack
   grid-template-columns: 5% 20% 15% repeat(12, 5%);
   grid-template-rows: 100%;
 }
</style>