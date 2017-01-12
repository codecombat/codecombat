/*

Imports a CSV of students and classrooms, generates them for a given teacher.

NOTE: This script is not set up for general use; it needs customization described in Usage.

Usage:

* Export prod env
* Set TEACHER_EMAIL below
* Prepare csv, edit logic below to get csv -> inputUsers as an array of user objects
* Update logic below to make sure the inputUser properties are being properly set to db docs
* Run this script with `node`

 */

TEACHER_EMAIL = ''

inputUsers = [] // TODO: Import from csv
require('coffee-script');
require('coffee-script/register');
GLOBAL._ = require('lodash')
_.str = require('underscore.string')
_.mixin(_.str.exports())

database = require('../server/commons/database')
database.connect()
mongoose = require('mongoose')
User = require('../server/models/User')
Classroom = require('../server/models/Classroom')
CourseInstance = require('../server/models/CourseInstance')
co = require('co')
co(function*() {

  // Load teacher
  teacher = yield User.findOne({emailLower: TEACHER_EMAIL.toLowerCase()})
  if (!teacher) {
    throw new Error('Teacher not found')
  }

  // Load classroom
  classrooms = yield Classroom.find({ ownerID: teacher._id })
  classroomMap = _.object(_.map(classrooms, (c) => c.get('name')), classrooms)

  for (var i in inputUsers) {
    inputUser = inputUsers[i] // { classroomName, userName, password }
    console.log(`${i}/${inputUsers.length}: ${inputUser.userName} -----------`)

    // Upsert classroom
    if (!classroomMap[inputUser.classroomName]) {
      console.log(`\tMaking classroom "${inputUser.classroomName}"...`)
      classroom = new Classroom()
      classroom.set('ownerID', teacher._id)
      classroom.set('members', [])
      classroom.set('name', inputUser.classroomName)
      classroom.set('aceConfig', {"language":"python"})
      yield classroom.setUpdatedCourses({isAdmin: false, addNewCoursesOnly: false})
      yield classroom.save()
      classroomMap[classroom.get('name')] = classroom
    }
    classroom = classroomMap[inputUser.classroomName]

    // Upsert course instance for CS1
    courseID = mongoose.Types.ObjectId("560f1a9f22961295f9427742")
    courseInstance = yield CourseInstance.findOne({classroomID: classroom._id, courseID: courseID })
    if (!courseInstance) {
      console.log(`\tMaking CS1 course instance...`)
      courseInstance = new CourseInstance({
        "classroomID": classroom._id,
        "courseID": courseID,
        "aceConfig": {},
        "ownerID": teacher._id,
        "members": []
      })
      yield courseInstance.save()
    }

    // Upsert user
    user = yield User.findOne({nameLower: inputUser.userName.toLowerCase()})
    if (!user) {
      console.log(`\tMaking user "${inputUser.userName}"...`)
      user = new User({anonymous:false})
      user.set('testGroupNumber', Math.floor(Math.random() * 256))
      user.set('name', inputUser.userName)
      user.set('password', inputUser.password)
      yield user.save()
    }

    // Add user to classroom and CS1
    if(!classroom.isMember(user._id)) {
      console.log(`\tAdding "${inputUser.userName}" to "${inputUser.classroomName}"...`)
      yield user.update({$set: {role: 'student'}})
      yield classroom.update({ $push: { members : user._id }})
      yield CourseInstance.update({_id: courseInstance._id}, { $addToSet: { members: user._id }})
      yield user.update({ $addToSet: { courseInstances: { $each: [courseInstance._id] } } })
    }
  }

})
.then(() => {
  console.log('Done')
  process.exit()
})
.catch((e) => {
  console.log(e.stack)
  process.exit()
})
