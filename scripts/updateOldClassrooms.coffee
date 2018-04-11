# Update classrooms created on or after August 1st 2017

# Assumes classrooms with any course versioned level assessment property does not need to be updated further

# TODO: test on a few more old test classrooms

if process.argv.length is 6
  # Usage codecombat/scripts$ coffee updateOldClassrooms.coffee <host> <port> <username> <password>
  process.env.COCO_MONGO_HOST = process.argv[2]
  process.env.COCO_MONGO_PORT = process.argv[3]
  process.env.COCO_MONGO_USERNAME = process.argv[4]
  process.env.COCO_MONGO_PASSWORD = process.argv[5]

### SET UP ###
do (setupLodash = this) ->
  global._ = require('lodash')
  _.str = require('underscore.string')
  _.mixin _.str.exports()
  global.tv4 = require('tv4').tv4

co = require('co')
mongoose = require('mongoose')
Promise = require('bluebird');

Classroom = require('../server/models/Classroom')
database = require('../server/commons/database')

database.connect()

# ObjectId for 8/1/17
startDateObjectId = mongoose.Types.ObjectId("598026f00000000000000000")
endDateObjectId = mongoose.Types.ObjectId('5aaf752d0000000000000000')

batchSize = 20

co(->
  todo = yield Classroom.count({_id: {$gt: startDateObjectId}})
  total = todo
  
  while true
    classrooms = yield Classroom.find({_id: {$gt: startDateObjectId}})
      .limit(batchSize)
      .sort({_id:1})
    break unless classrooms.length > 0
    classroomUpdates = classrooms.map (classroom) ->
      Promise.resolve co ->
        yield classroom.setUpdatedCourses({isAdmin: false, addNewCoursesOnly: false, includeAssessments: true})
        database.validateDoc(classroom)
        classroom = yield classroom.save()
        console.log("#{new Date().toISOString().substring(0, 10)} Updated classroom #{classroom.id} #{classroom.get('name')}")
    res = yield classroomUpdates
    console.log("#{new Date().toISOString().substring(0, 10)} #{res.length} classrooms updated.")
    todo -= res.length
    startDateObjectId = _.last(classrooms)._id
    console.log('todo', todo, '/', total, new Date(), '\t\tstart:', startDateObjectId+'', startDateObjectId.getTimestamp())
    # TEMP

).then(->
  process.exit()
).catch((e) ->
  console.log('Error: ')
  console.log(JSON.stringify(e, null, 2))
  process.exit()
)
