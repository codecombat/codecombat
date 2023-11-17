// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const Classroom = require('models/Classroom');
const CourseInstance = require('models/CourseInstance');
const co = require('co');

const isTeacherOf = co.wrap(function*({ user, classroom, classroomId, courseInstance, courseInstanceId }) {
  if (!user.isTeacher()) {
    return false;
  }

  if (classroomId && !classroom) {
    classroom = new Classroom({ _id: classroomId });
    yield classroom.fetch();
  }

  if (classroom) {
    if (user.get('_id') === classroom.get('ownerID')) { return true; }
  }

  if (courseInstanceId && !courseInstance) {
    courseInstance = new CourseInstance({ _id: courseInstanceId });
    yield courseInstance.fetch();
  }

  if (courseInstance) {
    if (user.get('id') === courseInstance.get('ownerID')) { return true; }
  }

  return false;
});

const isSchoolAdminOf = co.wrap(function*({ user, classroom, classroomId, courseInstance, courseInstanceId }) {
  if (!user.isSchoolAdmin()) {
    return false;
  }

  if (classroomId && !classroom) {
    classroom = new Classroom({ _id: classroomId });
    yield classroom.fetch();
  }

  if (classroom) {
    let needle;
    if ((needle = classroom.get('ownerID'), Array.from(user.get('administratedTeachers')).includes(needle))) { return true; }
  }

  if (courseInstanceId && !courseInstance) {
    courseInstance = new CourseInstance({ _id: courseInstanceId });
    yield courseInstance.fetch();
  }

  if (courseInstance) {
    let needle1;
    if ((needle1 = courseInstance.get('ownerID'), Array.from(user.get('administratedTeachers')).includes(needle1))) { return true; }
  }

  return false;
});

module.exports = {
  isTeacherOf,
  isSchoolAdminOf
};
