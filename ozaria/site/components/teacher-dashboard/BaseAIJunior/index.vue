
<script>
import { mapGetters, mapActions, mapMutations } from 'vuex'
import { COMPONENT_NAMES } from '../common/constants.js'
import utils from 'core/utils'
import PieChart from 'core/components/PieComponent'

const Courses = require('collections/Courses')
const Levels = require('collections/Levels')
const QRCode = require('qrcode')

require('app/styles/courses/teacher-class-view.sass')

const projectionData = {
  levelSessions: 'state.complete,state.goalStates,level,creator,changed,created,dateFirstCompleted,submitted,codeConcepts,code,codeLanguage'
}

export default {
  name: COMPONENT_NAMES.AI_JUNIOR,
  components: {
    'pie-chart': PieChart
  },
  props: {
    classroomId: {
      type: String,
      default: '',
      required: true
    },
    teacherId: { // sent from DSA
      type: String,
      default: ''
    }
  },
  data () {
    return {
      propsData: null
    }
  },
  computed: {
    ...mapGetters({
      classroom: 'teacherDashboard/getCurrentClassroom',
      classroomCourses: 'teacherDashboard/getCoursesCurrentClassroom',
      selectedCourseId: 'teacherDashboard/getSelectedCourseIdCurrentClassroom',
      levelSessionsMapByUser: 'teacherDashboard/getLevelSessionsMapCurrentClassroom',
      classroomMembers: 'teacherDashboard/getMembersCurrentClassroom',
      gameContent: 'teacherDashboard/getGameContentCurrentClassroom',
      getClassroomById: 'classrooms/getClassroomById',
      getActiveClassrooms: 'teacherDashboard/getActiveClassrooms',
      getCourseInstancesOfClass: 'courseInstances/getCourseInstancesOfClass',
      getInteractiveSessionsForClass: 'interactives/getInteractiveSessionsForClass',
      getSessionsForClassroom: 'levelSessions/getSessionsForClassroom',
      loading: 'teacherDashboard/getLoadingState',
      getLevelsForClassroom: 'levels/getLevelsForClassroom'
    }),
    selectedCourse () {
      return this.classroomCourses.find((c) => c._id === this.selectedCourseId) || {}
    },
    capstoneLevel () {
      return (this.gameContent[this.selectedCourseId] || {}).capstone || {}
    },
    utils () {
      return utils
    },
    exemplarProjectUrl () {
      return this.capstoneLevel.exemplarProjectUrl || ''
    },
    exemplarCodeUrl () {
      return this.capstoneLevel.exemplarCodeUrl || ''
    },
    projectRubricUrl () {
      return this.capstoneLevel.projectRubricUrl || ''
    }
  },

  watch: {
    async classroomId (newId) {
      this.setClassroomId(newId)
      await this.fetchClassroomData(newId)
    },
    async selectedCourseId (newId, oldId) {
      if (newId !== oldId) {
        await this.fetchClassroomData(this.classroomId)
      }
    }
  },

  async mounted () {
    this.setTeacherId(this.teacherId || me.get('_id'))
    this.setClassroomId(this.classroomId)
    await this.fetchClassroomData(this.classroomId)
    const areTeacherClassesFetched = this.getActiveClassrooms.length !== 0
    if (!areTeacherClassesFetched) {
      // to show list of classes in student projects tab
      await this.fetchClassroomsForTeacher({ teacherId: me.get('_id') })
    }
    this.startCamera()
    this.generateQRCode()
  },

  destroyed () {
    this.resetLoadingState()
  },

  methods: {
    ...mapActions({
      fetchData: 'teacherDashboard/fetchData',
      fetchClassroomById: 'classrooms/fetchClassroomForId',
      fetchClassroomsForTeacher: 'classrooms/fetchClassroomsForTeacher'
    }),
    ...mapMutations({
      resetLoadingState: 'teacherDashboard/resetLoadingState',
      setTeacherId: 'teacherDashboard/setTeacherId',
      setClassroomId: 'teacherDashboard/setClassroomId',
      setSelectedCourseId: 'teacherDashboard/setSelectedCourseIdCurrentClassroom'
    }),

    generateQRCode () {
      const canvas = document.getElementById('qr-code-canvas')
      QRCode.toCanvas(canvas, me.broadName(), { errorCorrectionLevel: 'H' }, function (error) {
        if (error) console.error(error)
      })
    },

    async startCamera () {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({ video: true })
        document.querySelector('video').srcObject = stream
        this.scanCode(stream) // Call your scanning function here
      } catch (error) {
        console.error('Error accessing the camera', error)
      }
    },

    scanCode (stream) {
      // Initialize your QR/barcode scanning library here
      // Use the stream or the video element as its input source
      // On detection:
      _.delay(() => this.captureImage(), 1000)
    },

    captureImage () {
      const video = document.querySelector('video')
      const canvas = document.createElement('canvas')
      canvas.width = video.videoWidth
      canvas.height = video.videoHeight
      const ctx = canvas.getContext('2d')
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
      const imageData = canvas.toDataURL('image/png')
      this.sendToServer(imageData)
    },

    sendToServer (imageData) {
      // Use Fetch API or XMLHttpRequest to send imageData to your server
      console.log(imageData)
    },

    async getCourseAssessmentPairs (courses, classroom) {
      const levels = new Levels(this.getLevelsForClassroom(this.classroomId))
      // await levels.fetchForClassroom(this.classroomId, { data: { project: 'original,name,primaryConcepts,concepts,primerLanguage,practice,shareable,i18n,assessment,assessmentPlacement,slug,goals' } })
      const courseAssessmentPairs = []
      const coursesStub = new Courses(courses)
      for (const course of coursesStub.models) {
        const assessmentLevels = classroom.getLevels({ courseID: course.id, assessmentLevels: true }).models
        const assessmentLevelOriginals = assessmentLevels.map(l2 => l2.get('original'))
        const fullLevels = levels.models.filter(l => assessmentLevelOriginals.includes(l.get('original')))
        courseAssessmentPairs.push([course, fullLevels])
      }
      return courseAssessmentPairs
    },

    async fetchClassroomData (classroomId) {
      this.propsData = null

      if (!this.getClassroomById(classroomId)) {
        await this.fetchClassroomById(classroomId)
      }
      await this.fetchData({ componentName: this.$options.name, options: { data: projectionData, loadedEventName: 'Student AIJunior: Loaded' } })
    }
  }
}
</script>

