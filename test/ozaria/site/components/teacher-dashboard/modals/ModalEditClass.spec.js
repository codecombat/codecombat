/* eslint-env jasmine */
import Component from 'ozaria/site/components/teacher-dashboard/modals/ModalEditClass.vue'
import GoogleClassroomHandler from 'core/social-handlers/GoogleClassroomHandler'
import { COMPONENT_NAMES } from 'ozaria/site/components/teacher-dashboard/common/constants.js'
import api from 'core/api'
import store from 'core/store'
import utils from 'core/utils'

describe('ModalEditClass handleClassroomImport', () => {
  const members = [{ _id: 'id1', email: 'student1@test.com', role: 'student' }]
  let isCodeCombat

  beforeEach(() => {
    isCodeCombat = utils.isCodeCombat
    utils.isCodeCombat = false
    store.commit('teacherDashboard/setComponentName', COMPONENT_NAMES.MY_CLASSES_ALL)
    spyOn(GoogleClassroomHandler, 'markAsImported').and.returnValue(Promise.resolve())
    spyOn(application.gplusHandler, 'token').and.returnValue('fake-access-token')
    spyOn(api.classrooms, 'importGoogleClassroomStudents').and.returnValue(Promise.resolve({ members }))
    spyOn(store, 'dispatch').and.returnValue(Promise.resolve())
  })

  afterEach(() => {
    utils.isCodeCombat = isCodeCombat
    store.commit('teacherDashboard/setComponentName', '')
  })

  it('imports the Google Classroom students once and refreshes the page the teacher is on', async function (done) {
    try {
      await Component.options.methods.handleClassroomImport.call({ isGoogleClassroomForm: true, googleClassId: 'gc1' }, { _id: 'classroom1' }, {})
      expect(api.classrooms.importGoogleClassroomStudents.calls.count()).toBe(1)
      expect(store.dispatch).toHaveBeenCalledWith('classrooms/addMembersToClassroom', jasmine.objectContaining({ members, skipApiCall: true, componentName: COMPONENT_NAMES.MY_CLASSES_ALL }))
      done()
    } catch (err) {
      done.fail(err)
    }
  })
})
