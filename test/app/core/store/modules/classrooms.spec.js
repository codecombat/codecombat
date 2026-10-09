/* eslint-env jasmine */
import classroomsModule from 'app/core/store/modules/classrooms'
import classroomsApi from 'core/api/classrooms'

describe('classrooms store addMembersToClassroom', () => {
  const classroom = { _id: 'classroom1', ownerID: 'teacher1', permissions: [] }
  const members = [{ _id: 'student1' }, { _id: 'student2' }]
  let commit, dispatch

  beforeEach(() => {
    commit = jasmine.createSpy('commit')
    dispatch = jasmine.createSpy('dispatch')
    spyOn(classroomsApi, 'addMembers').and.returnValue(Promise.resolve())
  })

  it('calls add-members and updates the classroom in the store', async function (done) {
    try {
      await classroomsModule.actions.addMembersToClassroom({ commit, dispatch }, { classroom, members })
      expect(classroomsApi.addMembers).toHaveBeenCalledWith({ classroomID: 'classroom1', members })
      expect(commit).toHaveBeenCalledWith('addMembersForClassroom', { teacherId: 'teacher1', classroomId: 'classroom1', memberIds: ['student1', 'student2'] })
      expect(dispatch).toHaveBeenCalledWith('baseSingleClass/fetchData', {}, { root: true })
      done()
    } catch (err) {
      done.fail(err)
    }
  })

  it('skips add-members with skipApiCall and still updates the classroom in the store', async function (done) {
    try {
      await classroomsModule.actions.addMembersToClassroom({ commit, dispatch }, { classroom, members, skipApiCall: true })
      expect(classroomsApi.addMembers).not.toHaveBeenCalled()
      expect(commit).toHaveBeenCalledWith('addMembersForClassroom', { teacherId: 'teacher1', classroomId: 'classroom1', memberIds: ['student1', 'student2'] })
      expect(dispatch).toHaveBeenCalledWith('baseSingleClass/fetchData', {}, { root: true })
      done()
    } catch (err) {
      done.fail(err)
    }
  })
})
