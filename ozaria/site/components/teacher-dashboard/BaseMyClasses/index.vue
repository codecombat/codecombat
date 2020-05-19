<script>
  import { mapGetters, mapActions, mapMutations } from 'vuex'
  import { COMPONENT_NAMES } from '../common/constants.js'
  import SecondaryTeacherNavigation from '../common/SecondaryTeacherNavigation'
  import TitleBar from '../common/TitleBar'
  import LoadingBar from '../common/LoadingBar'
  import ClassComponent from './ClassComponent'

  function getRandomIntInclusive (min, max) {
    min = Math.ceil(min)
    max = Math.floor(max)
    return Math.floor(Math.random() * (max - min + 1)) + min
  }

  const generateChapterStats = (idx) => {
    const chapterStats = {
      name: `Chapter ${idx}`,
      assigned: [true][Math.floor(Math.random() * 4)],
      progress: getRandomIntInclusive(0, 5) / 5
    }
    if (!chapterStats.assigned) {
      chapterStats.progress = 0
    }
    return chapterStats
  }

  const generateClassStats = (name) => ({
    name,
    chapters: Array.from(new Array(12)).map((_, idx) => generateChapterStats(idx)),
    language: ['javascript', 'python'][Math.floor(Math.random() * 2)],
    numberOfStudents: getRandomIntInclusive(10, 20),
    classroomCreated: moment(getRandomIntInclusive(new Date(2018, 0, 0).getTime(), Date.now())).format('MMMM Do, YYYY')
  })

  export default {
    name: COMPONENT_NAMES.MY_CLASSES_ALL,
    components: {
      'secondary-teacher-navigation': SecondaryTeacherNavigation,
      'title-bar': TitleBar,
      'loading-bar': LoadingBar,
      ClassComponent
    },
    data: () => ({
      classes: [
        generateClassStats('intro to cs'),
        generateClassStats('TECH 101'),
        generateClassStats('Class 3'),
        generateClassStats('More classes 502'),
        generateClassStats('Tech class 404')
      ]
    }),
    computed: {
      ...mapGetters({
        loading: 'teacherDashboard/getLoadingState',
        classroomsByTeacher: 'classrooms/getClassroomsByTeacher'
      }),
      teacherId () {
        return me.get('_id')
      },
      activeClassrooms () {
        return (this.classroomsByTeacher(this.teacherId) || {}).active
      }
    },

    mounted () {
      this.setTeacherId(me.get('_id'))
      this.fetchData({ componentName: this.$options.name })
    },

    destroyed () {
      this.resetLoadingState()
    },

    methods: {
      ...mapActions({
        fetchData: 'teacherDashboard/fetchData'
      }),
      ...mapMutations({
        resetLoadingState: 'teacherDashboard/resetLoadingState',
        setTeacherId: 'teacherDashboard/setTeacherId'
      })
    }
  }
</script>

<template>
  <div>
    <secondary-teacher-navigation
      :classrooms="activeClassrooms"
    />
    <title-bar title="All classes" />
    <loading-bar
      :key="loading"
      :loading="loading"
    />

    <class-component
      v-for="clas in classes"
      :key="clas.name"
      :classroom="clas"
    />
  </div>
</template>
