/* eslint-env jasmine */
import GoogleClassroomHandler from 'core/social-handlers/GoogleClassroomHandler'
import factories from 'test/app/factories'
import api from 'core/api'
import store from 'core/store'

var gClassrooms = []

describe('markAsImported(gcId)', () => {
  beforeEach((done) => {
    gClassrooms =[{
        id: "id1",
        name: "test class 1"
      }, {
        id: "id2",
        name: "test class 2"
      }]
    me.set(factories.makeUser({role: 'teacher', googleClassrooms: gClassrooms}).attributes)
    spyOn(me, 'save').and.callFake(function() {
      return $.Deferred().resolve(me).promise();
    });
    done()
  })

  it('should set importedToOzaria=true for gcId in me.googleClassrooms', async function (done) {
    expect(me.get('googleClassrooms')[0].importedToOzaria).toBeUndefined()
    expect(me.get('googleClassrooms')[1].importedToOzaria).toBeUndefined()
    try {
      await GoogleClassroomHandler.markAsImported(gClassrooms[0].id)
      expect(me.get('googleClassrooms')[0].importedToOzaria).toBeDefined()
      expect(me.get('googleClassrooms')[0].importedToOzaria).toBe(true)
      expect(me.get('googleClassrooms')[1].importedToOzaria).toBeUndefined()
      done()
    }
    catch (err) {
      done.fail(new Error("This should not have been called"))
    }
  });

  it('should throw error if the google classroom id does not exist in me.googleClassrooms', async function (done) {
    expect(me.get('googleClassrooms')[0].importedToOzaria).toBeUndefined()
    expect(me.get('googleClassrooms')[1].importedToOzaria).toBeUndefined()
    try {
      await GoogleClassroomHandler.markAsImported("new-id")
      done.fail(new Error("This should not have been called"))
    }
    catch (err) {
      expect(me.get('googleClassrooms')[0].importedToOzaria).toBeUndefined()
      expect(me.get('googleClassrooms')[1].importedToOzaria).toBeUndefined()
      done()
    }
  });

})

describe('importClassrooms()', () => {
  beforeEach((done) => {
    gClassrooms = [{
        id: "id1",
        name: "test class 1"
      }, {
        id: "id2",
        name: "test class 2"
      }]
    me.set(factories.makeUser({role: 'teacher'}).attributes)
    spyOn(me, 'save').and.callFake(function() {
      return $.Deferred().resolve(me).promise();
    });
    done()
  })

  it('adds googleClassrooms to the `me` object', async function(done) {
    spyOn(GoogleClassroomHandler.gcApiHandler, 'loadClassroomsFromAPI').and.returnValue(Promise.resolve(gClassrooms))
    expect(me.get('googleClassrooms')).toBeUndefined()
    try {
      await GoogleClassroomHandler.importClassrooms()
      expect(me.get('googleClassrooms')).toBeDefined()
      expect(me.get('googleClassrooms').length).toBe(gClassrooms.length)
      done()
    }
    catch (err) {
      done.fail(new Error("This should not have been called"))
    }
  });

  it('updates the linked classrooms in me.googleClassrooms while keeping the importedToOzaria value', async function(done) {

    me.set('googleClassrooms', gClassrooms)

    // mark gClassrooms[0] as imported
    let importedClassroom = me.get('googleClassrooms').find((c) => c.id == gClassrooms[0].id)
    importedClassroom.importedToOzaria = true

    expect(me.get('googleClassrooms').length).toBe(2)
    expect(me.get('googleClassrooms').find((gc) => gc.id == importedClassroom.id)).toBeDefined()
    expect(me.get('googleClassrooms').find((gc) => gc.id == importedClassroom.id).name).toBe(importedClassroom.name)
    expect(me.get('googleClassrooms').find((gc) => gc.id == importedClassroom.id).importedToOzaria).toBe(true)
    expect(me.get('googleClassrooms').find((gc) => gc.id != importedClassroom.id)).toBeDefined()
    expect(me.get('googleClassrooms').find((gc) => gc.id != importedClassroom.id).name).toBe(gClassrooms.find((gc) => gc.id!=importedClassroom.id).name)
    expect(me.get('googleClassrooms').find((gc) => gc.id != importedClassroom.id).importedToOzaria).toBeUndefined()

    // new classrooms data recieved from google classroom API
    const newGClassrooms = [{
      id: "id1",
      name: "test class 1-new"
    },
    {
      id: "id2",
      name: "test class 2-new"
    }]
    spyOn(GoogleClassroomHandler.gcApiHandler, 'loadClassroomsFromAPI').and.returnValue(Promise.resolve(newGClassrooms))

    try {
      await GoogleClassroomHandler.importClassrooms()
      // names of linked classroom should be updated, and importedToOzaria field should remain same
      expect(me.get('googleClassrooms').length).toBe(2)
      expect(me.get('googleClassrooms').find((gc) => gc.id == importedClassroom.id)).toBeDefined()
      expect(me.get('googleClassrooms').find((gc) => gc.id == importedClassroom.id).name).toBe(newGClassrooms.find((gc) => gc.id==importedClassroom.id).name)
      expect(me.get('googleClassrooms').find((gc) => gc.id == importedClassroom.id).importedToOzaria).toBe(true)
      expect(me.get('googleClassrooms').find((gc) => gc.id != importedClassroom.id)).toBeDefined()
      expect(me.get('googleClassrooms').find((gc) => gc.id != importedClassroom.id).name).toBe(newGClassrooms.find((gc) => gc.id!=importedClassroom.id).name)
      expect(me.get('googleClassrooms').find((gc) => gc.id != importedClassroom.id).importedToOzaria).toBeUndefined()
      done()
    }
    catch (err) {
      done.fail(new Error("This should not have been called"))
    }
  })

  it('does not remove an already imported classroom from me.googleClassrooms if deleted from google classroom, and sets deletedFromGC flag', async function(done) {
    // mark gClassrooms[0] as imported
    me.set('googleClassrooms', [gClassrooms[0]])
    let importedClassroom = me.get('googleClassrooms').find((c) => c.id == gClassrooms[0].id)
    importedClassroom.importedToOzaria = true

    expect(me.get('googleClassrooms').length).toBe(1)

    // new classrooms data recieved from google classroom API - does not contain classroom id1
    const newGClassrooms = [{
      id: "id2",
      name: "test class 2"
    }]
    spyOn(GoogleClassroomHandler.gcApiHandler, 'loadClassroomsFromAPI').and.returnValue(Promise.resolve(newGClassrooms))

    try {
      await GoogleClassroomHandler.importClassrooms()
      // me.googleClassrooms should contain old imported classroom id1 as well as new classroom id2
      expect(me.get('googleClassrooms').length).toBe(2)
      expect(me.get('googleClassrooms').find((gc) => gc.id == importedClassroom.id)).toBeDefined()
      expect(me.get('googleClassrooms').find((gc) => gc.id == importedClassroom.id).importedToOzaria).toBe(true)
      expect(me.get('googleClassrooms').find((gc) => gc.id == importedClassroom.id).deletedFromGC).toBe(true)
      expect(me.get('googleClassrooms').find((gc) => gc.id != importedClassroom.id)).toBeDefined()
      expect(me.get('googleClassrooms').find((gc) => gc.id != importedClassroom.id).name).toBe(newGClassrooms[0].name)
      expect(me.get('googleClassrooms').find((gc) => gc.id != importedClassroom.id).importedToOzaria).toBeUndefined()
      expect(me.get('googleClassrooms').find((gc) => gc.id != importedClassroom.id).deletedFromGC).toBeUndefined()
      done()
    }
    catch (err) {
      done.fail(new Error("This should not have been called"))
    }
  })

})

