utils = require '../utils'
Prepaid = require '../../../server/models/Prepaid'
Course = require '../../../server/models/Course'
CourseInstance = require '../../../server/models/CourseInstance'
User = require '../../../server/models/User'
moment = require 'moment'

describe 'POST /db/prepaid/:handle/redeemers', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Course, CourseInstance, Prepaid, User])
    @teacher = yield utils.initUser({role: 'teacher'})
    @admin = yield utils.initAdmin()
    yield utils.loginUser(@admin)
    @prepaid = yield utils.makePrepaid({ creator: @teacher.id })
    yield utils.loginUser(@teacher)
    @student = yield utils.initUser()
    @url = getURL("/db/prepaid/#{@prepaid.id}/redeemers")
    done()

  describe '.canReplaceUserPrepaid', ->
    beforeEach utils.wrap (done) ->
      yield utils.clearModels([Prepaid])
      yield utils.loginUser(@admin)
      @starter = yield utils.makePrepaid({
        creator: @teacher.id
        startDate: moment().subtract(2, 'month').toISOString()
        endDate: moment().add(4, 'month').toISOString()
        type: 'starter_license'
      })
      @course = yield utils.makePrepaid({
        creator: @teacher.id
        startDate: moment().subtract(2, 'month').toISOString()
        endDate: moment().add(10, 'month').toISOString()
        type: 'course'
      })
      @courseExpired = yield utils.makePrepaid({
        creator: @teacher.id
        startDate: moment().subtract(16, 'month').toISOString()
        endDate: moment().subtract(4, 'month').toISOString()
        type: 'course'
      })
      done()

    describe 'when the user has a starter license,', ->
      describe 'and we are assigning a full license', ->
        it 'returns true', ->
          expect(@course.canReplaceUserPrepaid(@starter)).toBe(true)

      describe 'and we are assigning a starter license', ->
        it 'returns false', ->
          expect(@starter.canReplaceUserPrepaid(@starter)).toBe(false)

    describe 'when the user has a full license,', ->
      describe 'that is NOT expired,', ->
        describe 'and we are assigning a full license', ->
          it 'returns false', ->
            expect(@course.canReplaceUserPrepaid(@course)).toBe(false)
            expect(@course.canReplaceUserPrepaid(@course.toObject())).toBe(false)

        describe 'and we are assigning a starter license', ->
          it 'returns false', ->
            expect(@starter.canReplaceUserPrepaid(@course)).toBe(false)

      describe 'that is expired,', ->
        describe 'and we are assigning a full license', ->
          it 'returns true', ->
            expect(@course.canReplaceUserPrepaid(@courseExpired)).toBe(true)

        describe 'and we are assigning a starter license', ->
          it 'returns true', ->
            expect(@starter.canReplaceUserPrepaid(@courseExpired)).toBe(true)

    describe 'when the user has no license', ->
      it 'returns true', ->
        expect(@course.canReplaceUserPrepaid(undefined)).toBe(true)
        expect(@starter.canReplaceUserPrepaid(undefined)).toBe(true)
