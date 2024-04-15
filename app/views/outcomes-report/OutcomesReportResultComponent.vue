<script>
import { mapActions, mapState } from 'vuex'
import utils from 'core/utils'
import SummaryComponent from './SummaryComponent'
import ClanLeagueStatsComponent from './ClanLeagueStatsComponent'

export default Vue.extend({
  name: 'OutcomesReportResultComponent',
  components: {
    SummaryComponent,
    ClanLeagueStatsComponent
  },
  props: {
    org: {
      type: Object,
      required: true
    },
    otherOrg: {
      type: Object,
      required: false,
      default: () => null
    },
    isSubOrg: {
      type: Boolean,
      default: false
    },
    editing: {
      type: Boolean,
      default: false
    },
    parentOrgKind: {
      type: String,
      default: null
    },
    showLicense: {
      type: Boolean,
      default: false
    },
    showLicenseSummary: {
      type: Boolean,
      default: false
    },
    showOther: {
      type: Boolean,
      default: false
    },
    leagueStats: {
      type: Object,
      required: false,
      default: () => null
    },
    parentOrgId: {
      type: String,
      default: null
    }
  },

  data () {
    return {
      // TODO: some bug where printing gets large horizontal margins after we customize included schools and finish editing
      included: !this.isSubOrg || this.org.initiallyIncluded
    }
  },

  computed: {
    ...mapState('courses', {
      coursesLoaded: 'loaded',
      sortedCourses: (state) => utils.sortCourses(_.values(state.byId)),
      sortedOtherCourses: (state) => utils.sortOtherCourses(_.values(state.otherById))
    }),

    kindString () {
      return utils.orgKindString(this.org.kind, this.org)
    },

    codeLanguageString () {
      return utils.capitalLanguages[this.org.codeLanguage] || ''
    },

    codeLanguageStats () {
      if (!this.org.progress) return
      let languageStats = {}
      let totalPrograms = 0
      for (const language of ['python', 'javascript', 'cpp', 'java']) {
        if (language === 'java' && !this.org.newReport) continue
        let programs
        if (this.org.newReport) {
          programs = this.org.progress.languages[language] || 0
        } else {
          programs = this.org.progress.programsByLanguage[language]
        }
        if (this.showOther && this.otherOrg?.progress) {
          if (this.otherOrg.newReport) {
            programs += this.otherOrg.progress.languages[language] || 0
          } else {
            if (language !== 'java') {
              programs += this.otherOrg.progress.programsByLanguage[language]
            }
          }
        }
        totalPrograms += programs
        languageStats[language] = { programs }
      }
      for (const [language, stats] of Object.entries(languageStats)) {
        stats.percentage = Math.round(100 * stats.programs / totalPrograms)
        stats.name = utils.capitalLanguages[language]
        stats.language = language
      }
      languageStats = _.omit(languageStats, (s) => !s.programs || s.programs < totalPrograms * 0.005) // Skip low usage languages
      languageStats = Object.values(languageStats).sort((a, b) => b.programs - a.programs) // Sorted array
      let otherLanguagesCumulativePercentage = 0
      for (const stats of languageStats) {
        // Keep track of how much all languages have contributed so that we can draw our pie chart
        stats.otherLanguagesCumulativePercentage = otherLanguagesCumulativePercentage
        otherLanguagesCumulativePercentage += stats.percentage
      }
      return languageStats
    },

    licenses () {
      // licenses are in shared db so do not merge coco & oz
      return this.org.newLicenses || []
    },

    totalLicense () {
      return this.licenses.reduce((acc, license) => {
        acc.used += license.used
        acc.count += license.count
        license.teachers?.forEach(tea => acc.teachers.add(tea))
        license.schools?.forEach(sch => acc.schools.add(sch))
        return acc
      }, { used: 0, count: 0, teachers: new Set(), schools: new Set() })
    },

    coursesWithProgress () {
      if (!this.org.progress) return []
      let courses = _.cloneDeep(this.sortedCourses)
      courses = this.formatCourse(courses, this.org.progress, this.org.newReport)
      if (this.showOther && this.otherOrg?.progress) {
        let otherCourses = _.cloneDeep(this.sortedOtherCourses)
        otherCourses = this.formatCourse(otherCourses, this.otherOrg.progress, this.otherOrg.newReport)
        courses = courses.concat(otherCourses)
      }

      return courses
    },

    schoolCount () {
      let schools = this.org.progress.schoolCount
      if (this.showOther && this.otherOrg?.progress) {
        schools += this.otherOrg.progress.schoolCount
      }
      return schools
    },

    teacherCount () {
      let teachers = this.org.progress.teacherCount
      if (this.showOther && this.otherOrg?.progress) {
        teachers += this.otherOrg.progress.teacherCount
      }
      return teachers
    },

    studentsWithCode () {
      let students = this.org.progress.studentsWithCode
      if (this.showOther && this.otherOrg?.progress) {
        students = Math.max(students, this.otherOrg.progress.studentsWithCode)
        // use max here because we cannot determine duplicated students
      }
      return students
    },

    projects () {
      let projects = this.org.progress.projects
      if (this.showOther && this.otherOrg?.progress) {
        projects += this.otherOrg.progress.projects
      }

      return projects
    },

    programs () {
      let programs = this.org.progress.programs
      if (this.showOther && this.otherOrg?.progress) {
        programs += this.otherOrg.progress.programs
      }
      return programs
    },

    linesOfCode () {
      let lines = this.org.progress.linesOfCode
      if (this.showOther && this.otherOrg?.progress) {
        lines += this.otherOrg.progress.linesOfCode
      }
      return lines
    },

    playtime () {
      let time = this.org.progress.playtime
      if (this.showOther && this.otherOrg?.progress) {
        time += this.otherOrg.progress.playtime
      }
      return time
    },
    populationSize () {
      let size = this.org.progress.populationSize
      if (this.showOther && this.otherOrg?.progress) {
        size += this.otherOrg.progress.populationSize
      }
      return size
    },

    sampleSize () {
      let size = this.org.progress.sampleSize
      if (this.showOther && this.otherOrg?.progress) {
        size += this.otherOrg.progress.sampleSize
      }
      return size
    },

    mapUrl () {
      if (!this.org.address) return null
      let orgName = this.org.displayName || this.org.name
      if (this.org.kind === 'school-district' && !/school.*district|isd|usd|unified/.test(orgName)) { orgName += ' School District' }
      const addresses = [orgName + ', ' + this.org.address]
      for (const subOrg of this.org.subOrgs || []) {
        if (subOrg.address) {
          let subOrgName = subOrg.displayName || subOrg.name
          if (subOrg.kind === 'school-district' && !/school.*district|isd|usd|unified/.test(subOrgName)) { subOrgName += ' School District' }
          addresses.push(subOrgName + ', ' + subOrg.address)
        }
      }
      // One address, do a search-type link
      let url = `https://www.google.com/maps/search/?api=1&query=${addresses.map(a => encodeURIComponent(a))}`
      if (addresses.length > 1) {
        // Multiple addresses, abuse direction-type link to show them all
        // Could add &destination=${encodeURIComponent(addresses[0])} to activate the driving directions, but probably better without
        const urlWithSubOrgs = `https://www.google.com/maps/dir/?api=1&origin=${encodeURIComponent(addresses[0])}&waypoints=${addresses.slice(1).map(a => encodeURIComponent(a)).join('|')}`
        if (urlWithSubOrgs.length < 8192) { url = urlWithSubOrgs }
      }
      return url
    },

    isAdmin () {
      return me.isAdmin()
    },

    isSchoolAdmin () {
      return me.isSchoolAdmin()
    },

    topTeacherInfo () {
      const formatTeacher = (tea) => {
        if (!tea) {
          return ''
        }
        const linkedTeacher = `<a href="/outcomes-report/teacher/${tea._id}" target="_blank">${tea.firstName}</a>`
        const unlinkedTeacher = `<span>${tea.firstName}</span>`
        let teacherTag = unlinkedTeacher
        if (me.isAdmin()) {
          teacherTag = linkedTeacher
        } else if (this.org.kind === 'school-district' || this.parentOrgKind === 'school-district') {
          if (me.isDistrictAdmin(this.org._id) || me.isDistrictAdmin(this.parentOrgId)) {
            teacherTag = linkedTeacher
          }
        }
        return teacherTag
      }
      const n = this.teacherCount - this.org.topTeachers.length
      let info
      const A = formatTeacher(this.org.topTeachers[0])
      const B = formatTeacher(this.org.topTeachers[1])
      if (n <= 0) {
        if (!B) {
          info = $.i18n.t('outcomes.top_teacher_info_2', {
            A
          })
        } else {
          info = $.i18n.t('outcomes.top_teacher_info_1', {
            A,
            B
          })
        }
      } else {
        info = $.i18n.t('outcomes.top_teacher_info', {
          A,
          B,
          n
        })
      }
      // $.i18.t encode the html
      const txt = document.createElement('textarea')
      txt.innerHTML = info
      return txt.value
    }
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
      fetchCourses: 'courses/fetch'
    }),

    phoneString (phone) {
      if (!/[0-9]{10}/.test(phone)) return phone
      return `(${phone.slice(0, 3)}) ${phone.slice(3, 6)}-${phone.slice(6, 10)}`
    },

    formatLicenseName (license) {
      if (license._id === null) {
        return $.i18n.t('teacher.full_license')
      }
      const ids = license._id.split('-').slice(1) // first is ''

      return $.i18n.t('teacher.customized_license') + ': ' + ids.map(id => utils.courseAcronyms[id]).join('+')
    },

    formatNumber (num) {
      if (num < 10000) return num.toLocaleString()
      if (num < 999500) return Math.round(num / 1000) + 'K'
      if (num < 10000000) return (num / 1000000).toFixed(1) + 'M'
      if (num < 999500000) return Math.round(num / 1000000) + 'M'
      if (num < 10000000000) return (num / 1000000000).toFixed(1) + 'B'
      if (num < 999500000000) return Math.round(num / 1000000000) + 'B'
      return Math.round(num / 1000000000000) + 'T'
    },

    formatCourse (courses, progress, newReport) {
      let alreadyCoveredConcepts = []
      for (const course of courses) {
        course.name = utils.i18n(course, 'name')
        course.acronym = utils.courseAcronyms[course._id]
        course.studentsStarting = (progress.studentsStartingCourse || {})[course._id] || 0
        course.studentsCompleting = (progress.studentsCompletingCourse || {})[course._id] || 0
        course.completion = course.studentsStarting ? Math.min(1, course.studentsCompleting / course.studentsStarting) : 0
        if (newReport) {
          const courseCompleteLevels = progress.courseCompleteLevels || {}
          const courseStartingStudents = progress.courseStartingStudents || {}
          const completeLevels = Math.max(...Object.values(courseCompleteLevels[course._id] || {})) || 0
          course.studentsStarting = courseStartingStudents[course._id] || 0
          course.completeLevels = completeLevels
          course.completion = Math.min(1, course.completeLevels / (progress.courseAllLevels[course._id] || 1))
        }
        course.newConcepts = _.difference(course.concepts, alreadyCoveredConcepts)
        alreadyCoveredConcepts = _.union(course.concepts, alreadyCoveredConcepts)
      }
      if (newReport) {
        courses = _.filter(courses, (course) => course.completeLevels >= 1)
      } else {
        courses = _.filter(courses, (course) => (course.studentsStarting + course.studentsCompleting) >= Math.min(100, Math.max(2, Math.ceil(0.02 * progress.studentsWithCode))))
      }

      return courses
    }
  }
})
</script>

