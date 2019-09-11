import GoogleClassroomHandler from 'core/social-handlers/GoogleClassroomHandler'
import factories from 'test/app/factories'
import api from 'core/api'

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

  it('should set importedToCoco=true for gcId in me.googleClassrooms', async function (done) {
    expect(me.get('googleClassrooms')[0].importedToCoco).toBeUndefined()
    expect(me.get('googleClassrooms')[1].importedToCoco).toBeUndefined()
    try {
      await GoogleClassroomHandler.markAsImported(gClassrooms[0].id)
      expect(me.get('googleClassrooms')[0].importedToCoco).toBeDefined()
      expect(me.get('googleClassrooms')[0].importedToCoco).toBe(true)
      expect(me.get('googleClassrooms')[1].importedToCoco).toBeUndefined()
      done()
    }
    catch (err) {
      done.fail(new Error("This should not have been called"))
    }
  });

  it('should throw error if the google classroom id does not exist in me.googleClassrooms', async function (done) {
    expect(me.get('googleClassrooms')[0].importedToCoco).toBeUndefined()
    expect(me.get('googleClassrooms')[1].importedToCoco).toBeUndefined()
    try {
      await GoogleClassroomHandler.markAsImported("new-id")
      done.fail(new Error("This should not have been called"))
    }
    catch (err) {
      expect(me.get('googleClassrooms')[0].importedToCoco).toBeUndefined()
      expect(me.get('googleClassrooms')[1].importedToCoco).toBeUndefined()
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

  it('updates the classrooms in me.googleClassrooms except the already imported classrooms', async function(done) {
    
    me.set('googleClassrooms', gClassrooms)

    // mark gClassrooms[0] as imported
    let importedClassroom = me.get('googleClassrooms').find((c) => c.id == gClassrooms[0].id)
    importedClassroom.importedToCoco = true

    expect(me.get('googleClassrooms').length).toBe(2)
    expect(me.get('googleClassrooms').find((gc) => gc.id == importedClassroom.id)).toBeDefined()
    expect(me.get('googleClassrooms').find((gc) => gc.id == importedClassroom.id).name).toBe(importedClassroom.name)
    expect(me.get('googleClassrooms').find((gc) => gc.id == importedClassroom.id).importedToCoco).toBe(true)
    expect(me.get('googleClassrooms').find((gc) => gc.id != importedClassroom.id)).toBeDefined()
    expect(me.get('googleClassrooms').find((gc) => gc.id != importedClassroom.id).name).toBe(gClassrooms.find((gc) => gc.id!=importedClassroom.id).name)
    expect(me.get('googleClassrooms').find((gc) => gc.id != importedClassroom.id).importedToCoco).toBeUndefined()

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
      // name of id2 classroom should be updated, and everything else should remain same
      expect(me.get('googleClassrooms').length).toBe(2)
      expect(me.get('googleClassrooms').find((gc) => gc.id == importedClassroom.id)).toBeDefined()
      expect(me.get('googleClassrooms').find((gc) => gc.id == importedClassroom.id).name).toBe(importedClassroom.name)
      expect(me.get('googleClassrooms').find((gc) => gc.id == importedClassroom.id).importedToCoco).toBe(true)
      expect(me.get('googleClassrooms').find((gc) => gc.id != importedClassroom.id)).toBeDefined()
      expect(me.get('googleClassrooms').find((gc) => gc.id != importedClassroom.id).name).toBe(newGClassrooms.find((gc) => gc.id!=importedClassroom.id).name)
      expect(me.get('googleClassrooms').find((gc) => gc.id != importedClassroom.id).importedToCoco).toBeUndefined()
      done()
    }
    catch (err) {
      done.fail(new Error("This should not have been called"))
    }
  })

  it('does not remove an already imported classroom from me.googleClassrooms if deleted from google classroom', async function(done) {
    // mark gClassrooms[0] as imported
    me.set('googleClassrooms', [gClassrooms[0]])
    let importedClassroom = me.get('googleClassrooms').find((c) => c.id == gClassrooms[0].id)
    importedClassroom.importedToCoco = true

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
      expect(me.get('googleClassrooms').find((gc) => gc.id == importedClassroom.id).importedToCoco).toBe(true)
      expect(me.get('googleClassrooms').find((gc) => gc.id != importedClassroom.id)).toBeDefined()
      expect(me.get('googleClassrooms').find((gc) => gc.id != importedClassroom.id).name).toBe(newGClassrooms[0].name)
      expect(me.get('googleClassrooms').find((gc) => gc.id != importedClassroom.id).importedToCoco).toBeUndefined()
      done()
    }
    catch (err) {
      done.fail(new Error("This should not have been called"))
    }
  })

})

const gcStudents = [
  {
    userId: "studentId1",
    profile: {
      name: {
        givenName: "s1-firstName",
        familyName: "s1-lastName"
      },
      emailAddress: "student1@test.com"
    }
  },
  {
    userId: "studentId2",
    profile: {
      name: {
        givenName: "s2-firstName",
        familyName: "s2-lastName"
      },
      emailAddress: "student2@test.com"
    }
  }
]

