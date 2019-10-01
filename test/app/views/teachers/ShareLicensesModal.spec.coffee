ShareLicensesModal = require 'views/teachers/ShareLicensesModal'
ShareLicensesStoreModule = require 'views/teachers/ShareLicensesStoreModule'
factories = require '../../factories'
api = require 'core/api'

describe 'ShareLicensesModal', ->
  afterEach ->
    @modal?.destroy?() unless @modal?.destroyed
  
  describe 'joiner list', ->
    beforeEach (done) ->
      window.me = @teacher = factories.makeUser({firstName: 'teacher', lastName: 'one'})
      @joiner1 = factories.makeUser({firstName: 'joiner', lastName: 'one'})
      @joiner2 = factories.makeUser({firstName: 'joiner', lastName: 'two'})
      @prepaid = factories.makePrepaid({ joiners: [{ userID: @joiner1.id }, { userID: @joiner2.id }] })
      spyOn(api.prepaids, 'fetchJoiners').and.returnValue Promise.resolve([
          _.pick(@joiner1.attributes, '_id', 'name', 'email', 'firstName', 'lastName')
          _.pick(@joiner2.attributes, '_id', 'name', 'email', 'firstName', 'lastName')
        ])
      @modal = new ShareLicensesModal({ prepaid: @prepaid })
      @modal.render()
      @store = @modal.shareLicensesComponent.$store
      # TODO How do I wait for VueX to finish updating?
      _.defer ->
        done()
    
    # xit 'shows a list of joiners in reverse order', ->
    #   joiners = @modal.shareLicensesComponent.prepaid.joiners
    #   expect(joiners[0]?.firstName).toBe('teacher')
    #   expect(joiners[0]?.lastName).toBe('one')
    #   expect(joiners[0]?.email).toBe(@teacher.get('email'))
    #   expect(joiners[1]?.firstName).toBe('joiner')
    #   expect(joiners[1]?.lastName).toBe('two')
    #   expect(joiners[1]?.email).toBe(@joiner2.get('email'))
    #   expect(joiners[2]?.firstName).toBe('joiner')
    #   expect(joiners[2]?.lastName).toBe('one')
    #   expect(joiners[2]?.email).toBe(@joiner1.get('email'))
      
    describe 'Add Teacher button', ->
      beforeEach (done) ->
        @joiner3 = factories.makeUser({firstName: 'joiner', lastName: 'three'})
        spyOn(api.prepaids, 'addJoiner').and.returnValue Promise.resolve(@prepaid.toJSON())
        spyOn(api.users, 'getByEmail').and.returnValue Promise.resolve(_.pick(@joiner3.toJSON(), ['_id', 'name', 'email', 'firstName', 'lastName']))
        _.defer ->
          done()
        
      it 'can add a joiner', (done) ->
        @modal.shareLicensesComponent.teacherSearchInput = @joiner3.get('email')
        @modal.shareLicensesComponent.addTeacher().then =>
          joiners = @modal.shareLicensesComponent.prepaid.joiners
          expect(joiners[1].firstName).toBe('joiner')
          expect(joiners[1].lastName).toBe('three')
          expect(joiners[1].email).toBe(@joiner3.get('email'))
          done()

describe 'ShareLicensesStoreModule', ->
  beforeEach (done) ->
    window.me = @teacher = factories.makeUser({firstName: 'teacher', lastName: 'one'})
    @joiner1 = factories.makeUser({firstName: 'joiner', lastName: 'one'})
    @joiner2 = factories.makeUser({firstName: 'joiner', lastName: 'two'})
    @prepaid = factories.makePrepaid({ joiners: [{ userID: @joiner1.id }, { userID: @joiner2.id }] })
    @store = require('core/store')
    @store.registerModule('modal', ShareLicensesStoreModule)
    @store.commit('modal/clearData')
    spyOn(api.prepaids, 'fetchJoiners').and.returnValue Promise.resolve([
        _.pick(@joiner1.attributes, '_id', 'name', 'email', 'firstName', 'lastName')
        _.pick(@joiner2.attributes, '_id', 'name', 'email', 'firstName', 'lastName')
      ])
    spyOn(@store, 'commit').and.stub()
    done()
  
  describe 'setJoiners', ->
    it 'fetches and attaches joiner information', (done) ->
      @store.dispatch('modal/setPrepaid', @prepaid.attributes)
      .then =>
        expect(api.prepaids.fetchJoiners).toHaveBeenCalled()
        expect(ShareLicensesStoreModule.state.error).toBe('')
        expect(@store.commit).toHaveBeenCalled()
        storedPrepaid = @store.commit.calls.argsFor(0)[1]
        expect(storedPrepaid._id).toEqual(@prepaid.attributes._id)
        expect(storedPrepaid.joiners[0]).toDeepEqual(_.assign({}, _.pick(@joiner1.attributes, 'firstName', 'lastName', 'name', 'email', '_id'), {userID: @joiner1.get('_id')}))
        expect(storedPrepaid.joiners[1]).toDeepEqual(_.assign({}, _.pick(@joiner2.attributes, 'firstName', 'lastName', 'name', 'email', '_id'), {userID: @joiner2.get('_id')}))
        done()
