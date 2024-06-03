/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let TeacherStudentView
require('app/styles/teachers/teacher-student-view.sass')
const RootView = require('views/core/RootView')
const Classroom = require('models/Classroom')
const State = require('models/State')
const Courses = require('collections/Courses')
const Levels = require('collections/Levels')
const Prepaids = require('collections/Prepaids')
const LevelSessions = require('collections/LevelSessions')
const User = require('models/User')
const Users = require('collections/Users')
const CourseInstances = require('collections/CourseInstances')
require('d3/d3.js')
const utils = require('core/utils')
const aceUtils = require('core/aceUtils')
const AceDiff = require('ace-diff')
require('app/styles/teachers/ace-diff-teacher-student.sass')
const fullPageTemplate = require('app/templates/teachers/teacher-student-view-full')
const viewTemplate = require('app/templates/teachers/teacher-student-view')
const userClassroomHelper = require('../../lib/user-classroom-helper')

module.exports = (TeacherStudentView = (function () {
  TeacherStudentView = class TeacherStudentView extends RootView {
    static initClass () {
      this.prototype.id = 'teacher-student-view'

      this.prototype.events = {
        'change #course-dropdown': 'onChangeCourseChart',
        'change .course-select': 'onChangeCourseSelect',
        'click .progress-dot a': 'onClickProgressDot',
        'click .level-progress-dot': 'onClickStudentProgressDot',
        'click .nav-link': 'onClickSolutionTab'
      }
    }

    getMeta () { return { title: utils.isOzaria ? `${$.i18n.t('teacher.student_profile')} | ${$.i18n.t('common.ozaria')}` : this.user?.broadName() } }

    onClickSolutionTab (e) {
      let idTarget
      const link = $(e.target).closest('a')
      const levelSlug = link.data('level-slug')
      if (utils.isCodeCombat) {
        idTarget = link.attr('id').split('-')[0]
      }
      const solutionIndex = link.data('solution-index')
      if (utils.isCodeCombat) {
        let left, levelOriginal
        let lang = (left = this.classroom.get('aceConfig').language) != null ? left : 'python'
        if ([utils.courseIDs.WEB_DEVELOPMENT_1, utils.courseIDs.WEB_DEVELOPMENT_2].indexOf(this.selectedCourseId) !== -1) {
          lang = 'html'
        }
        if (/\+/.test(idTarget)) {
          levelOriginal = idTarget.split('+')[0]
          const codes = this.levelStudentCodeMap[levelOriginal]
          const code = this.levels.fingerprint(codes[solutionIndex].plan, lang)
          this.aceDiffs?.[levelOriginal].editors.left.ace.setValue(code, -1)
        } else {
          levelOriginal = link.attr('id').split('-')[0].slice(0, -1)
          const solutions = this.paidTeacher || utils.allFreeCourseIDs.includes(this.selectedCourseId) ? this.levelSolutionsMap[levelOriginal] : [{ source: $.i18n.t('teachers.not_allow_to_solution') }]
          this.aceDiffs?.[levelOriginal].editors.right.ace.setValue(solutions[solutionIndex].source, -1)
        }
      }
      window.tracker.trackEvent('Click Teacher Student Solution Tab', { levelSlug, solutionIndex })
    }

    constructor (options, classroomID, studentID) {
      super(...arguments)
      this.studentID = studentID
      this.state = new State({
        renderOnlyContent: options.renderOnlyContent
      })
      this.startTime = new Date()

      if (options.renderOnlyContent) {
        this.template = viewTemplate
      } else {
        this.template = fullPageTemplate
      }

      this.classroom = new Classroom({ _id: classroomID })
      this.listenToOnce(this.classroom, 'sync', this.onClassroomSync)
      this.supermodel.trackRequest(this.classroom.fetch())
      this.isCreativeLevelMap = {}

      this.prepaids = new Prepaids()
      this.paidTeacher = me.isAdmin() || me.isPaidTeacher()
      if (!me.isAdmin()) {
        this.supermodel.trackRequest(this.prepaids.fetchMineAndShared())
      }

      if (this.studentID) {
        this.user = new User({ _id: this.studentID })
        this.supermodel.trackRequest(this.user.fetch())
      }

      this.courses = new Courses()
      this.supermodel.trackRequest(this.courses.fetch({ data: { project: 'name,i18n,slug' } }))

      this.courseInstances = new CourseInstances()
      this.supermodel.trackRequest(this.courseInstances.fetchForClassroom(classroomID))

      // TODO: fetch only necessary thang data (i.e. levels with student progress, via separate API instead of complicated data.project values)
      this.levels = new Levels()
      this.supermodel.trackRequest(this.levels.fetchForClassroom(classroomID, { data: { project: 'name,original,i18n,primerLanguage,thangs.id,thangs.components.config.programmableMethods.plan.solutions,thangs.components.config.programmableMethods.plan.context,thangs.components.config.programmableMethods.plan.i18n' } }))
      this.urls = require('core/urls')

      // wrap templates so they translate when called
      const translateTemplateText = (template, context) => $('<div />').html(template(context)).i18n().html()
      this.singleStudentLevelProgressDotTemplate = _.wrap(require('app/templates/teachers/hovers/progress-dot-single-student-level'), translateTemplateText)
      this.levelProgressMap = {}
      me.getClientCreatorPermissions()?.then(() => this.render?.())
    }

    getRenderData () {
      const c = super.getRenderData(...arguments)
      c.isCreativeMode = l => this.isCreativeMode(l)
      return c
    }

    onLoaded () {
      let needle
      if (this.courses.loaded && (this.courses.length > 0) && !this.selectedCourseId) { this.selectedCourseId = this.courses.first().id }
      this.paidTeacher = this.paidTeacher || (this.prepaids.find(p => (needle = p.get('type'), ['course', 'starter_license'].includes(needle)) && (p.get('maxRedeemers') > 0)) != null)
      if (this.students.loaded && !this.destroyed) {
        this.user = _.find(this.students.models, s => s.id === this.studentID)
        if (utils.isOzaria) {
          this.setMeta({ title: `${$.i18n.t('teacher.student_profile')} | ${this.user.broadName()} | ${$.i18n.t('common.ozaria')}` })
        }
        this.updateLastPlayedInfo()
        this.updateLevelProgressMap()
        this.updateLevelDataMap()
        this.calculateStandardDev()
        this.updateSolutions()
        this.render()
      }

      super.onLoaded()
      // Navigate to anchor after loading complete, update selectedCourseId for progress dropdown
      if (window.location.hash) {
        const levelSlug = window.location.hash.substring(1)
        this.updateSelectedCourseProgress(levelSlug)
        return window.location.href = window.location.href
      }
    }

    destroy () {
      if (this.startTime) {
        const timeSpent = new Date() - this.startTime
        application.tracker?.trackTiming(timeSpent, 'Teachers Time Spent', 'Student Profile Page', me.id)
      }
      return super.destroy()
    }

    afterRender () {
      super.afterRender(...arguments)
      this.$('.progress-dot, .btn-view-project-level').each(function (i, el) {
        const dot = $(el)
        return dot.tooltip({
          html: true,
          container: dot
        }).delegate('.tooltip', 'mousemove', () => dot.tooltip('hide'))
      })

      this.$('.glyphicon-question-sign').each(function (i, el) {
        const dot = $(el)
        return dot.tooltip({
          html: true,
          container: dot
        }).delegate('.tooltip', 'mousemove', () => dot.tooltip('hide'))
      })

      this.drawBarGraph()
      this.onChangeCourseChart()

      for (const oldEditor of this.aceEditors != null ? this.aceEditors : []) { oldEditor.destroy() }
      this.aceEditors = []
      const {
        aceEditors
      } = this
      const classLang = this.classroom.get('aceConfig')?.language || 'python'
      this.$el.find('pre:has(code[class*="lang-"])').each(function () {
        let lang
        const codeElem = $(this).first().children().first()
        for (const mode in aceUtils.aceEditModes) { if (codeElem?.hasClass('lang-' + mode)) { lang = mode } }
        if (utils.isOzaria) {
          const aceEditor = aceUtils.initializeACE(this, lang || classLang)
          return aceEditors.push(aceEditor)
        }
      })
      if (utils.isCodeCombat) {
        const view = this
        this.aceDiffs = {}
        const showAceDiff = this.paidTeacher || utils.allFreeCourseIDs.includes(this.selectedCourseId)
        return this.$el.find('div[class*="ace-diff-"]').each(function () {
          const cls = $(this).attr('class')
          const levelOriginal = cls.split('-')[2]
          const solutions = showAceDiff ? view.levelSolutionsMap[levelOriginal] : [{ source: $.i18n.t('teachers.not_allow_to_solution') }]
          const studentCode = view.levelStudentCodeMap[levelOriginal]
          let lang = classLang
          if ([utils.courseIDs.WEB_DEVELOPMENT_1, utils.courseIDs.WEB_DEVELOPMENT_2].indexOf(view.selectedCourseId) !== -1) {
            lang = 'html'
          }
          view.aceDiffs[levelOriginal] = new AceDiff({
            element: '.' + cls,
            mode: 'ace/mode/' + classLang,
            theme: 'ace/theme/textmate',
            showDiffs: showAceDiff,
            showConnectors: showAceDiff,
            left: {
              content: view.levels.fingerprint(studentCode?.[0]?.plan != null ? studentCode?.[0]?.plan : '', lang),
              editable: false,
              copyLinkEnabled: false
            },
            right: {
              content: solutions?.[0]?.source != null ? solutions?.[0]?.source : '',
              editable: false,
              copyLinkEnabled: false
            }
          })
          return view.aceDiffs[levelOriginal]
        })
      }
    }

    updateSolutions () {
      if (!this.classroom?.loaded || !this.sessions?.loaded || !this.levels?.loaded) { return }
      this.levelSolutionsMap = this.levels.getSolutionsMap([this.classroom.get('aceConfig')?.language, 'html'])
      this.levelStudentCodeMap = {}
      this.capstoneGuidedCode = {}
      // I it's not clear why the value is _plan_ in Ozaria and {plan:_plan_,...} in CodeCombat
      if (utils.isOzaria) {
        return (() => {
          const result = []
          for (const session of this.sessions.models) {
          // Normal level
            if (session.get('creator') === this.studentID) {
              var name

              this.levelStudentCodeMap[session.get('level').original] = session.get('code')?.['hero-placeholder']?.plan
              // Arena level
              if (this.levelStudentCodeMap[name = session.get('level').original] == null) { this.levelStudentCodeMap[name] = session.get('code')?.['hero-placeholder-1']?.plan }
              // Capstone with saved code level
              if (session.get('code')?.['saved-capstone-normal-code']?.plan) {
                result.push(this.capstoneGuidedCode[session.get('level').original] = session.get('code')['saved-capstone-normal-code'].plan)
              } else {
                result.push(undefined)
              }
            }
          }
          return result
        })()
      } else { // CodeCombat
        return (() => {
          const result1 = []
          for (const session of this.sessions.models) {
            if (session.get('creator') === this.studentID) {
              const levelOriginal = session.get('level').original
              this.levelStudentCodeMap[levelOriginal] = this.levelStudentCodeMap[levelOriginal] || []
              // Normal level
              if (session.get('code')?.['hero-placeholder']?.plan) {
                this.levelStudentCodeMap[levelOriginal].push({
                  plan: session.get('code')['hero-placeholder'].plan,
                  team: 'humans'
                })
              }
              // Arena level
              if (session.get('code')?.['hero-placeholder-1']?.plan) {
                result1.push(this.levelStudentCodeMap[levelOriginal].push({
                  plan: session.get('code')['hero-placeholder-1'].plan,
                  team: 'ogres'
                }))
              } else {
                result1.push(undefined)
              }
            }
          }
          return result1
        })()
      }
    }

    isCreativeMode (levelOriginal) {
      return this.isCreativeLevelMap && this.isCreativeLevelMap[levelOriginal]
    }

    updateSelectedCourseProgress (levelSlug) {
      if (!levelSlug) { return }
      this.selectedCourseId = this.classroom.get('courses').find(c => c.levels.find(l => l.slug === levelSlug))?._id
      if (!this.selectedCourseId) { return }
      return this.render?.()
    }

    onClickProgressDot (e) {
      return this.updateSelectedCourseProgress(this.$(e.currentTarget).data('level-slug'))
    }

    onChangeCourseChart (e) {
      if (e) {
        const selected = ('#visualisation-' + ((e.currentTarget).value))
        $("[id|='visualisation']").hide()
        return $(selected).show()
      }
    }

    onChangeCourseSelect (e) {
      this.selectedCourseId = $(e.currentTarget).val()
      this.render?.()
      return window.tracker?.trackEvent('Change Teacher Student Code Review Course', { category: 'Teachers', classroomId: this.classroom.id, studentId: this.studentID, selectedCourseId: this.selectedCourseId })
    }

    onClickStudentProgressDot (e) {
      const levelSlug = $(e.currentTarget).data('level-slug')
      const levelProgress = $(e.currentTarget).data('level-progress')
      return window.tracker?.trackEvent('Click Teacher Student Code Review Progress Dot', { category: 'Teachers', classroomId: this.classroom.id, courseId: this.selectedCourseId, studentId: this.studentID, levelSlug, levelProgress })
    }

    questionMarkHtml (i18nBlurb) {
      return "<div style='text-align: left; width: 400px; font-family:Open Sans, sans-serif;'>" + $.i18n.t(i18nBlurb) + '</div>'
    }

    calculateStandardDev () {
      let session
      if (!this.courses.loaded || !this.levels.loaded || !this.sessions?.loaded || !this.levelData) { return }

      const levelSessionsByStudentByLevel = {}
      for (session of this.sessions.models) {
        const userSessions = levelSessionsByStudentByLevel[session.get('creator')] || {}
        const userSessionsForLevel = userSessions[session.get('level').original] || []
        userSessionsForLevel.push(session)
        userSessions[session.get('level').original] = userSessionsForLevel
        levelSessionsByStudentByLevel[session.get('creator')] = userSessions
      }
      const levelDataByLevel = {}
      for (const levelDatum of this.levelData) {
        levelDataByLevel[levelDatum.levelID] = levelDatum
      }
      this.courseComparisonMap = []
      return (() => {
        const result = []
        for (const versionedCourse of this.classroom.getSortedCourses() || []) {
          const course = this.courses.get(versionedCourse._id)
          const numbers = []
          const performanceNumbers = []
          let studentCourseTotal = 0
          let performanceStudentCourseTotal = 0
          let members = 0 // this is the COUNT for our standard deviation, number of members who have played all of the levels this student has played.
          for (const member of this.classroom.get('members')) {
            let number = 0
            let performanceNumber = 0
            let memberPlayed = 0 // number of levels a member has played that this student has also played
            for (const versionedLevel of versionedCourse.levels) {
              var left
              const sessions = (left = (levelSessionsByStudentByLevel[member] != null ? levelSessionsByStudentByLevel[member] : {})[versionedLevel.original]) != null ? left : []
              for (session of sessions) {
                const playedLevel = levelDataByLevel[session.get('level').original]
                if ((playedLevel.levelProgress === 'complete') || (playedLevel.levelProgress === 'started')) {
                  number += session.get('playtime') || 0
                  performanceNumber += (!playedLevel.isLadder && !playedLevel.isProject && session.get('playtime')) || 0
                  memberPlayed += 1
                }
                if (session.get('creator') === this.studentID) {
                  studentCourseTotal += session.get('playtime') || 0
                  performanceStudentCourseTotal += (!playedLevel.isLadder && !playedLevel.isProject && session.get('playtime')) || 0
                }
              }
            }
            if (memberPlayed > 0) { members += 1 }
            numbers.push(number)
            performanceNumbers.push(performanceNumber)
          }

          // add all numbers[]
          const sum = numbers.reduce((a, b) => a + b)
          const performanceSum = performanceNumbers.reduce((a, b) => a + b)

          // divide by members to get MEAN, remember MEAN is only an average of the members' performance on levels THIS student has done.
          var mean = sum / members
          var performanceMean = performanceSum / members

          // # for each number in numbers[], subtract MEAN then SQUARE, add all, then divide by COUNT to get VARIANCE
          const diffSum = numbers.map(num => Math.pow((num - mean), 2)).reduce((a, b) => a + b)
          const performanceDiffSum = performanceNumbers.map(num => Math.pow((num - performanceMean), 2)).reduce((a, b) => a + b)
          const variance = (diffSum / members)
          const performanceVariance = (performanceDiffSum / members)

          // square root of VARIANCE is standardDev
          const StandardDev = Math.sqrt(variance)
          const PerformanceStandardDev = Math.sqrt(performanceVariance)

          let perf = utils.isCodeCombat ? -(performanceStudentCourseTotal - performanceMean) / PerformanceStandardDev : -(studentCourseTotal - mean) / StandardDev
          perf = perf > 0 ? Math.ceil(perf) : Math.floor(perf)

          result.push(this.courseComparisonMap.push({
            courseModel: course,
            courseID: course.get('_id'),
            studentCourseTotal,
            standardDev: StandardDev,
            mean,
            performance: perf
          }))
        }
        return result
      })()
    }

    // console.log (@courseComparisonMap)

    drawBarGraph () {
      if (!this.courses.loaded || !this.levels.loaded || !this.sessions?.loaded || !this.levelData || !this.courseComparisonMap) { return }

      const WIDTH = 1142
      const HEIGHT = 600
      const MARGINS = {
        top: 50,
        right: 20,
        bottom: 50,
        left: 70
      }

      return (() => {
        const result = []
        for (const versionedCourse of this.classroom.getSortedCourses() || []) {
        // this does all of the courses, logic for whether student was assigned is in corresponding jade file
          const vis = d3.select('#visualisation-' + versionedCourse._id)
          // TODO: continue if selector isn't found.
          const courseLevelData = []
          for (const level of this.levelData) {
            if (level.courseID === versionedCourse._id) {
              if (level.assessment) {
                continue
              }
              courseLevelData.push(level)
            }
          }

          const course = this.courses.get(versionedCourse._id)
          const levels = this.classroom.getLevels({ courseID: course.id }).models

          var xRange = d3.scale.ordinal().rangeRoundBands([MARGINS.left, WIDTH - MARGINS.right], 0.1).domain(courseLevelData.map(d => d.levelIndex))
          var yRange = d3.scale.linear().range([HEIGHT - (MARGINS.top), MARGINS.bottom]).domain([0, d3.max(courseLevelData, function (d) { if (d.classAvg > d.studentTime) { return d.classAvg } else { return d.studentTime } })])
          const xAxis = d3.svg.axis().scale(xRange).tickSize(1).tickSubdivide(true)
          const yAxis = d3.svg.axis().scale(yRange).tickSize(1).orient('left').tickSubdivide(true)

          vis.append('svg:g').attr('class', 'x axis').attr('transform', 'translate(0,' + (HEIGHT - (MARGINS.bottom)) + ')').call(xAxis)
          vis.append('svg:g').attr('class', 'y axis').attr('transform', 'translate(' + MARGINS.left + ',0)').call(yAxis)

          const chart = vis.selectAll('rect')
            .data(courseLevelData)
            .enter()
          // draw classroom average bars
          chart.append('rect')
            .attr('class', 'classroom-bar')
            .attr('x', d => xRange(d.levelIndex) + ((xRange.rangeBand()) / 2))
            .attr('y', d => yRange(d.classAvg))
            .attr('width', (xRange.rangeBand()) / 2)
            .attr('height', d => HEIGHT - (MARGINS.bottom) - yRange(d.classAvg))
            .attr('fill', '#5CB4D0')
          // add classroom average values
          chart.append('text')
            .attr('x', d => xRange(d.levelIndex) + ((xRange.rangeBand()) / 2))
            .attr('y', d => yRange(d.classAvg) - 3)
            .text(function (d) { if ((d.classAvg !== 0) && (d.classAvg !== d.studentTime)) { return d.classAvg } })
            .attr('class', 'label')
          // draw student playtime bars
          chart.append('rect')
            .attr('class', 'student-bar')
            .attr('x', d => xRange(d.levelIndex))
            .attr('y', d => yRange(d.studentTime))
            .attr('width', (xRange.rangeBand()) / 2)
            .attr('height', d => HEIGHT - (MARGINS.bottom) - yRange(d.studentTime))
            .attr('fill', function (d) { if (d.levelProgress === 'complete') { return '#20572B' } else { return '#F2BE19' } })
          // add student playtime value
          chart.append('text')
            .attr('x', d => xRange(d.levelIndex))
            .attr('y', d => yRange(d.studentTime) - 3)
            .text(function (d) { if (d.studentTime !== 0) { return d.studentTime } })
            .attr('class', 'label')

          const labels = vis.append('g').attr('class', 'labels')
          // add Playtime axis label
          labels.append('text')
            .attr('transform', 'rotate(-90)')
            .attr('y', 20)
            .attr('x', -HEIGHT / 2)
            .attr('dy', '.71em')
            .style('text-anchor', 'middle')
            .text($.i18n.t('teacher.playtime_axis'))
          // add levels axis label
          result.push(labels.append('text')
            .attr('x', WIDTH / 2)
            .attr('y', HEIGHT - 10)
            .text($.i18n.t('teacher.levels_axis') + ' ' + course.getTranslatedName())
            .style('text-anchor', 'middle'))
        }
        return result
      })()
    }

    onClassroomSync () {
      // Now that we have the classroom from db, can request all level sessions for this classroom
      this.sessions = new LevelSessions()
      this.sessions.comparator = 'changed' // Sort level sessions by changed field, ascending
      this.listenTo(this.sessions, 'sync', this.onSessionsSync)
      this.supermodel.trackRequests(this.sessions.fetchForAllClassroomMembers(this.classroom))

      this.students = new Users()
      const jqxhrs = this.students.fetchForClassroom(this.classroom, { removeDeleted: true })
      // @listenTo @students, ->
      this.supermodel.trackRequests(jqxhrs)
      this.isTeacherOfClass = userClassroomHelper.isTeacherOf({ user: me, classroom: this.classroom })
    }

    onSessionsSync () {
      // Now we have some level sessions, and enough data to calculate last played string
      // This may be called multiple times due to paged server API calls via fetchForAllClassroomMembers
      if (this.destroyed) { return } // Don't do anything if page was destroyed after db request
      this.updateLastPlayedInfo()
      this.updateLevelProgressMap()
      this.updateLevelDataMap()
      return this.updateSolutions()
    }

    updateLastPlayedInfo () {
      // Make sure all our data is loaded, @sessions may not even be intialized yet
      let course, level
      if (!this.courses.loaded || !this.levels.loaded || !this.sessions?.loaded || !this.user?.loaded) { return }

      // Use lodash to find the last session for our user, @sessions already sorted by changed date
      const session = _.findLast(this.sessions.models, s => s.get('creator') === this.user.id)

      if (!session) { return }

      // Find course for this level session, for it's name
      // Level.original is the original id, used for level versioning, and connects levels to level sessions
      for (const versionedCourse of this.classroom.getSortedCourses() || []) {
        for (level of versionedCourse.levels) {
          if (level.original === session.get('level').original) {
            // Found the level for our level session in the classroom versioned courses
            // Find the full course so we can get it's name
            course = this.courses.get(versionedCourse._id)
            break
          }
        }
      }

      // Find level for this level session, for it's name
      level = this.levels.findWhere({ original: session.get('level').original })
      if (utils.isOzaria) {
        this.levels.forEach(level => {
          if (level.get('creativeMode')) {
            this.isCreativeLevelMap[level.get('original')] = true
          }
        })
      }

      // extra vars for display
      this.lastPlayedCourse = course
      this.lastPlayedLevel = level
      return this.lastPlayedSession = session
    }

    lastPlayedString () {
      // Update last played string based on what we found
      let lastPlayedString = ''
      if (this.lastPlayedCourse) { lastPlayedString += this.lastPlayedCourse.getTranslatedName() }
      if (this.lastPlayedCourse && this.lastPlayedLevel) { lastPlayedString += ': ' }
      if (this.lastPlayedLevel) { lastPlayedString += this.lastPlayedLevel.getTranslatedName() }
      if (this.lastPlayedCourse || this.lastPlayedLevel) {
        if (me.get('preferredLanguage', true) === 'en-US') {
          lastPlayedString += ', on '
        } else {
          lastPlayedString += ', '
        }
      }
      if (this.lastPlayedSession) { lastPlayedString += moment(this.lastPlayedSession.get('changed')).format('LLLL') }
      return lastPlayedString
    }

    updateLevelProgressMap () {
      let session
      if (!this.courses.loaded || !this.levels.loaded || !this.sessions?.loaded || !this.user?.loaded) { return }

      // Map levels to sessions once, so we don't have to search entire session list multiple times below
      this.levelSessionMap = {}
      for (session of this.sessions.models) {
        if (session.get('creator') === this.studentID) {
          this.levelSessionMap[session.get('level').original] = session
        }
      }

      // Create mapping of level to student progress
      this.levelProgressMap = {}
      this.levelProgressTimeMap = {}
      return (this.classroom.getSortedCourses() || []).map((versionedCourse) =>
        (() => {
          const result = []
          for (const versionedLevel of versionedCourse.levels) {
            session = this.levelSessionMap[versionedLevel.original]
            if (session?.get('creator') === this.studentID) {
              this.levelProgressTimeMap[versionedLevel.original] = { changed: moment(session.get('changed')) }
              if (session.get('state')?.complete) {
                this.levelProgressMap[versionedLevel.original] = 'complete'
                result.push(this.levelProgressTimeMap[versionedLevel.original].dateFirstCompleted = moment(session.get('dateFirstCompleted'))) // enable this line if needed
              } else {
                result.push(this.levelProgressMap[versionedLevel.original] = 'started')
              }
            } else {
              result.push(this.levelProgressMap[versionedLevel.original] = 'not started')
            }
          }
          return result
        })())
    }

    updateLevelDataMap () {
      if (!this.courses.loaded || !this.levels.loaded || !this.sessions?.loaded) { return }

      this.levelData = []
      return (() => {
        const result = []
        for (var versionedCourse of this.classroom.getSortedCourses() || []) {
          var course = this.courses.get(versionedCourse._id)
          var ladderLevel = this.classroom.getLadderLevel(course.get('_id'))
          var projectLevel = this.classroom.getProjectLevel(course.get('_id'))
          result.push((() => {
            const result1 = []
            for (const versionedLevel of versionedCourse.levels) {
              let playTime = 0 // TODO: this and timesPlayed should probably only count when the levels are completed
              let timesPlayed = 0
              let studentTime = 0
              let levelProgress = 'not started'
              for (const session of this.sessions.models) {
                if (session.get('level').original === versionedLevel.original) {
                  // if @levelProgressMap[versionedLevel.original] == 'complete' # ideally, don't log sessions that aren't completed in the class
                  playTime += session.get('playtime') || 0
                  timesPlayed += 1
                  if (session.get('creator') === this.studentID) {
                    studentTime = session.get('playtime') || 0
                    if (this.levelProgressMap[versionedLevel.original] === 'complete') {
                      levelProgress = 'complete'
                    } else if (this.levelProgressMap[versionedLevel.original] === 'started') {
                      levelProgress = 'started'
                    }
                  }
                }
              }
              const classAvg = timesPlayed > 0 ? Math.round(playTime / timesPlayed) : 0 // only when someone other than the user has played
              // console.log (timesPlayed)
              result1.push(this.levelData.push({
                assessment: versionedLevel.assessment,
                levelID: versionedLevel.original,
                levelIndex: this.classroom.getLevelNumber(versionedLevel.original, -1, course.get('_id')),
                levelName: versionedLevel.name,
                courseModel: course,
                courseID: course.get('_id'),
                classAvg,
                studentTime: studentTime || 0,
                levelProgress,
                isLadder: ladderLevel?.attributes.original === versionedLevel.original,
                isProject: projectLevel?.attributes.original === versionedLevel.original
                // required:
              }))
            }
            return result1
          })())
        }
        return result
      })()
    }

    studentStatusString () {
      const status = this.user.prepaidStatus()
      if (!this.user.get('coursePrepaid')) { return '' }
      const expires = this.user.get('coursePrepaid')?.endDate
      const date = (expires != null) ? moment(expires).utc().format('l') : ''
      return utils.formatStudentLicenseStatusDate(status, date)
    }

    canViewStudentProfile () { return this.classroom && ((this.classroom.get('ownerID') === me.id) || me.isAdmin()) }
  }
  TeacherStudentView.initClass()
  return TeacherStudentView
})())

