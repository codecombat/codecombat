import CocoClass from 'core/CocoClass'

const generateClassroomHandler = require('./ExternalClassroomHandler')

const SchoologyAPIHandler = class SchoologyAPIHandler extends CocoClass {
  async loadClassroomsFromAPI () {
    const response = await fetch('/edlink/classrooms')
    return response.json()
  }

  async getAllStudents (schoologyClassroomId) {
    const response = await fetch(`/edlink/classrooms/${schoologyClassroomId}/students`)
    return response.json()
  }
}

module.exports = generateClassroomHandler(SchoologyAPIHandler, 'schoologyClassroom')