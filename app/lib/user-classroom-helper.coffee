Classroom = require 'models/Classroom'
CourseInstance = require 'models/CourseInstance'
co = require 'co'

isTeacherOf = co.wrap ({ user, classroom, classroomId, courseInstance, courseInstanceId }) ->
  if not user.isTeacher()
    return false

  if classroomId and not classroom
    classroom = new Classroom({ _id: classroomId })
    yield classroom.fetch()

  if classroom
    return true if user.get('_id') == classroom.get('ownerID')

  if courseInstanceId and not courseInstance
    courseInstance = new CourseInstance({ _id: courseInstanceId })
    yield courseInstance.fetch()

  if courseInstance
    return true if user.get('id') == courseInstance.get('ownerID')

  return false

isSchoolAdminOf = co.wrap ({ user, classroom, classroomId, courseInstance, courseInstanceId }) ->
  if not user.isSchoolAdmin()
    return false

  if classroomId and not classroom
    classroom = new Classroom({ _id: classroomId })
    yield classroom.fetch()

  if classroom
    return true if classroom.get('ownerID') in user.get('administratedTeachers')

  if courseInstanceId and not courseInstance
    courseInstance = new CourseInstance({ _id: courseInstanceId })
    yield courseInstance.fetch()

  if courseInstance
    return true if courseInstance.get('ownerID') in user.get('administratedTeachers')

  return false

module.exports = {
  isTeacherOf,
  isSchoolAdminOf
}
