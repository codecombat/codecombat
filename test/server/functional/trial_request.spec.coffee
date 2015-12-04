require '../common'

describe 'Trial Requests', ->
  URL = getURL('/db/trial.request')
  ownURL = getURL('/db/trial.request/-/own')

  createTrialRequest = (user, type, properties, done) ->
    requestBody =
      type: type
      properties: properties
    request.post {uri: URL, json: requestBody }, (err, res, body) ->
      expect(err).toBeNull()
      expect(res.statusCode).toBe(200)
      expect(body.type).toEqual(type)
      expect(body.properties).toEqual(properties)
      expect(body.applicant).toEqual(user.id)
      expect(body.status).toEqual('submitted')
      TrialRequest.findById body._id, (err, doc) ->
        expect(err).toBeNull()
        expect(doc.get('type')).toEqual(type)
        expect(doc.get('properties')).toEqual(properties)
        expect(doc.get('applicant')).toEqual(user._id)
        expect(doc.get('status')).toEqual('submitted')
        done(doc)

  it 'Clear database', (done) ->
    clearModels [User, TrialRequest], (err) ->
      throw err if err
      done()

  it 'Create trial request', (done) ->
    loginNewUser (user) ->
      properties =
        email: user.get('email')
        location: 'SF, CA'
        age: '14-17'
        numStudents: 14
        heardAbout: 'magical interwebs'
      createTrialRequest user, 'subscription', properties, (trialRequest) ->
        done()

  it 'Get trial requests, non-admin', (done) ->
    loginNewUser (user) ->
      properties =
        email: user.get('email')
        location: 'SF, CA'
        age: '14-17'
        numStudents: 14
        heardAbout: 'magical interwebs'
      createTrialRequest user, 'subscription', properties, (trialRequest) ->
        request.get URL, (err, res, body) ->
          expect(res.statusCode).toEqual(403)
          done()

  it 'Get trial requests, admin', (done) ->
    loginNewUser (user) ->
      properties =
        email: user.get('email')
        location: 'SF, CA'
        age: '14-17'
        numStudents: 14
        heardAbout: 'magical interwebs'
      createTrialRequest user, 'subscription', properties, (trialRequest) ->
        loginNewUser (admin) ->
          admin.set('permissions', ['admin'])
          admin.save (err, user) ->
            request.get URL, (err, res, body) ->
              expect(res.statusCode).toEqual(200)
              expect(body.length).toBeGreaterThan(0)
              done()

  it 'Get own trial requests', (done) ->
    loginNewUser (user) ->
      properties =
        email: user.get('email')
        location: 'SF, CA'
        age: '14-17'
        numStudents: 14
        heardAbout: 'magical interwebs'
      createTrialRequest user, 'subscription', properties, (trialRequest) ->
        request.get ownURL, (err, res, body) ->
          expect(res.statusCode).toEqual(200)
          ownRequests = JSON.parse(body)
          expect(ownRequests.length).toEqual(1)
          expect(ownRequests[0]._id).toEqual(trialRequest.id)
          done()

  it 'Get non-owned trial request, non-admin', (done) ->
    loginNewUser (user) ->
      properties =
        email: user.get('email')
        location: 'SF, CA'
        age: '14-17'
        numStudents: 14
        heardAbout: 'magical interwebs'
      createTrialRequest user, 'subscription', properties, (trialRequest) ->
        loginNewUser (user2) ->
          request.get URL + "/#{trialRequest.id}", (err, res, body) ->
            expect(res.statusCode).toEqual(403)
            done()

  it 'Approve trial request', (done) ->
    loginNewUser (user) ->
      properties =
        email: user.get('email')
        location: 'SF, CA'
        age: '14-17'
        numStudents: 14
        heardAbout: 'magical interwebs'
      createTrialRequest user, 'subscription', properties, (trialRequest) ->
        loginNewUser (admin) ->
          admin.set('permissions', ['admin'])
          admin.save (err, admin) ->
            requestBody = trialRequest.toObject()
            requestBody.status = 'approved'
            request.put {uri: URL, json: requestBody }, (err, res, body) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(200)
              expect(body.status).toEqual('approved')
              expect(body.reviewDate).toBeDefined()
              expect(new Date(body.reviewDate)).toBeLessThan(new Date())
              expect(body.reviewer).toEqual(admin.id)
              TrialRequest.findById body._id, (err, doc) ->
                expect(err).toBeNull()
                expect(doc.get('status')).toEqual('approved')
                expect(doc.get('reviewDate')).toBeDefined()
                expect(new Date(doc.get('reviewDate'))).toBeLessThan(new Date())
                expect(doc.get('reviewer')).toEqual(admin._id)
                Prepaid.find {'properties.trialRequestID': doc.get('_id')}, (err, prepaids) ->
                  expect(err).toBeNull()
                  return done(err) if err
                  expect(prepaids.length).toEqual(2)
                  for prepaid in prepaids
                    expect(prepaid.get('type')).toEqual('course')
                    expect(prepaid.get('creator')).toEqual(user.get('_id'))
                    if prepaid.get('properties').endDate
                      expect(prepaid.get('maxRedeemers')).toEqual(500)
                      expect(prepaid.get('properties').endDate).toBeGreaterThan(new Date())
                    else
                      expect(prepaid.get('maxRedeemers')).toEqual(2)
                  done()

  it 'Deny trial request', (done) ->
    loginNewUser (user) ->
      properties =
        email: user.get('email')
        location: 'SF, CA'
        age: '14-17'
        numStudents: 14
        heardAbout: 'magical interwebs'
      createTrialRequest user, 'subscription', properties, (trialRequest) ->
        loginNewUser (admin) ->
          admin.set('permissions', ['admin'])
          admin.save (err, user) ->
            requestBody = trialRequest.toObject()
            requestBody.status = 'denied'
            request.put {uri: URL, json: requestBody }, (err, res, body) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(200)
              expect(body.status).toEqual('denied')
              expect(body.reviewDate).toBeDefined()
              expect(new Date(body.reviewDate)).toBeLessThan(new Date())
              expect(body.reviewer).toEqual(admin.id)
              expect(body.prepaidCode).not.toBeDefined()
              TrialRequest.findById body._id, (err, doc) ->
                expect(err).toBeNull()
                expect(doc.get('status')).toEqual('denied')
                expect(doc.get('reviewDate')).toBeDefined()
                expect(new Date(doc.get('reviewDate'))).toBeLessThan(new Date())
                expect(doc.get('reviewer')).toEqual(admin._id)
                expect(doc.get('prepaidCode')).not.toBeDefined()
                done()
