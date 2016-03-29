errors = require '../commons/errors'
wrap = require 'co-express'
Promise = require 'bluebird'
database = require '../commons/database'
mongoose = require 'mongoose'
TrialRequest = require '../models/TrialRequest'
CourseInstance = require '../models/CourseInstance'
Classroom = require '../models/Classroom'
Course = require '../models/Course'
User = require '../models/User'

module.exports =
  addMembers: wrap (req, res) ->
    if req.body.userID
      userIDs = [req.body.userID]
    else if req.body.userIDs
      userIDs = req.body.userIDs
    else
      throw new errors.UnprocessableEntity('Must provide userID or userIDs')
    
    for userID in userIDs
      unless _.all userIDs, database.isID
        throw new errors.UnprocessableEntity('Invalid list of user IDs')
      
    courseInstance = yield database.getDocFromHandle(req, CourseInstance)
    if not courseInstance
      throw new errors.NotFound('Course Instance not found.')
      
    classroom = yield Classroom.findById courseInstance.get('classroomID')
    if not classroom
      throw new errors.NotFound('Classroom not found.')
    
    classroomMembers = (userID.toString() for userID in classroom.get('members'))
    unless _.all(userIDs, (userID) -> _.contains classroomMembers, userID)
      throw new errors.Forbidden('Users must be members of classroom')
      
    unless classroom.get('ownerID').equals(req.user._id)
      throw new errors.Forbidden('You must own the classroom to add members')
      
    # Only the enrolled users
    users = yield User.find({ _id: { $in: userIDs }}).select('coursePrepaidID')
    usersArePrepaid = _.all((user.get('coursePrepaidID') for user in users))
    
    course = yield Course.findById courseInstance.get('courseID')
    throw new errors.NotFound('Course referenced by course instance not found') unless course
    
    if not (course.get('free') or usersArePrepaid)
      throw new errors.PaymentRequired('Cannot add users to a course instance until they are added to a prepaid')
    
    userObjectIDs = (mongoose.Types.ObjectId(userID) for userID in userIDs)
    
    courseInstance = yield CourseInstance.findByIdAndUpdate(
      courseInstance._id,
      { $addToSet: { members: { $each: userObjectIDs } } }
      { new: true }
    )
    
    userUpdateResult = yield User.update(
      { _id: { $in: userObjectIDs } },
      { $addToSet: { courseInstances: courseInstance._id } }
    )
    
    res.status(200).send(courseInstance.toObject({ req }))
