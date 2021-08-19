<script>
import { mapGetters, mapActions, mapState } from 'vuex'
import utils from 'core/utils'

export default Vue.extend({
  name: 'outcomes-report-result-component',
  props: {
    org: {
      type: Object,
      required: true
    },
    isSubOrg: {
      type: Boolean,
      default: false
    },
    editing: {
      type: Boolean,
      default: false
    },
    included: {
      type: Boolean,
      default: true
    }
  },

  data () {
    return {
      
    }
  },

  computed: {
    ...mapState('courses', {
      coursesLoaded: 'loaded',
      sortedCourses: (state) => utils.sortCourses(_.values(state.byId))
    }),

    kindString () {
      if (this.org.kind == 'administrative-region' && this.org.geo && this.org.geo.country == 'US' && /^en/.test(me.get('preferredLanguage')))
        return 'State'
      const key = {
        'administrative-region': 'teachers_quote.state',
        'school-district': 'teachers_quote.district_label',
        'school-admin': 'outcomes.school_admin',
        'school-network': 'outcomes.school_network',
        'school-subnetwork': 'outcomes.school_subnetwork',
        school: 'teachers_quote.organization_label',
        teacher: 'courses.teacher',
        classroom: 'outcomes.classroom',
        student: 'courses.student',
      }[this.org.kind]
      return $.i18n.t(key)
    },

    codeLanguageStats () {
      if (!this.org.progress) return 
      let languageStats = {}
      let totalPrograms = 0
      for (let language of ['python', 'javascript', 'cpp']) {
        let programs = this.org.progress.programsByLanguage[language]
        totalPrograms += programs
        languageStats[language] = { programs }
      }
      for (let [language, stats] of Object.entries(languageStats)) {
        stats.percentage = Math.round(100 * stats.programs / totalPrograms)
        stats.name = {python: 'Python', 'javascript': 'JavaScript', 'cpp': 'C++'}[language]
        stats.language = language
      }
      return Object.values(languageStats).sort((a, b) => b.programs - a.programs)
    },

    coursesWithProgress () {
      let courses = _.cloneDeep(this.sortedCourses)
      let alreadyCoveredConcepts = []
      for (let course of courses) {
        course.name = utils.i18n(course, 'name')
        course.studentsStarting = this.org.progress.studentsStartingCourse[course._id] || 0
        course.studentsCompleting = this.org.progress.studentsCompletingCourse[course._id] || 0
        course.completion = course.studentsStarting ? Math.min(1, course.studentsCompleting / course.studentsStarting) : 0
        course.newConcepts = _.difference(course.concepts, alreadyCoveredConcepts)
        alreadyCoveredConcepts = _.union(course.concepts, alreadyCoveredConcepts)
      }

      return courses
    },
  },

  created () {
    this.fetchCourses()
  },

  // TODO: figure out how to sync included status back to the parent
  // https://vuejs.org/v2/guide/components-custom-events.html#sync-Modifier
  
  mounted () {
  },

  methods: {
    ...mapActions({
      fetchCourses: 'courses/fetch',
    }),

    phoneString (phone) {
      if (!/[0-9]{10}/.test(phone)) return phone
      return `(${phone.slice(0, 3)}) ${phone.slice(3, 6)}-${phone.slice(6, 10)}`
    },
  }
});
</script>


