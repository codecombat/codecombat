utils = require '../utils'
sendwithus = require '../../../server/sendwithus'
request = require '../request'
User = require '../../../server/models/User'

# TODO: need to update this test since /contact calls external Close.io API now
#xdescribe 'POST /contact', ->
#  
#  beforeEach utils.wrap (done) ->
#    spyOn(sendwithus.api, 'send')
#    @teacher = yield utils.initUser({role: 'teacher'})
#    yield utils.loginUser(@teacher)
#    done()
#  
#  describe 'when recipientID is "schools@codecombat.com"', ->
#    it 'sends to that email', utils.wrap (done) ->
#      [res, body] = yield request.postAsync({url: getURL('/contact'), json: {
#        sender: 'some@email.com'
#        message: 'A message'
#        recipientID: 'schools@codecombat.com'
#      }})
#      expect(sendwithus.api.send).toHaveBeenCalled()
#      user = yield User.findById(@teacher.id)
#      yield new Promise((resolve) -> setTimeout(resolve, 10))
#      expect(user.get('enrollmentRequestSent')).toBe(true)
#      done()