<template lang="pug">
.outcomes-report-result-component(v-if="included || editing")
  .page-break(v-if="isSubOrg && included")
    hr

  .address
    p
      b
        if org.archived
          em #{$t("outcomes.archived")}:
        else
          span #{kindString}:
      span= " "
      if isSubOrg
        a(:href="'/outcomes-report/' + org.kind + '/' + org._id" target="_blank")
          b= org.displayName || org.name
      else
        b= org.displayName || org.name
        if included && isAdmin && editing && org.kind == 'school-district' && org['administrative-region']
          span ,&nbsp;
          a(:href="'/outcomes-report/administrative-region/' + org['administrative-region'].region.toLowerCase()" target="_blank")= org['administrative-region'].region
        if included && isAdmin && editing && org.kind == 'school-district' && org['country']
          span ,&nbsp;
          a(:href="'/outcomes-report/country/' + org['country'].country.toLowerCase()" target="_blank")= org['country'].country
      if org.email
        span  (#{org.email})
      if org.kind == 'student' && org.displayName && org.name && (org.name.replace(/\W/g, '').toLowerCase() != org.displayName.replace(/\W/g, '').toLowerCase())
        span  (#{org.name})

      if codeLanguageString
        span  (#{codeLanguageString})
      if !included && org.progress && studentsWithCode && org.kind != 'student'
        span  - #{studentsWithCode} #{$t('courses.students').toLocaleLowerCase()}
      label.edit-label.editing-only(:for="'includeOrg-' + org._id" v-if="editing && isSubOrg")
        span  &nbsp;
        input(:id="'includeOrg-' + org._id" name="'includeOrg-' + org._id" type="checkbox" v-model="included")
        span= ' '
        span= $t('outcomes.include').toLocaleLowerCase()
      if included && isAdmin && editing
        span(v-if="org.address")
          br
          span= org.address
          span
            span= ' '
            a(:href="mapUrl" target="_blank" rel="nofollow") (map)
        //if org.geo && org.geo.county
        //  br
        //  span County: #{org.geo.county}
        if org.phone || org.website
          br
        if org.phone
          span= 'Phone: '
          a(:href="'tel:' + org.phone")= phoneString(org.phone)
          span &nbsp;
        if org.website
          span= ' Website: '
          a(:href="org.website" rel="nofollow" target="_blank")= org.website
      if included && org.students && org.kind == 'course' && parentOrgKind != 'student'
        for student in org.students
          br
          span= $t('courses.student') + ': '
          a(:href="'/outcomes-report/student/' + student._id" target="_blank")
            b= student.displayName
      if included && org.classrooms && org.kind == 'student' && parentOrgKind != 'classroom'
        for classroom in org.classrooms
          br
          span= $t('outcomes.classroom') + ': '
          a(:href="'/outcomes-report/classroom/' + classroom._id" target="_blank")
            b= classroom.name
          span  #{classroom.codeLanguage} - #{formatNumber(classroom.studentCount)} #{$t('courses.students').toLocaleLowerCase()}
      if included && org.teachers && ['classroom', 'student'].indexOf(org.kind) != -1 && ['teacher', 'classroom'].indexOf(parentOrgKind) == -1
        for teacher in org.teachers
          br
          span= $t('courses.teacher') + ': '
          a(:href="'/outcomes-report/teacher/' + teacher._id" target="_blank")
            b= teacher.displayName
          if teacher.email
            span  (#{teacher.email})
      if included && org.schools && org.kind == 'teacher' && parentOrgKind != 'school'
        for school in org.schools
          br
          span= 'School: '
          a(:href="'/outcomes-report/school/' + school._id" target="_blank")
            b= school.name
      if included && org['school-district'] && ['school', 'teacher', 'school-admin'].indexOf(org.kind) != -1 && ['school-district', 'school'].indexOf(parentOrgKind) == -1 && (isSchoolAdmin || (isAdmin && (editing || org.kind != 'teacher')))
        br
        span= 'District: '
        a(:href="'/outcomes-report/school-district/' + org['school-district']._id" target="_blank")
          b= org['school-district'].name
      if included && org['school-admin'] && ['school', 'teacher'].indexOf(org.kind) != -1 && parentOrgKind != 'school-admin' && org['school-admin'].displayName != 'Anonymous'
        br
        span= $t('nav.admin') + ': '
        a(:href="'/outcomes-report/school-admin/' + org['school-admin']._id" target="_blank")
          b= org['school-admin'].displayName

      .license-summary(v-if="showLicenseSummary && totalLicense.count > 0")
        p(v-html="$t('outcomes.license_template', { used: totalLicense.used.toLocaleString(), available: totalLicense.count.toLocaleString() })")
        p(v-html="$t('outcomes.licensed_teachers', { teachers: totalLicense.teachers.size.toLocaleString() })")
        p(v-html="$t('outcomes.licensed_schools', { schools: totalLicense.schools.size.toLocaleString() })")
      .top-teachers(v-if="['school', 'school-admin', 'school-district'].includes(org.kind) && teacherCount > 0")
        p(v-html="topTeacherInfo")

  .block(v-if="org.kind === 'school-district'")
    summary-component(:students="studentsWithCode" :teachers="teacherCount" :schools="schoolCount" :licensesUsed="totalLicense?.used" v-if="org.progress")

  .block(v-if="showLicense")
    h1= $t('outcomes.license_stats')
    for license in licenses
      .license
        h3= formatLicenseName(license)
        span= "Used: " + license.used
        span= "Available: " + license.count

  .block(v-if="included && coursesLoaded && coursesWithProgress[0] && (coursesWithProgress[0].completion !== null || coursesWithProgress[0].studentsStarting > 1)" :class="isSubOrg && coursesWithProgress.length > 1 ? 'dont-break' : ''")
    h1= $t('teacher.course_progress')
    for course in coursesWithProgress
      if !isSubOrg || coursesWithProgress.length == 1
        .course.dont-break.full-row
          h3= course.name
          .bar
            .el
              svg(width=100, height=100)
                - var radius = 50
                circle.bottom(r=radius,cx=radius, cy=radius)
                circle.top(r=radius / 2, cx=radius, cy=radius, :style="'stroke-dasharray: ' + 3.1415926 * 50 * course.completion + 'px ' + 3.1415926 * 50 + 'px'")
            .el
              .big #{Math.round(100 * course.completion)}%
              .under= $t('courses.complete')
            .el(v-if="org.kind != 'student'")
              .big #{formatNumber(course.studentsStarting)}
              .under= (course.studentsStarting === 1 ? $t("courses.student") : $t("courses.students")).toLocaleLowerCase()
            .el.concepts-list
              b= $t('outcomes.key_concepts') + ':'
              ul
                li(v-for="concept in course.newConcepts.slice(0, 6)")
                  span {{$t('concepts.' + concept)}}
      else
        .course.inline
          .el
            svg(width=100, height=100)
              - var radius = 50
              circle.bottom(r=radius,cx=radius,cy=radius)
              circle.top(r=radius / 2, cx=radius, cy=radius, :style="'stroke-dasharray: ' + 3.1415926 * 50 * course.completion + 'px ' + 3.1415926 * 50 + 'px'")
            if org.kind != 'student'
              .overlay-text.top-text #{formatNumber(course.studentsStarting)} #{(course.studentsStarting === 1 ? $t('courses.student') : $t('courses.students')).toLocaleLowerCase()}
            .overlay-text.mid-text= course.acronym
            .overlay-text.bot-text= Math.round(100 * course.completion) + '% ' + $t('courses.complete')

  .block(v-if="org.progress && programs > 1 && included && codeLanguageStats.length > 1 && !codeLanguageString")
    // TODO: somehow note the code language if we are skipping this section (like 100% Python at school level)
    .course.dont-break.full-row
      h3= $t('outcomes.code_languages')
      .bar
        .el
          svg(width=100, height=100)
            - var radius = 50
            circle.bottom(r=radius,cx=radius, cy=radius)
            for stats, index in codeLanguageStats
              circle(r=radius / 2, cx=radius, cy=radius, :class="'top top' + index", :style="'stroke-dasharray: ' + 3.1415926 * 50 * stats.percentage / 100 + 'px ' + 3.1415926 * 50 + 'px; stroke-dashoffset: ' + 3.1415926 * 50 * -stats.otherLanguagesCumulativePercentage / 100 + 'px;'")

        for stats, index in codeLanguageStats
          .el.code-language-stat
            .big #{stats.percentage}%
            .under
              img.code-language-icon(alt="" :src="'/images/common/code_languages/' + stats.language + '_small.png'")
              span= stats.name

  .dont-break.block.summary(v-if="org.progress && programs > 1 && included")
    h1= $t('clans.summary')
    if org.kind != 'student'
      h4= $t('outcomes.using_codecombat')
      .fakebar
        div
          | #{formatNumber(studentsWithCode)}
          = " "
          small= (studentsWithCode == 1 ? $t('courses.student') : $t('courses.students')).toLocaleLowerCase()
    if org.kind === 'student'
      h4= (org.displayName || org.name) + ' ' + $t('outcomes.wrote')
    else
      h4= $t('outcomes.wrote')
    .fakebar
      div
        | #{formatNumber(programs)}
        = " "
        small= programs == 1 ? $t('outcomes.computer_program') : $t('outcomes.computer_programs')
    h4= $t('outcomes.across_an_estimated')
    .fakebar
      div
        | #{formatNumber(linesOfCode)}
        = " "
        small= linesOfCode == 1 ? $t('outcomes.line_of_code') : $t('outcomes.lines_of_code')
    if org.progress && (playtime >= 1.5 * 3600 || org.kind == 'student')
      h4= $t('outcomes.in')
      .fakebar
        div
          if playtime > 1.5 * 3600
            span= formatNumber(Math.round(playtime / 3600))
          else
            span= (playtime / 3600).toFixed(1)
          = " "
          small= $t('outcomes.coding_hours')
    if projects >= 1 + Math.min(100, Math.floor(0.02 * studentsWithCode))
      h4= $t('outcomes.expressed_creativity')
      .fakebar
        div
          | #{formatNumber(projects)}
          = " "
          small= $t('outcomes.report_content_1') + (projects == 1 ? $t('outcomes.project') : $t('outcomes.projects'))
    if org.progress && sampleSize < populationSize
      em=  "* " + $t('outcomes.progress_stats', {sampleSize: formatNumber(sampleSize), populationSize: formatNumber(populationSize)})

  .block(v-if="['school', 'teacher', 'school-district'].includes(org.kind) && leagueStats && leagueStats.totalPlayers > 1")
    h1= $t('outcomes.ai_league')
    clan-league-stats-component(:stats="leagueStats")

  .block(v-if="included && false")
    h1 Uncategorized Info
    ol
      if org.clan
        li
          a(:href="'/league/' + org.clan") View AI League Team
        li
          span (summary AI League stats about CodePoints, # participants, top players, etc.)
      if org.nces && org.nces.schools && !isNaN(org.nces.schools)
        li
          span Total schools in #{org.kind}: #{formatNumber(org.nces.schools)}
        li TODO: show info for all active schools we have for this #{org.kind}, not just the number of schools that exist
      else if org.schools && org.schools.length > 1
        li
          span # of schools: #{formatNumber(org.schools.length)}
      if org.nces && org.nces.teachers && !isNaN(org.nces.teachers)
        li
          span Total teachers in #{org.kind}: #{formatNumber(org.nces.teachers)}
        li TODO: show info for all registered teachers we have for this #{org.kind}, not just the number of teachers that exist
      else if org.teachers && org.teachers.length > 1
        li
          span # of teachers: #{formatNumber(org.teachers.length)}
      if org.classrooms && !isNaN(org.classrooms)
        li
          span Total classrooms in #{org.kind}: #{formatNumber(org.classrooms)}
      else if org.classrooms && org.classrooms.length > 1
        li
          span # of classrooms: #{formatNumber(org.classrooms.length)}
      if org.nces && org.nces.students && !isNaN(org.nces.students)
        li
          span Total students in #{org.kind}: #{formatNumber(org.nces.students)}
        li TODO: show info for all registered students we have for this #{org.kind}, not just the number of students that exist
      else if org.students && org.students.length > 1
        li
          span # of students: #{formatNumber(org.students.length)}
      if org.licenses && ((org.licenses.usage && org.licenses.total) || org.licenses.hasAccessToShared)
        li
          span= licenses

</template>

<style lang="scss">
#page-outcomes-report .outcomes-report-result-component {
  $eve: #2d585a;
  $dawn: #532e48;
  $moon: #f7d047;
  $dusk: #5db9ac;
  $sun: #ff8600;

  @if $is-codecombat {
    $eve:  rgb(31, 87, 43);
    $dawn: rgb(14, 75, 96);
    $moon: rgb(242, 190, 24);
    $dusk: rgb(75, 96, 14);
    $sun: rgb(96, 14, 75);
  }

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
  label.edit-label {
    float: right;
  }
  .license {
    display: flex;

    h3 {
      flex-basis: 50%;
      font-family: 'Open Sans', sans-serif;
      font-weight: 600;
      font-size: 14pt;
    }

    span {
      flex-basis: 20%;
      text-align: right;
    }
  }
  .course {
    // TODO: tighten up styles so that most common case (1 course, multiple code languages) can fit on one page
    &.full-row {
      margin-bottom: 0.15in;
    }
    &.inline {
      width: 1.25in;
      height: 1.25in;
      display: inline-block;

      svg {
        filter: contrast(0.8);
      }
    }
    .bar {
      margin-bottom: 0.0in;
      break-inside: avoid;
      //border: 1px solid orange
      .concepts-list {
        max-width: 31%;
      }
    }
    .bar::after {
      clear: both;
      display: table;
      content: " ";
    }
    .el {
      margin-right: 0.25in;
      position: relative;
      svg {
        transform: rotate(-90deg);
      }
      circle.top {
        fill: transparent;
        stroke-width: 50;
        stroke: $dawn;

        // TODO: better colors
        &.top1 {
          stroke: $sun;
        }

        &.top2 {
          stroke: $dusk;
        }
      }
      circle.bottom {
        fill: $moon;
      }

      &.code-language-stat {
        .big {
          width: 1.7in;
        }

        .under {
          width: 1.7in;
        }
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

        img.code-language-icon {
          width: 0.49in;
          margin: 0 0.05in 0 -0.09in;
        }
      }
      @media print {
        .overlay-text {
          color: white !important;
          text-shadow: -1px -1px 0 black, 1px -1px 0 black, -1px 1px 0 black, 1px 1px 0 black !important;
        }
      }
      .overlay-text {
        color: white;
        position: absolute;
        width: 100%;
        left: 0;
        right: 0;
        text-align: center;
        font-family: 'Open Sans', sans-serif;
        text-shadow: -1px -1px 0 black, 1px -1px 0 black, -1px 1px 0 black, 1px 1px 0 black;
        $circleSize: 75pt;

        &.top-text, &.bot-text {
          font-size: 9pt;
          line-height: 9pt;
        }
        &.mid-text {
          font-size: 16pt;
          line-height: 16pt;
          /*top: calc($circleSize / 2 - 16pt / 2);*/
          top: 29.5pt;
        }
        &.top-text {
          /*top: calc($circleSize / 2 - 16pt / 2 - 9pt - 2pt);*/
          top: 18pt;
        }
        &.bot-text {
          /*bottom: calc($circleSize / 2 - 16pt / 2 - 9pt - 2pt);*/
          bottom: 18pt;
        }
      }

      li {
        line-height: 14pt;
        font-size: 12pt;
      }
      height: 75pt;
      float: left;
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
      margin-top: 0.25in;
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
      margin-top: 0.05in;
      margin-bottom: 0.15in;

      background-color: $eve;
      -webkit-print-color-adjust: exact !important;
      background: linear-gradient($eve, $eve) !important;

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
      break-inside: avoid;
      float: left;
      width: 4in;
      margin-right: 1in;
    }
    .right-col {
      break-inside: avoid;
      float: left;
      width: 2.5in;
      font-size: 14pt;
      line-height: 18pt;
      ul {
        padding-left: 2ex;
      }
    }
  }
  .dont-break {
    break-inside: avoid;
  }

  .dont-break::after {
    clear: both;
    content: ' ';
    display: table;
  }

  .dont-break.block.summary {
    padding-top: 0.25in;

    h1 {
      margin-top: 0.1in;
    }
  }

  .page-break {
    display: flex;
    align-items: center;
    page-break-before: always;

    hr {
      width: 100%;
    }

    @media screen {
      height: 1in;
    }

    @media print {
      height: 0.5in;

      hr {
        display: none
      }
    }
  }

  @media print {
    * {
      /* print-color-adjust: exact is needed for white text when overlaid on pie charts */
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
      transition: none !important;
    }
  }
}
</style>
