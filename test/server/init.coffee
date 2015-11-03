
module.exports.course = (properties) ->
  properties ?= {}
  _.defaults(properties, {
    name: 'Unnamed course'
    campaignID: ObjectId("55b29efd1cd6abe8ce07db0d")
    concepts: ['basic_syntax', 'arguments', 'while_loops', 'strings', 'variables']
    description: "Learn basic syntax, while loops, and the CodeCombat environment."
    screenshot: "/images/pages/courses/101_info.png"
  })
  
  return (done) ->
    test = @
    course = new Course(properties)
    course.save (err, course) ->
      expect(err).toBeNull()
      test.course = course
      done()

      
module.exports.classroom = (givenProperties) ->
  return (done) ->
    properties = _.defaults({}, givenProperties, {
      name: 'Unnamed classroom'
    })
    test = @
    url = getURL('/db/classroom')
    request.post {uri: url, json: properties}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      Classroom.findById body._id, (err, classroom) ->
        expect(err).toBeNull()
        expect(classroom).toBeTruthy()
        test.classroom = classroom
        done()
        
        
module.exports.courseInstance = (givenProperties) ->
  return (done) ->
    properties = _.defaults({}, givenProperties, {
      name: 'Unnamed course instance'
    })
    test = @
    url = getURL('/db/course_instance')
    properties.courseID ?= test.course.id
    properties.classroomID ?= test.classroom.id
    request.post {uri: url, json: properties}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      CourseInstance.findById body._id, (err, courseInstance) ->
        expect(err).toBeNull()
        expect(courseInstance).toBeTruthy()
        test.courseInstance = courseInstance
        done()
        
        
module.exports.user = (givenOptions) ->
  return (done) ->
    options = _.defaults({}, givenOptions, {
      setTo: 'user',
      properties: {
        name: 'User'+_.uniqueId()
      }
    })
    test = @
    user = new User(options.properties)
    user.save (err, user) ->
      expect(err).toBeNull()
      test[options.setTo] = user
      done()
      
      
module.exports.prepaid = (givenOptions) ->
  return (done) ->
    options = _.defaults({}, givenOptions, {
      setTo: 'prepaid',
      properties: {
        type: 'course'
        maxRedeemers: 10
        redeemers: []
      }
    })
    test = @
    prepaid = new Prepaid(options.properties)
    prepaid.save (err, prepaid) ->
      expect(err).toBeNull()
      test[options.setTo] = prepaid
      done()