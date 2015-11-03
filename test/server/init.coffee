
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

      
module.exports.classroom = (properties) ->
  properties = {}
  _.defaults(properties, {
    name: 'Unnamed classroom'
  })
  
  return (done) ->
    test = @
    classroom = new Classroom(properties)
    classroom.save (err, classroom) ->
      expect(err).toBeNull()
      test.classroom = classroom
      done()
    