// TODO: Hookup enroll/assign functionality

// onClickEnrollStudentButton: (e) ->
//   userID = $(e.currentTarget).data('user-id')
//   user = @user.get(userID)
//   selectedUsers = new Users([user])
//   @enrollStudents(selectedUsers)
//   window.tracker?.trackEvent $(e.currentTarget).data('event-action'), category: 'Teachers', classroomID: @classroom.id, userID: userID
//
// enrollStudents: (selectedUsers) ->
//   modal = new ActivateLicensesModal { @classroom, selectedUsers, users: @user }
//   @openModalView(modal)
//   modal.once 'redeem-users', (enrolledUsers) =>
//     enrolledUsers.each (newUser) =>
//       user = @user.get(newUser.id)
//       if user
//         user.set(newUser.attributes)
//     null

// levelPopoverContent: (level, session, i) ->
//   return null unless level
//   context = {
//     moment: moment
//     level: level
//     session: session
//     i: i
//     canViewSolution: @teacherMode
//   }
//   return popoverTemplate(context)
//
// getLevelURL: (level, course, courseInstance, session) ->
//   return null unless @teacherMode and _.all(arguments)
//   "/play/level/#{level.get('slug')}?course=#{course.id}&course-instance=#{courseInstance.id}&session=#{session.id}&observing=true"
