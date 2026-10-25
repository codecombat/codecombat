import api from 'core/api'
import CocoClass from 'core/CocoClass'
const SCOPE = 'https://www.googleapis.com/auth/classroom.courses.readonly https://www.googleapis.com/auth/classroom.profile.emails https://www.googleapis.com/auth/classroom.rosters.readonly'

const utils = require('core/utils')

const GoogleClassroomAPIHandler = class GoogleClassroomAPIHandler extends CocoClass {

  constructor () {
    if (me.useGoogleClassroom()) {
      application.gplusHandler.loadAPI()
    }
    super()
  }

  loadClassroomsFromAPI () {
    return new Promise((resolve, reject) => {
      const fun = () => {
        gapi.client.load('classroom', 'v1', () => {
          gapi.client.classroom.courses.list({ access_token: application.gplusHandler.token(), teacherId: me.get('gplusID'), courseStates: 'ACTIVE' })
            .then((r) => {
              resolve(r.result.courses || [])
            })
            .catch((err) => {
              console.error('Error in fetching from Google Classroom loadClassroom:', err)
              reject(err)
            })
        })
      }
      this.requestGoogleAccessToken(fun)
    })
  }

  requestGoogleAccessToken (callback) {
    application.gplusHandler.requestGoogleAuthorization(
      SCOPE,
      callback
    )
  }

}

module.exports = {
  gcApiHandler: new GoogleClassroomAPIHandler(),

  scopes: 'https://www.googleapis.com/auth/classroom.courses.readonly https://www.googleapis.com/auth/classroom.profile.emails https://www.googleapis.com/auth/classroom.rosters.readonly',

  markAsImported: async function(gcId) {
    try {
      let gClass = me.get('googleClassrooms').find((c)=>c.id==gcId)
      if (gClass) {
        if (utils.isCodeCombat) {
          gClass.importedToCoco = true
        } else {
          gClass.importedToOzaria = true
        }
        await new Promise(me.save().then)
      }
      else {
        return Promise.reject("Classroom not found in me.googleClassrooms")
      }
    }
    catch (err) {
      console.error("Error in marking classroom as imported:", err)
      return Promise.reject("Error in marking classroom as imported")
    }
  },

  // import classrooms from GC and merge them into me.googleClassrooms
  // this also sets `deletedFromGC` for classrooms that are removed from GC but had already been imported to coco/ozaria
  importClassrooms: async function() {
    try {
      const importedClassrooms = await this.gcApiHandler.loadClassroomsFromAPI()
      const importedClassroomsNames = importedClassrooms.map((c) => {
        return { id: c.id, name: c.name }
      })
      const classrooms = me.get('googleClassrooms') || []
      let mergedClassrooms = []
      importedClassroomsNames.forEach((imported) => {
        const cl = classrooms.find((c) => c.id == imported.id)
        mergedClassrooms.push({ ...cl, ...imported })
      })

      // classrooms that were imported to coco/ozaria but no more exist in importedClassroomNames, i.e. have been removed from google classroom
      const mergedClassroomIds = mergedClassrooms.map((m) => m.id)
      const extraClassroomsImported = classrooms.filter((c) => (c.importedToCoco || c.importedToOzaria) && !(mergedClassroomIds.includes(c.id)))
      // set deletedFromGC, so that it gets filtered from the dropdown on the create classroom modal
      // for example, a class that is importedToOzaria but deleted from GC should not be available in the dropdown on coco
      extraClassroomsImported.forEach((e) => e.deletedFromGC = true)
      mergedClassrooms = mergedClassrooms.concat(extraClassroomsImported)
      me.set('googleClassrooms', mergedClassrooms)
      await new Promise(me.save().then)
    }
    catch (err) {
      console.error("Error in importing classrooms", err)
      return Promise.reject()
    }
  },

  // Imports students from google classroom, create their account on coco and add to the coco classroom
  importStudentsToClassroom: async function (cocoClassroom) {
    const store = require('core/store')
    try {
      cocoClassroom = cocoClassroom?.attributes || cocoClassroom

      const accessToken = await new Promise((resolve) => {
        const fun = () => resolve(application.gplusHandler.token())
        if (!application.gplusHandler.token()) this.gcApiHandler.requestGoogleAccessToken(fun)
        else fun()
      })

      const { members: classroomNewMembers } = await api.classrooms.importGoogleClassroomStudents({ classroomID: cocoClassroom._id, accessToken })

      if (classroomNewMembers.length > 0) {
        if (!utils.isCodeCombat) {
          await store.dispatch('classrooms/addMembersToClassroom', { classroom: cocoClassroom, members: classroomNewMembers, skipApiCall: true, componentName: store.getters['teacherDashboard/getComponentName'] })
        }
        noty ( {text: classroomNewMembers.length+' Students imported.', layout: 'topCenter', timeout: 3000, type: 'success' })
        return classroomNewMembers
      } else if (utils.isCodeCombat) {
        console.error("No new students imported.")
        return Promise.reject('No new students imported')
      }
      else {
        noty({ text: $.i18n.t('teachers.no_new_students_imported'), layout: 'topCenter', type: 'success', timeout: 3000 })
        return []
      }
    }
    catch (err) {
      console.error("Error in importing students", err)
      return Promise.reject(`Error in importing students: ${err.message}`)
    }
  }
}
