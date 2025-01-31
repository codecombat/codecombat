import CocoClass from 'core/CocoClass'
const SCOPE = 'https://www.googleapis.com/auth/classroom.courses.readonly https://www.googleapis.com/auth/classroom.profile.emails https://www.googleapis.com/auth/classroom.rosters.readonly'
const generateClassroomHandler = require('./ExternalClassroomHandler')

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

  loadStudentsFromAPI (googleClassroomId, nextPageToken='') {
    return new Promise((resolve, reject) => {
      const fun = () => gapi.client.load('classroom', 'v1', () => {
        gapi.client.classroom.courses.students.list({ access_token: application.gplusHandler.token(), courseId: googleClassroomId, pageToken: nextPageToken })
        .then((r) => {
            resolve(r.result || {})
          })
        .catch ((err) => {
            console.error('Error in fetching from Google Classroom loadStudent:', err)
            reject(err)
          })
        })
      if (!application.gplusHandler.token()) this.requestGoogleAccessToken(fun)
      else fun()
    })
  }

  async getAllStudents(googleClassroomId) {
    let importedStudents = []
    let importStudentsResult = await this.loadStudentsFromAPI(googleClassroomId)
    importedStudents = importedStudents.concat(importStudentsResult.students || [])
    while ((importStudentsResult.nextPageToken || '').length > 0) {
      const nextPageToken = importStudentsResult.nextPageToken
      importStudentsResult = await this.loadStudentsFromAPI(googleClassroomId, nextPageToken)
      importedStudents = importedStudents.concat(importStudentsResult.students || [])
    }
    return importedStudents
  }

  requestGoogleAccessToken (callback) {
    application.gplusHandler.requestGoogleAuthorization(
      SCOPE,
      callback
    )
  }
}

module.exports = generateClassroomHandler(GoogleClassroomAPIHandler, 'googleClassroom')