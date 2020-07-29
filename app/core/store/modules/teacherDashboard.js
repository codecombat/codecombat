
import { COMPONENT_NAMES } from 'ozaria/site/components/teacher-dashboard/common/constants.js'

export default {
  namespaced: true,

  state: {
    teacherId: '',
    classroomId: '', // current classrom id for single class page and projects page
    selectedCourseIdForClassroom: {}, // selectedCourse for each classroomId across single class and student projects page
    loading: false
  },

  mutations: {
    setTeacherId (state, teacherId) {
      if (state.teacherId !== teacherId) {
        state.teacherId = teacherId
      }
    },
    setClassroomId (state, classroomId) {
      if (state.classroomId !== classroomId) {
        state.classroomId = classroomId
      }
    },
    startLoading (state) {
      state.loading = true
    },
    stopLoading (state) {
      state.loading = false
    },
    resetLoadingState (state) {
      state.loading = false
    },
    setSelectedCourseIdCurrentClassroom (state, { courseId }) {
      if (state.classroomId) {
        Vue.set(state.selectedCourseIdForClassroom, state.classroomId, courseId)
      }
    }
  },

  getters: {
    teacherId (state) {
      return state.teacherId
    },
    classroomId (state) {
      return state.classroomId
    },
    classroom (state, getters) {
      return getters.getActiveClassrooms.find((c) => c._id === state.classroomId) || {}
    },
    getLoadingState (state) {
      return state.loading
    },
    getActiveClassrooms (state, _getters, _rootState, rootGetters) {
      if (state.teacherId) {
        return rootGetters['classrooms/getActiveClassroomsByTeacher'](state.teacherId) || []
      } else {
        return []
      }
    },
    getArchivedClassrooms (state, _getters, _rootState, rootGetters) {
      if (state.teacherId) {
        return rootGetters['classrooms/getArchivedClassroomsByTeacher'](state.teacherId) || []
      } else {
        return []
      }
    },
    getCurrentClassroom (state, _getters, _rootState, rootGetters) {
      if (state.teacherId && state.classroomId) {
        const classrooms = rootGetters['classrooms/getActiveClassroomsByTeacher'](state.teacherId) || []
        return classrooms.find((c) => c._id === state.classroomId) || {}
      } else {
        return {}
      }
    },
    getCoursesCurrentClassroom (state, getters, _rootState, rootGetters) {
      if (state.classroomId) {
        const classroom = getters['getCurrentClassroom']
        const classroomCourseIds = (classroom.courses || []).map((c) => c._id) || []
        const courses = rootGetters['courses/sorted'] || []
        return courses.filter((c) => classroomCourseIds.includes(c._id))
      }
      return []
    },
    getSelectedCourseIdCurrentClassroom (state, getters) {
      if (state.classroomId && state.selectedCourseIdForClassroom[state.classroomId]) {
        return state.selectedCourseIdForClassroom[state.classroomId]
      } else { // TODO default should be last assigned course
        const classroomCourses = getters['getCoursesCurrentClassroom'] || []
        if (classroomCourses.length > 0) {
          return (classroomCourses[0] || {})._id
        }
      }
    },
    getMembersCurrentClassroom (state, getters, _rootState, rootGetters) {
      if (state.classroomId) {
        const classroom = getters['getCurrentClassroom']
        return rootGetters['users/getClassroomMembers'](classroom) || []
      }
      return []
    },
    getLevelSessionsMapCurrentClassroom (state, _getters, _rootState, rootGetters) {
      if (state.classroomId) {
        return rootGetters['levelSessions/getSessionsMapForClassroom'](state.classroomId) || {}
      }
      return {}
    },
    getGameContentCurrentClassroom (state, _getters, _rootState, rootGetters) {
      if (state.classroomId) {
        return rootGetters['gameContent/getContentForClassroom'](state.classroomId) || {}
      }
      return {}
    },
    getActiveLicenses (state, _getters, _rootState, rootGetters) {
      if (state) {
        return rootGetters['prepaids/getActiveLicensesForTeacher'](state.teacherId) || []
      } else {
        return []
      }
    },
    getExpiredLicenses (state, _getters, _rootState, rootGetters) {
      if (state.teacherId) {
        return rootGetters['prepaids/getExpiredLicensesForTeacher'](state.teacherId) || []
      } else {
        return []
      }
    }
  },

  actions: {
    // componentName = name of the vue component -> used to fetch relevant data for the respective page
    // options = { data: {} }
    // options.data = {} -> contains specific properties to fetch (or `project`) for an object as a string, eg: {users: 'firstName,lastName,email', levelSessions: 'state.complete,level,creator,changed'}
    async fetchData ({ state, dispatch, commit }, { componentName, options = {} }) {
      if (!state.teacherId) {
        console.error('Error in fetching data: teacherId is not set')
        noty({ text: 'Error in fetching data', type: 'error', layout: 'center', timeout: 2000 })
        return
      }

      commit('startLoading')
      try {
        if (componentName === COMPONENT_NAMES.MY_CLASSES_ALL) {
          // My classes page
          await dispatch('fetchDataAllClasses', options)
          dispatch('fetchDataAllClassesAsync', options) // does not block loading indicator
        } else if (componentName === COMPONENT_NAMES.MY_CLASSES_SINGLE) {
          // Single class progress page
          await dispatch('fetchDataSingleClass', options)
          dispatch('fetchDataSingleClassAsync', options) // does not block loading indicator
        } else if (componentName === COMPONENT_NAMES.STUDENT_PROJECTS) {
          // Students progress page
          await dispatch('fetchDataStudentProjects', options)
          dispatch('fetchDataStudentProjectsAsync', options) // does not block loading indicator
        } else if (componentName === COMPONENT_NAMES.MY_LICENSES) {
          // Teacher licenses page
          await dispatch('fetchDataMyLicenses', options)
          dispatch('fetchDataMyLicensesAsync', options) // does not block loading indicator
        } else if (componentName === COMPONENT_NAMES.RESOURCE_HUB) {
          // Resource Hub page
          dispatch('fetchDataResourceHubAsync', options) // does not block loading indicator
        }
      } catch (err) {
        console.error('Error in fetching data:', err)
        noty({ text: 'Error in fetching data', type: 'error', layout: 'topCenter', timeout: 2000 })
      } finally {
        commit('stopLoading')
        if (options.loadedEventName) { // should be set for tracking the loaded event for dashboard pages
          window.tracker?.trackEvent(options.loadedEventName, { category: 'Teachers' })
        }
      }
    },

    // My classes page
    // options.data = { levelSessions: '' } -> properties needed for these objects, i.e. will be used as `project` in db queries
    async fetchDataAllClasses ({ state, dispatch, rootGetters }, options = {}) {
      const fetchPromises = []

      fetchPromises.push(dispatch('courseInstances/fetchCourseInstancesForTeacher', state.teacherId, { root: true }))
      fetchPromises.push(dispatch('courses/fetchReleased', undefined, { root: true }))
      fetchPromises.push(dispatch('classrooms/fetchClassroomsForTeacher', state.teacherId, { root: true }))

      await Promise.all(fetchPromises)
    },

    // My classes page - without blocking loading indicator
    async fetchDataAllClassesAsync ({ state, dispatch, rootGetters }, options = {}) {
      const fetchPromises = []

      const classrooms = rootGetters['classrooms/getClassroomsByTeacher'](state.teacherId)
      if (((classrooms || {}).active || []).length > 0) {
        classrooms.active.forEach((classroom) => {
          const levelSessionOptions = {
            project: (options.data || {}).levelSessions
          }
          fetchPromises.push(dispatch('levelSessions/fetchForClassroomMembers', { classroom, options: levelSessionOptions }, { root: true }))
        })
      }

      fetchPromises.push(dispatch('prepaids/fetchPrepaidsForTeacher', state.teacherId, { root: true }))
      fetchPromises.push(dispatch('teacherDashboard/fetchDataCurriculumGuide', undefined, { root: true }))

      await Promise.all(fetchPromises)
    },

    // Single class progress page
    // options.data = { users: '', levelSessions: '' } -> properties needed for these objects, i.e. will be used as `project` in db queries
    async fetchDataSingleClass ({ state, dispatch }, options = {}) {
      const fetchPromises = []

      fetchPromises.push(dispatch('courseInstances/fetchCourseInstancesForTeacher', state.teacherId, { root: true }))
      fetchPromises.push(dispatch('courses/fetchReleased', undefined, { root: true }))

      options.fetchInteractiveSessions = true
      fetchPromises.push(dispatch('teacherDashboard/fetchClassroomData', options, { root: true }))

      await Promise.all(fetchPromises)
    },

    // Single class progress page - without blocking loading indicator
    async fetchDataSingleClassAsync ({ state, dispatch }, options = {}) {
      const fetchPromises = []

      fetchPromises.push(dispatch('prepaids/fetchPrepaidsForTeacher', state.teacherId, { root: true }))
      fetchPromises.push(dispatch('teacherDashboard/fetchDataCurriculumGuide', undefined, { root: true }))

      await Promise.all(fetchPromises)
    },

    // Students progress page
    // options.data = { users: '', levelSessions: '' } -> properties needed for these objects, i.e. will be used as `project` in db queries
    async fetchDataStudentProjects ({ state, dispatch }, options = {}) {
      const fetchPromises = []

      fetchPromises.push(dispatch('courses/fetchReleased', undefined, { root: true }))
      fetchPromises.push(dispatch('teacherDashboard/fetchClassroomData', options, { root: true }))

      await Promise.all(fetchPromises)
    },

    // Students progress page - without blocking loading indicator
    async fetchDataStudentProjectsAsync ({ state, dispatch }, options = {}) {
      const fetchPromises = []
      fetchPromises.push(dispatch('prepaids/fetchPrepaidsForTeacher', state.teacherId, { root: true }))
      fetchPromises.push(dispatch('teacherDashboard/fetchDataCurriculumGuide', undefined, { root: true }))
      await Promise.all(fetchPromises)
    },

    // Teacher licenses page
    async fetchDataMyLicenses ({ state, dispatch }, options = {}) {
      const fetchPromises = []
      fetchPromises.push(dispatch('prepaids/fetchPrepaidsForTeacher', state.teacherId, { root: true }))

      await Promise.all(fetchPromises)
    },

    // Teacher licenses page - without blocking loading indicator
    async fetchDataMyLicensesAsync ({ state, dispatch, getters }, options = {}) {
      const fetchPromises = []

      fetchPromises.push(dispatch('teacherDashboard/fetchDataCurriculumGuide', undefined, { root: true }))
      fetchPromises.push(dispatch('classrooms/fetchClassroomsForTeacher', state.teacherId, { root: true }))

      const licenses = getters['getActiveLicenses'].concat(getters['getExpiredLicenses'])
      const licenseIds = (licenses || []).map((l) => l._id)

      licenseIds.forEach((id) => {
        fetchPromises.push(dispatch('users/fetchCreatorOfPrepaid', id, { root: true }))
        fetchPromises.push(dispatch('prepaids/fetchJoinersForPrepaid', id, { root: true }))
      })
      await Promise.all(fetchPromises)
    },

    // Resource Hub Page
    async fetchDataResourceHubAsync ({ state, dispatch }, options = {}) {
      const fetchPromises = []
      fetchPromises.push(dispatch('teacherDashboard/fetchDataCurriculumGuide', undefined, { root: true }))
      fetchPromises.push(dispatch('classrooms/fetchClassroomsForTeacher', state.teacherId, { root: true }))
      await Promise.all(fetchPromises)
    },

    // Curriculum guides panel
    async fetchDataCurriculumGuide ({ dispatch, rootGetters }) {
      let sortedCourses = rootGetters['courses/sorted'] || []
      if (sortedCourses.length === 0) {
        await dispatch('courses/fetchReleased', undefined, { root: true })
      }
      sortedCourses = rootGetters['courses/sorted'] || []
      if (sortedCourses[0]) {
        // After loading ensure that the first course is automatically selected
        dispatch('baseCurriculumGuide/setSelectedCampaign', sortedCourses[0].campaignID, { root: true })
      }
      sortedCourses.forEach(({ campaignID }) => {
        dispatch('gameContent/fetchGameContentForCampaign', { campaignId: campaignID }, { root: true })
      })
    },

    // Fetches classroom data for current state.classroomId
    async fetchClassroomData ({ state, dispatch, rootGetters }, options = {}) {
      if (!state.classroomId) {
        console.error('Error in fetching data: classroomId is not set')
        noty({ text: 'Error in fetching data', type: 'error', layout: 'center', timeout: 2000 })
        return
      }

      await dispatch('classrooms/fetchClassroomsForTeacher', state.teacherId, { root: true })

      const fetchPromises = []

      fetchPromises.push(dispatch('gameContent/fetchGameContentForClassoom', { classroomId: state.classroomId, options }, { root: true }))

      const teacherClassrooms = rootGetters['classrooms/getClassroomsByTeacher'](state.teacherId)
      const classroom = ((teacherClassrooms || {}).active || []).find((cl) => cl._id === state.classroomId)
      if (classroom) {
        const userOptions = {
          project: (options.data || {}).users
        }
        fetchPromises.push(dispatch('users/fetchClassroomMembers', { classroom, options: userOptions }, { root: true }))
        const levelSessionOptions = {
          project: (options.data || {}).levelSessions
        }
        fetchPromises.push(dispatch('levelSessions/fetchForClassroomMembers', { classroom, options: levelSessionOptions }, { root: true }))
        if (options.fetchInteractiveSessions) {
          fetchPromises.push(dispatch('interactives/fetchSessionsForClassroomMembers', classroom, { root: true }))
        }
      }

      // TODO If classroom already loaded, load it asynchronously without blocking UI, i.e. without `await` to optimize performance
      await Promise.all(fetchPromises)
    }
  }
}
