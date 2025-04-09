<template>
  <div class="style-ozaria apply-license">
    <div class="form">
      <div class="licenses">
        <div class="title license-grid">
          <div></div> <!-- checkbox -->
          <div></div> <!-- name -->
          <div>endDate</div>
          <div v-for="course in utils.orderedCourseIDs">
            {{utils.courseAcronyms[course]}}
          </div>
        </div>
        <div class="license-grid" v-for="license in licenses">
          <div>
            <input type="radio" value="license" />
          </div>
          <div></div>
          <div class="endDate">
            {{license.endDate}}
          </div>
          <div v-for="(course, index) in utils.orderedCourseIDs">
            <input type="checkbox" class="checkbox-course" :checked="(license.courseBits & Math.pow(2, index)) ? 'checked' : undefined" onclick="return false" />
          </div>
        </div>
      </div>
      <div class="students user-grid" v-for="student in students">
        <div>
          <input type="checkbox" />
        </div>
        <div>
          {{ student.name }}
        </div>
        <div class="endDate">
        </div>
        <div v-for="(course, index) in utils.orderedCourseIDs">
          <input type="checkbox" class="checkbox-course" :checked="(student.courseBits & Math.pow(2, index)) ? 'checked' : undefined" onclick="return false" />
        </div>
      </div>

    </div>
    <div class="buttons">

    </div>
  </div>
</template>

<script>
 import utils from 'app/core/utils'
 import { mapGetters } from 'vuex'
 export default {
   data () {
     return {
     }
   },
   methods: {
     numericalCourses (object, oType) {
       if (oType === 'prepaid') {
         if (!(object.includedCourseIDs?.length)) {
           return utils.courseNumbericalStatus.FULL_ACCESS
         }
         const fun = (s, k) => {
           return s + utils.courseNumbericalStatus[k]
         }
         return _.reduce(object.includedCourseIDs, fun, 0)
       } else if (oType === 'member') {
       }
     }
   },
   computed: {
     ...mapGetters({
       selectedStudentIds: 'baseSingleClass/selectedStudentIds',
       classroomMembers: 'teacherDashboard/getMembersCurrentClassroom',
       getPrepaids: 'prepaids/getPrepaidsByTeacher'
     }),
     utils () {
       return utils
     },
     licenses () {
       return this.getPrepaids(me.id).available.map(prepaid => {
         prepaid.courseBits = this.numbericalCourses(prepaid, 'prepaid')
         return prepaid
       })
     },
     students () {
       return this.classroomMembers.map(member => {
         member.courseBits = member.prepaidNumbericalCourses()
         return member
       })
     }
   }
 }
</script>

<style lang="scss" scoped>
 .license-grid, .user-grid {
   display: grid;
   // checkbox, name, endDate, cs1, gd1, cs2, gd2, gd3 cs3, cs4, cs5, cs6, wd2, junior, hackstack
   grid-template-columns: 5% 20% 15% repeat(12, 5%);
   grid-template-rows: 100%;
 }
</style>