<template lang="pug">
.outcomes-report-result-component(v-if="included || editing")
  .address
    p
      b #{kindString}:
      span= " "
      b= org.displayName || org.name
      if org.email
        span  (#{org.email})
      label.edit-label.editing-only(:for="'includeOrg-' + org._id" v-if="editing && isSubOrg")
        span  &nbsp;
        input(:id="'includeOrg-' + org._id" name="'includeOrg-' + org._id" type="checkbox" v-model="included")
        span  include
      span(v-if="org.address && included")
        br
        span= org.address

  .block(v-if="included && coursesLoaded")
    h1 Course Progress
    for course in coursesWithProgress
      .course.dont-break(v-if="course.studentsStarting")
        h3= course.name
        .bar
          .el
            svg(width=100, height=100)
              - var radius = 50
              - var fullCircleStroke = 2*Math.PI*radius / 2
              circle.bottom(r=radius,cx=50,cy=50)
              //circle.top(r=radius / 2,cx=50,cy=50,style="stroke-dasharray: #{fullCircleStroke/100*course.completion} #{fullCircleStroke}")
              circle.top(r=radius / 2, cx=50, cy=50, :style="'stroke-dasharray: calc(3.1415926 * 50 * ' + course.completion + ') calc(3.1415926 * 50)'")
              
          .el
            .big #{Math.round(100 * course.completion)}%
            .under complete
          .el
            .big #{course.studentsStarting}
            .under students
          .el.concepts-list
            b Key Concepts:
            ul
              li(v-for="concept in course.newConcepts")
                span {{$t('concepts.' + concept)}}

  .block(v-if="org.progress && org.progress.programs > 1 && included")
    .course.dont-break
      h3 Code Languages
        .bar
          .el
            svg(width=100, height=100)
              - var radius = 50
              - var fullCircleStroke = 2*Math.PI*radius / 2
              circle.bottom(r=radius,cx=50,cy=50)
              //circle.top(r=radius / 2, cx=50, cy=50, :style="'stroke-dasharray: ' + fullCircleStroke/100*33 + ' ' + 2*Math.PI*radius / 2")
              circle.top(r=radius / 2, cx=radius, cy=radius, :style="'stroke-dasharray: calc(3.1415926 * radius * ' + (codeLanguageStats[0].percentage / 100) + ') calc(3.1415926 * radius)'")
              
          .el
            .big(v-if="codeLanguageStats[0]") #{codeLanguageStats[0].percentage}%
            .under= codeLanguageStats[0].name
          .el
            .big= org.progress.programs.toLocaleString()
            .under programs
          .el.concepts-list
            b Programs:
            ul
              li(v-for="languageStats, index in codeLanguageStats")
                span #{languageStats.name}: #{languageStats.programs.toLocaleString()} (#{languageStats.percentage}%)
  
  .dont-break.block(v-if="org.progress && org.progress.programs > 1 && included")
    h1 Summary
    h4 Using CodeCombat&apos;s personalized learning engine, your...
    .fakebar
      div
        | #{org.progress.studentsWithCode.toLocaleString()}
        = " "
        small students
    h4 wrote...
    .fakebar
      div
        | #{org.progress.programs.toLocaleString()}
        = " "
        small computer programs
    h4 across an estimated...
    .fakebar
      div
        | #{org.progress.linesOfCode.toLocaleString()}
        = " "
        small lines of code
    if org.progress.projects > 9
      h4 and expressed creativity by building
      .fakebar
        div
          | #{org.progress.projects.toLocaleString()}
          = " "
          small standalone game and web projects
  
  
  .dont-break.block
    .rob-row
      if org.classrooms && org.classrooms.length
        .left-col
          h1 Classes
          for clazz in org.classrooms
            b= clazz.name
            ul
              li Language: #{clazz.codeLanguage}
              li #{clazz.studentCount} students

  .block(v-if="included")
    h1 Uncategorized Info
    ol
      if org.clan
        li
          a(:href="'https://codecombat.com/league/' + org.clan") View AI League Team
        li
          span (summary AI League stats about CodePoints, # participants, top players, etc.)
      if org.website
        li
          a(:href="org.website" rel="nofollow" target="_blank") #{org.name} website
      if org.geo && org.geo.county
        li County: #{org.geo.county}
      if org.phone
        li
          span= 'Phone: '
          a(:href="'tel:' + org.phone")= phoneString(org.phone)
      if org.progress && org.progress.playtime
        li
          span Student play time: #{Math.round(org.progress.playtime / 3600).toLocaleString()} hours
      if org.progress && org.progress.sampleSize < org.progress.populationSize
        li
          span Progress stats based on sampling #{org.progress.sampleSize.toLocaleString()} of #{org.progress.populationSize.toLocaleString()} students
      if org.level
        li
          span School level: #{org.level}
      if org.schools && !isNaN(org.schools)
        li
          span Total schools in #{org.kind}: #{org.schools.toLocaleString()}
        li TODO: show info for all active schools we have for this #{org.kind}, not just the number of schools that exist
      else if org.schools && org.schools.length === 1
        li
          a(:href="'https://codecombat.com/outcomes-report/school/' + org.schools[0]._id") School: #{org.schools[0].name}
      else if org.schools
        li
          span # of schools: #{org.schools.length.toLocaleString()}
      if org.teachers && !isNaN(org.teachers)
        li
          span Total teachers in #{org.kind}: #{org.teachers.toLocaleString()}
        li TODO: show info for all registered teachers we have for this #{org.kind}, not just the number of teachers that exist
      else if org.teachers && org.teachers.length === 1
        li
          a(:href="'https://codecombat.com/outcomes-report/teacher/' + org.teachers[0]._id") Teacher: #{org.teachers[0].displayName}
      else if org.teachers
        li
          span # of teachers: #{org.teachers.length.toLocaleString()}
      if org.classrooms && !isNaN(org.classrooms)
        li
          span Total classrooms in #{org.kind}: #{org.classrooms.toLocaleString()}
      else if org.classrooms && org.classrooms.length === 1
        li
          a(:href="'https://codecombat.com/outcomes-report/classroom/' + org.classrooms[0]._id") Classroom: #{org.classrooms[0].name} #{org.classrooms[0].codeLanguage} - #{org.classrooms[0].studentCount.toLocaleString()} students
      else if org.classrooms
        li
          span # of classrooms: #{org.classrooms.length.toLocaleString()}
      if org.students && !isNaN(org.students)
        li
          span Total students in #{org.kind}: #{org.students.toLocaleString()}
        li TODO: show info for all registered students we have for this #{org.kind}, not just the number of students that exist
      else if org.students && org.students.length === 1
        li
          a(:href="'https://codecombat.com/outcomes-report/student/' + org.students[0]._id") Student: #{org.students[0].displayName} - #{org.students[0].progress ? org.students[0].progress.programs.toLocaleString() + ' programs' : ''}
      else if org.students
        li
          span # of students: #{org.students.length.toLocaleString()}
      if org.licenses && ((org.licenses.usage && org.licenses.total) || org.licenses.hasAccessToShared)
        li
          span= licenses

</template>


<style lang="scss">
#page-outcomes-report .outcomes-report-result-component {
  .address {
    margin-top: 0.25in;
    padding-left: 0.5in;
    padding-right: 0.5in;
    text-align: left;
    p {
      line-height: 18pt;
      font-size: 15pt;
      margin-bottom: 0.1in;
    }
  }
  .course {
    margin-bottom: 0.25in;
    .bar {
      margin-bottom: 0.0in;
      page-break-inside: avoid;
      //border: 1px solid orange
      .concepts-list {
        max-width: 30%;
      }
      .el {
        margin-right: 0.25in;
        svg {
          transform: rotate(-90deg);
        }
        circle.top {
          fill: rgb(242, 190, 24);
          stroke-width: 50;
          stroke: rgb(14,75,96);
        }
        circle.bottom {
          fill: rgb(242, 190, 24);
        }

        .big {
          display: block;
          font-size: 41pt;
          line-height: 41pt;
          font-family: 'Open Sans', sans-serif;
          font-weight: 600;
          text-align: center;
          width: 1.5in;
        }
        .under {
          display: block;
          text-align: center;
          width: 1.5in;
        }
        li {
          line-height: 14pt;
          font-size: 12pt;
        }
        height: 1in;
        float: left;
      }
    }
    .bar::after {
      clear: both;
      display: table;
      content: " ";
    }
    h3 {
      font-family: 'Open Sans', sans-serif;
      font-weight: 600;
      font-size: 18pt;
    }
  }
  .block {
    margin-top: 0;
    margin-left: 0.5in;
    margin-right: 0.5in;

    h1, h2 {
      font-family: 'Open Sans', sans-serif;
      font-size: 22pt;
      font-weight: 100;
      margin-top: 0.5in;
      border-bottom: 1px solid #ccc;
      border-radius: 0px;
      margin-bottom: 0.1in;
    }
    h3, h4 {
      font-family: 'Open Sans', sans-serif;
      font-weight: 600;
    }
    h1 {
      font-size: 18pt;
      line-height: 18pt;
    }
    h2 {
      font-size: 14pt;
      line-height: 15pt;
    }
    h4 {
      font-size: 18pt;
      line-height: 18pt;
      font-weight: 600;
    }
    .fakebar {
      margin-top: 0.1in;
      margin-bottom: 0.25in;

      background-color: rgb(31, 87, 43);
      -webkit-print-color-adjust: exact !important;
      background: linear-gradient(rgb(31, 87, 43), rgb(31, 87, 43)) !important;

      height: 0.4in;
      line-height: 0.4in;
      > div {
        background-color: white;
        -webkit-print-color-adjust: exact !important;
        background: linear-gradient(white, white) !important;
        height: 100%;
        padding-left: 0.1in;
        float: right;
        font-size: 32pt;
        font-weight: 600;
        small {
          font-size: 18pt;
          font-weight: 600;
        }
      }
      > div::after {
        clear: both;
        content: ' ';
        display: table;
      }
    }
    p {
      font-size: 14pt;
      line-height: 18pt;
    }
    .left-col {
      page-break-inside: avoid;
      float: left;
      width: 4in;
      margin-right: 1in;
    }
    .right-col {
      page-break-inside: avoid;
      float: left;
      width: 2.5in;
      font-size: 14pt;
      line-height: 18pt;
      ul {
        padding-left: 2ex;
      }
    }
    .row-row {
      page-break-inside: avoid;
    }
    .rob-row::after {
      page-break-inside: avoid;
      content: " ";
      display: table;
      clear: both;
    }
  }
  .dont-break {
    page-break-inside: avoid;
  }

  &.sub-org {
    .block {
      h1 {
        font-size: 16pt;
        line-height: 16pt;
      }
      h2 {
        font-size: 14pt;
        line-height: 14pt;
      }
      h3 {
        font-size: 12pt;
        line-height: 12pt;
      }
      h4 {
        font-size: 10pt;
        line-height: 10pt;
      }
    }
  }
}
</style>


