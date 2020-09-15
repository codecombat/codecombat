
import { COMPONENT_NAMES, PAGE_TITLES } from 'ozaria/site/components/school-admin-dashboard/common/constants.js'
import { COMPONENT_NAMES as DT_COMPONENT_NAMES } from 'ozaria/site/components/teacher-dashboard/common/constants.js'
import User from 'app/models/User'

export default {
  namespaced: true,

  state: {
    schoolAdminId: '',
    selectedAdministeredTeacherId: '',
    selectedAdministeredTeacherClassroomId: '',
    loading: false,
    pageTitle: '',
    componentName: ''
  },

  mutations: {
    setSchoolAdminId (state, schoolAdminId) {
      if (state.schoolAdminId !== schoolAdminId) {
        state.schoolAdminId = schoolAdminId
      }
    },
    setSelectedAdministeredTeacherId (state, teacherId) {
      state.selectedAdministeredTeacherId = teacherId
    },
    setSelectedAdministeredTeacherClassroomId (state, classroomId) {
      state.selectedAdministeredTeacherClassroomId = classroomId
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
    setPageTitle (state, title) {
      state.pageTitle = title
    },
    setComponentName (state, componentName) {
      state.componentName = componentName
    }
  },

  getters: {
    schoolAdminId (state) {
      return state.schoolAdminId
    },
    selectedAdministeredTeacherId (state) {
      return state.selectedAdministeredTeacherId
    },
    selectedAdministeredTeacherClassroomId (state) {
      return state.selectedAdministeredTeacherClassroomId
    },
    selectedAdministeredTeacherName (state, getters) {
      if (state.selectedAdministeredTeacherId) {
        const teacherData = getters['getAdministratedTeacherData']
        return User.broadName(teacherData)
      } else {
        return ''
      }
    },
    getLoadingState (state) {
      return state.loading
    },
    getPageTitle (state) {
      return state.pageTitle
    },
    getPageBreadCrumbs (state, getters) {
      if (!Object.values(COMPONENT_NAMES.ADMINISTERED_TEACHERS).includes(state.componentName)) {
        return []
      }
      const teacherName = getters['selectedAdministeredTeacherName']
      const teacherId = state.selectedAdministeredTeacherId
      let classroomName = ''
      let breadcrumbs = []
      if (state.selectedAdministeredTeacherClassroomId) {
        const classroomData = getters['getAdministratedTeacherClassroomData']
        classroomName = classroomData.name
      }
      if (state.componentName === COMPONENT_NAMES.ADMINISTERED_TEACHERS.ALL_CLASSES) {
        breadcrumbs = [{
          href: '/school-administrator',
          text: PAGE_TITLES[COMPONENT_NAMES.MY_SCHOOLS]
        }, {
          text: `${teacherName}'s Classes`
        }]
      } else if (state.componentName === COMPONENT_NAMES.ADMINISTERED_TEACHERS.TEACHER_LICENSES) {
        breadcrumbs = [{
          href: '/school-administrator',
          text: PAGE_TITLES[COMPONENT_NAMES.MY_SCHOOLS]
        }, {
          text: `${teacherName}'s Licenses`
        }]
      } else if (state.componentName === COMPONENT_NAMES.ADMINISTERED_TEACHERS.CLASS_PROGRESS) {
        breadcrumbs = [{
          href: '/school-administrator',
          text: PAGE_TITLES[COMPONENT_NAMES.MY_SCHOOLS]
        }, {
          href: `/school-administrator/teacher/${teacherId}`,
          text: `${teacherName}'s Classes`
        }, {
          text: `${classroomName} Progress`
        }]
      } else if (state.componentName === COMPONENT_NAMES.ADMINISTERED_TEACHERS.CLASS_PROJECTS) {
        breadcrumbs = [{
          href: '/school-administrator',
          text: PAGE_TITLES[COMPONENT_NAMES.MY_SCHOOLS]
        }, {
          href: `/school-administrator/teacher/${teacherId}`,
          text: `${teacherName}'s Classes`
        }, {
          text: `${classroomName} Projects`
        }]
      }
      // TODO Use i18n
      return breadcrumbs
    },
    getComponentName (state) {
      return state.componentName
    },
    getActiveLicenses (state, _getters, _rootState, rootGetters) {
      if (state.schoolAdminId) {
        return rootGetters['prepaids/getActiveLicensesForTeacher'](state.schoolAdminId) || []
      } else {
        return []
      }
    },
    getExpiredLicenses (state, _getters, _rootState, rootGetters) {
      if (state.schoolAdminId) {
        return rootGetters['prepaids/getExpiredLicensesForTeacher'](state.schoolAdminId) || []
      } else {
        return []
      }
    },
    getAdministratedTeachers (state, _getters, _rootState, rootGetters) {
      if (state.schoolAdminId) {
        return rootGetters['schoolAdministrator/getTeachers'] || []
      } else {
        return []
      }
    },
    getAdministratedTeacherData (state, _getters, _rootState, rootGetters) {
      if (state.selectedAdministeredTeacherId) {
        return (rootGetters['schoolAdministrator/getTeachers'] || []).find((t) => t._id === state.selectedAdministeredTeacherId) || {}
      } else {
        return {}
      }
    },
    getAdministratedTeacherClassroomData (state, _getters, _rootState, rootGetters) {
      if (state.selectedAdministeredTeacherId && state.selectedAdministeredTeacherClassroomId) {
        const activeClassrooms = rootGetters['classrooms/getActiveClassroomsByTeacher'](state.selectedAdministeredTeacherId) || []
        return activeClassrooms.find((c) => c._id === state.selectedAdministeredTeacherClassroomId) || {}
      } else {
        return {}
      }
    },
    getAllAdministratedClassrooms (_state, getters, _rootState, rootGetters) {
      const teachers = getters['getAdministratedTeachers']
      let allClassrooms = []
      teachers.forEach((t) => {
        const classrooms = rootGetters['classrooms/getClassroomsByTeacher'](t._id) || {}
        allClassrooms = allClassrooms.concat(classrooms.active || [])
        allClassrooms = allClassrooms.concat(classrooms.archived || [])
      })
      return allClassrooms
    }
  },

  actions: {
    // componentName = name of the vue component -> used to fetch relevant data for the respective page
    // options = { data: {} }
    // options.data = {} -> contains specific properties to fetch (or `project`) for an object as a string, eg: {users: 'firstName,lastName,email', levelSessions: 'state.complete,level,creator,changed'}
    async fetchData ({ state, dispatch, commit }, { componentName, options = {} }) {
      if (!state.schoolAdminId) {
        console.error('Error in fetching data: schoolAdminId is not set')
        noty({ text: 'Error in fetching data', type: 'error', layout: 'center', timeout: 2000 })
        return
      }

      commit('startLoading')
      commit('setComponentName', componentName)
      try {
        dispatch('fetchDataCurriculumGuide') // loaded async (doesnt block loading bar)
        if (componentName === COMPONENT_NAMES.SCHOOL_ADMIN_LICENSES) {
          // SchoolAdmin licenses page
          await dispatch('fetchDataMyLicenses', options)
        } else if (componentName === COMPONENT_NAMES.MY_SCHOOLS) {
          // My Schools page
          await dispatch('fetchDataMySchools', options)
        } else {
          // Administrated teachers' pages
          await dispatch('fetchDataAdministratedTeachers', options)
        }
      } catch (err) {
        console.error('Error in fetching data:', err)
        noty({ text: 'Error in fetching data', type: 'error', layout: 'topCenter', timeout: 2000 })
      } finally {
        commit('stopLoading')
        if (options.loadedEventName) { // should be set for tracking the loaded event for dashboard pages
          window.tracker?.trackEvent(options.loadedEventName, { category: 'SchoolAdmin' })
        }
      }
    },

    // My Schools page
    async fetchDataMySchools ({ state, dispatch, getters }, options = {}) {
      await dispatch('schoolAdministrator/fetchTeachers', undefined, { root: true }) // fetches for me.id

      const fetchPromises = []
      const teachers = getters['getAdministratedTeachers']
      teachers.forEach((t) => {
        fetchPromises.push(dispatch('userStats/fetchStatsForUser', t._id, { root: true }))
      })

      await Promise.all(fetchPromises)
    },

    // Administrated teachers' pages
    async fetchDataAdministratedTeachers ({ state, dispatch, getters }, options = {}) {
      await dispatch('schoolAdministrator/fetchTeachers', undefined, { root: true }) // fetches for me.id

      const fetchPromises = []
      const teachers = getters['getAdministratedTeachers']
      teachers.forEach((t) => {
        fetchPromises.push(dispatch('classrooms/fetchClassroomsForTeacher', t._id, { root: true })) // needed for breadcrumbs
      })

      await Promise.all(fetchPromises)

      // Specific data for each Administrated teachers' page is loaded from `teacherDashboard.js` by mounting the relevant DT vue component on the DSA page
      // It might lead to fetching some additional data on each such DSA page (which is needed for DT but not for DSA, eg: prepaids on all classes page)
      // This is fine for now since its not adding any performance bottleneck, but can be refactored later if needed
    },

    // SchoolAdmin licenses page
    async fetchDataMyLicenses ({ state, dispatch }, options = {}) {
      const fetchPromises = []
      fetchPromises.push(dispatch('prepaids/fetchPrepaidsForTeacher', state.schoolAdminId, { root: true }))
      fetchPromises.push(dispatch('fetchDataAdministratedTeachers', options)) // needed for student-enrollment-history

      await Promise.all(fetchPromises)

      // fetch async (doesnt block loading)
      dispatch('fetchDataMyLicensesAsync', options)
    },

    // SchoolAdmin licenses page async - without blocking loading indicator
    async fetchDataMyLicensesAsync ({ state, dispatch, getters }, options = {}) {
      const fetchPromises = []

      const licenses = getters['getActiveLicenses'].concat(getters['getExpiredLicenses'])
      const licenseIds = (licenses || []).map((l) => l._id)

      licenseIds.forEach((id) => {
        fetchPromises.push(dispatch('users/fetchCreatorOfPrepaid', id, { root: true }))
        fetchPromises.push(dispatch('prepaids/fetchJoinersForPrepaid', id, { root: true }))
      })
      await Promise.all(fetchPromises)
    },

    // Curriculum guides panel
    async fetchDataCurriculumGuide ({ state, dispatch, rootGetters }) {
      dispatch('prepaids/fetchPrepaidsForTeacher', state.schoolAdminId, { root: true }) // needed so that curr guide can check if its a paid school admin user or not
      dispatch('teacherDashboard/fetchDataCurriculumGuide', undefined, { root: true })
    }
  }
}