describe('importStudentsToClassroom(cocoClassroom)', () => {
  beforeEach((done) => {
    me.set(factories.makeUser({role: 'teacher'}).attributes)
    spyOn(GoogleClassroomHandler.gcApiHandler, 'loadStudentsFromAPI').and.returnValue(Promise.resolve(gcStudents)) 
    done()
  })

  it('signs up the imported students on codecombat with their google id and adds them to the classroom', async function(done) {
    const users = gcStudents.map((s) => {
      return factories.makeUser({
        gplusID: s.userId,
        firstName: s.profile.givenName,
        lastName: s.profile.familyName,
        email: s.profile.emailAddress,
        role: 'student'
      })
    })
    spyOn(api.users, 'signupFromGoogleClassroom').and.callFake(function(attrs) {
      return Promise.resolve(users.find((u) => u.get('gplusID')==attrs.gplusID))
    })

    const classroomWithNewMembers = factories.makeClassroom({googleClassroomId: "id1", members: users.map((u) => u._id)})
    spyOn(api.classrooms, 'addMembers').and.returnValue(Promise.resolve(classroomWithNewMembers)) 
    
    try {
      const cocoClassroom = factories.makeClassroom({googleClassroomId: "id1"})
      const classroomNewMembers = await GoogleClassroomHandler.importStudentsToClassroom(cocoClassroom)
      expect(api.users.signupFromGoogleClassroom).toHaveBeenCalled()
      expect(api.users.signupFromGoogleClassroom.calls.count()).toEqual(gcStudents.length)
      expect(api.classrooms.addMembers).toHaveBeenCalled()
      expect(classroomNewMembers.length).toEqual(gcStudents.length)
      expect(classroomNewMembers[0].get('gplusID')).toBe(gcStudents[0].userId)
      expect(classroomNewMembers[1].get('gplusID')).toBe(gcStudents[1].userId)
      done()
    }
    catch (err) {
      done.fail(new Error("This should not have been called"))
    }
  });

  describe ('if students already exist on codecombat', () => {
    it('does not add students if already exist in the classroom', async function(done) {
      const signUpResult = gcStudents.map((s) => {
        let user = factories.makeUser({
          gplusID: s.userId,
          firstName: s.profile.givenName,
          lastName: s.profile.familyName,
          email: s.profile.emailAddress,
          role: 'student'
        }).attributes
        return {
          isError: true,
          errorID: 'google-id-exists',
          error: user
        }
      })
      spyOn(api.users, 'signupFromGoogleClassroom').and.callFake(function(attrs) {
        return Promise.resolve(signUpResult.find((r) => r.error.gplusID==attrs.gplusID))
      })

      const classroomWithNewMembers = factories.makeClassroom({googleClassroomId: "id1", members: signUpResult.map((r) => r.error._id)})
      spyOn(api.classrooms, 'addMembers').and.returnValue(Promise.resolve(classroomWithNewMembers))

      try {
        await GoogleClassroomHandler.importStudentsToClassroom(classroomWithNewMembers)
        done.fail(new Error("This should not have been called"))
      }
      catch (err) {
        expect(api.users.signupFromGoogleClassroom).toHaveBeenCalled()
        expect(api.users.signupFromGoogleClassroom.calls.count()).toEqual(gcStudents.length)
        expect(api.classrooms.addMembers).not.toHaveBeenCalled()
        done()
      }
    });

    it('adds students to classroom if do not exist already', async function(done) {
      const signUpResult = gcStudents.map((s) => {
        let user = factories.makeUser({
          gplusID: s.userId,
          firstName: s.profile.givenName,
          lastName: s.profile.familyName,
          email: s.profile.emailAddress,
          role: 'student'
        }).attributes
        return {
          isError: true,
          errorID: 'google-id-exists',
          error: user
        }
      })
      spyOn(api.users, 'signupFromGoogleClassroom').and.callFake(function(attrs) {
        return Promise.resolve(signUpResult.find((r) => r.error.gplusID==attrs.gplusID))
      })

      const classroomWithNewMembers = factories.makeClassroom({googleClassroomId: "id1", members: signUpResult.map((r) => r.error._id)})
      spyOn(api.classrooms, 'addMembers').and.returnValue(Promise.resolve(classroomWithNewMembers))

      try {
        const cocoClassroom = factories.makeClassroom({googleClassroomId: "id1"})
        const newMembers = await GoogleClassroomHandler.importStudentsToClassroom(cocoClassroom)
        expect(api.users.signupFromGoogleClassroom).toHaveBeenCalled()
        expect(api.users.signupFromGoogleClassroom.calls.count()).toEqual(gcStudents.length)
        expect(api.classrooms.addMembers).toHaveBeenCalled()
        expect(newMembers.length).toEqual(gcStudents.length)
        done()
      }
      catch (err) {
        done.fail(new Error("This should not have been called"))
      }
    })
  })
})