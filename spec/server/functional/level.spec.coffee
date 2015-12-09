require '../common'

describe 'Level', ->

  level =
    name: 'King\'s Peak 3'
    description: 'Climb a mountain.'
    permissions: simplePermissions
    scripts: []
    thangs: []
    documentation: {specificArticles: [], generalArticles: []}

  urlLevel = '/db/level'

  it 'clears things first', (done) ->
    clearModels [Level], (err) ->
      expect(err).toBeNull()
      done()

  it 'can make a Level.', (done) ->
    loginJoe ->
      request.post {uri: getURL(urlLevel), json: level}, (err, res, body) ->
        expect(res.statusCode).toBe(200)
        done()

  it 'get schema', (done) ->
    request.get {uri: getURL(urlLevel+'/schema')}, (err, res, body) ->
      expect(res.statusCode).toBe(200)
      body = JSON.parse(body)
      expect(body.type).toBeDefined()
      done()


describe 'GET /db/level/<id>/session', ->

  describe 'when level is a course level', ->

    levelID = null

    it 'sets up a course instance', (done) ->

      clearModels [Campaign, Course, CourseInstance, Level, User], (err) ->

        loginAdmin (admin) ->

          url = getURL('/db/level')
          body =
            name: 'Course Level'
            type: 'course'
            permissions: simplePermissions

          request.post {uri: url, json: body }, (err, res, level) ->
            levelID = level._id

            url = getURL('/db/campaign')
            body =
              name: 'Course Campaign'
              levels: {}
            body.levels[level.original] = { 'original': level.original }

            request.post { uri: url, json: body }, (err, res, campaign) ->

              course = new Course({
                name: 'Test Course'
                campaignID: ObjectId(campaign._id)
              })

              course.save (err) ->

                expect(err).toBeNull()
                
                loginJoe (joe) ->

                  classroom = new Classroom({
                    name: 'Test Classroom'
                    members: [ joe.get('_id') ]
                    aceConfig: { language: 'javascript' }
                  })

                  classroom.save (err, classroom) ->
                    
                    expect(err).toBeNull()

                    courseInstance = new CourseInstance({
                      name: 'Course Instance'
                      members: [
                        joe.get('_id')
                      ]
                      courseID: ObjectId(course.id)
                      classroomID: ObjectId(classroom.id)
                    })
  
                    courseInstance.save (err) ->
  
                      expect(err).toBeNull()
                      done()

    it 'creates a new session if the user is in a course with that level', (done) ->
      loginJoe (joe) ->

        url = getURL("/db/level/#{levelID}/session")

        request.get { uri: url, json: true }, (err, res, body) ->
          expect(res.statusCode).toBe(200)
          expect(body.codeLanguage).toBe('javascript')
          done()

    it 'does not create a new session if the user is not in a course with that level', (done) ->
      loginSam (sam) ->

        url = getURL("/db/level/#{levelID}/session")

        request.get { uri: url }, (err, res, body) ->
          expect(res.statusCode).toBe(402)
          done()