<template>
  <div id="teacher-class-view">
    <div class="container">
      <h4 class="m-b-2 m-t-3">
        {{ $t('teacher.progress_color_key') }}
      </h4>
      <div
        id="progress-color-key-row"
        class="row m-b-3"
      >
        <div class="col col-md-2 col-xs-3">
          <div class="progress-dot forest" />
          <div class="key-text">
            <span class="small">{{ $t('teacher.success') }}</span>
          </div>
          <div class="clearfix" />
        </div>
        <div class="col col-md-2 col-xs-3">
          <div class="progress-dot gold" />
          <div class="key-text">
            <span class="small">{{ $t('teacher.in_progress') }}</span>
          </div>
          <div class="clearfix" />
        </div>
        <div class="col col-md-2 col-xs-3">
          <div class="progress-dot" />
          <div class="key-text">
            <span class="small">{{ $t('teacher.not_started') }}</span>
          </div>
          <div class="clearfix" />
        </div>
        <div class="col col-md-2 col-xs-3">
          <pie-chart
            :percent="100 * 2 / 3"
            :stroke-width="10"
            color="#20572B"
            :opacity="1"
          />
          <div class="key-text">
            <span
              class="small"
              data-i18n="TODO"
            >Partially Complete</span>
          </div>
          <div class="clearfix" />
        </div>
      </div>
      <div>
        <video
          id="camera-stream"
          autoplay
          playsinline
          muted
        />
        <button
          class="dusk-btn"
          @click="startCamera()"
        >
          Capture
        </button>
        <canvas id="qr-code-canvas" />
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
#camera-stream {
  max-width: 100%;
  height: auto;
  min-height: 320px;
  outline: 1px solid black;
}

#qr-code-canvas {
  width: 300px;
  height: 300px;
  outline: 1px solid black;
}

.capstone-container {
  display: flex;
  flex-direction: row;
  align-items: flex-start;
  justify-content: center;
  padding: 0px 30px;
}

.capstone-details {
  width: 30%;
  margin-right: 60px;
}

.capstone-sessions {
  width: 70%;
}
</style>