describe('importStudentsToClassroom(cocoClassroom)', () => {
  const members = [
    { _id: 'id1', email: 'student1@test.com', firstName: 's1-firstName', lastName: 's1-lastName', role: 'student' },
    { _id: 'id2', email: 'student2@test.com', firstName: 's2-firstName', lastName: 's2-lastName', role: 'student' },
  ]

  beforeEach((done) => {
    me.set(factories.makeUser({ role: 'teacher' }).attributes)
    spyOn(application.gplusHandler, 'token').and.returnValue('fake-access-token')
    done()
  })

  it('calls the api with the classroom id and the google access token', async function (done) {
    spyOn(api.classrooms, 'importGoogleClassroomStudents').and.returnValue(Promise.resolve({ members }))
    try {
      const cocoClassroom = factories.makeClassroom({ googleClassroomId: 'id1' })
      await GoogleClassroomHandler.importStudentsToClassroom(cocoClassroom)
      expect(api.classrooms.importGoogleClassroomStudents).toHaveBeenCalledWith({ classroomID: cocoClassroom.id, accessToken: 'fake-access-token' })
      done()
    } catch (err) {
      done.fail(new Error('This should not have been called'))
    }
  })

  it('returns the members and updates the classroom store without calling add-members again', async function (done) {
    spyOn(api.classrooms, 'importGoogleClassroomStudents').and.returnValue(Promise.resolve({ members }))
    spyOn(store, 'dispatch')
    try {
      const cocoClassroom = factories.makeClassroom({ googleClassroomId: 'id1' })
      const classroomNewMembers = await GoogleClassroomHandler.importStudentsToClassroom(cocoClassroom)
      expect(classroomNewMembers).toEqual(members)
      expect(store.dispatch).toHaveBeenCalledWith('classrooms/addMembersToClassroom', { classroom: cocoClassroom.attributes, members, skipApiCall: true })
      done()
    } catch (err) {
      done.fail(new Error('This should not have been called'))
    }
  })

  it('resolves with no members and shows the no-new-students noty when no new students were imported', async function (done) {
    spyOn(api.classrooms, 'importGoogleClassroomStudents').and.returnValue(Promise.resolve({ members: [] }))
    try {
      const cocoClassroom = factories.makeClassroom({ googleClassroomId: 'id1' })
      const classroomNewMembers = await GoogleClassroomHandler.importStudentsToClassroom(cocoClassroom)
      expect(classroomNewMembers).toEqual([])
      done()
    } catch (err) {
      done.fail(new Error('This should not have been called'))
    }
  })
})
