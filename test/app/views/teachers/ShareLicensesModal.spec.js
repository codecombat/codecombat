/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const ShareLicensesModal = require('views/teachers/ShareLicensesModal');
const ShareLicensesStoreModule = require('views/teachers/ShareLicensesStoreModule');
const factories = require('../../factories');
const api = require('core/api');

describe('ShareLicensesModal', function() {
  afterEach(function() {
    if (!(this.modal != null ? this.modal.destroyed : undefined)) { return __guardMethod__(this.modal, 'destroy', o => o.destroy()); }
  });
  
  return describe('joiner list', function() {
    beforeEach(function(done) {
      window.me = (this.teacher = factories.makeUser({firstName: 'teacher', lastName: 'one'}));
      this.joiner1 = factories.makeUser({firstName: 'joiner', lastName: 'one'});
      this.joiner2 = factories.makeUser({firstName: 'joiner', lastName: 'two'});
      this.prepaid = factories.makePrepaid({ joiners: [{ userID: this.joiner1.id }, { userID: this.joiner2.id }] });
      spyOn(api.prepaids, 'fetchJoiners').and.returnValue(Promise.resolve([
          _.pick(this.joiner1.attributes, '_id', 'name', 'email', 'firstName', 'lastName'),
          _.pick(this.joiner2.attributes, '_id', 'name', 'email', 'firstName', 'lastName')
        ])
      );
      this.modal = new ShareLicensesModal({ prepaid: this.prepaid });
      this.modal.render();
      this.store = this.modal.shareLicensesComponent.$store;
      // TODO How do I wait for VueX to finish updating?
      return _.defer(() => done());
    });
    
    // xit 'shows a list of joiners in reverse order', ->
    //   joiners = @modal.shareLicensesComponent.prepaid.joiners
    //   expect(joiners[0]?.firstName).toBe('teacher')
    //   expect(joiners[0]?.lastName).toBe('one')
    //   expect(joiners[0]?.email).toBe(@teacher.get('email'))
    //   expect(joiners[1]?.firstName).toBe('joiner')
    //   expect(joiners[1]?.lastName).toBe('two')
    //   expect(joiners[1]?.email).toBe(@joiner2.get('email'))
    //   expect(joiners[2]?.firstName).toBe('joiner')
    //   expect(joiners[2]?.lastName).toBe('one')
    //   expect(joiners[2]?.email).toBe(@joiner1.get('email'))
      
    return describe('Add Teacher button', function() {
      beforeEach(function(done) {
        this.joiner3 = factories.makeUser({firstName: 'joiner', lastName: 'three'});
        spyOn(api.prepaids, 'addJoiner').and.returnValue(Promise.resolve(this.prepaid.toJSON()));
        spyOn(api.users, 'getByEmail').and.returnValue(Promise.resolve(_.pick(this.joiner3.toJSON(), ['_id', 'name', 'email', 'firstName', 'lastName'])));
        return _.defer(() => done());
      });
        
      return it('can add a joiner', function(done) {
        this.modal.shareLicensesComponent.teacherSearchInput = this.joiner3.get('email');
        return this.modal.shareLicensesComponent.addTeacher().then(() => {
          const {
            joiners
          } = this.modal.shareLicensesComponent.prepaid;
          expect(joiners[1].firstName).toBe('joiner');
          expect(joiners[1].lastName).toBe('three');
          expect(joiners[1].email).toBe(this.joiner3.get('email'));
          return done();
        });
      });
    });
  });
});

describe('ShareLicensesStoreModule', function() {
  beforeEach(function(done) {
    window.me = (this.teacher = factories.makeUser({firstName: 'teacher', lastName: 'one'}));
    this.joiner1 = factories.makeUser({firstName: 'joiner', lastName: 'one'});
    this.joiner2 = factories.makeUser({firstName: 'joiner', lastName: 'two'});
    this.prepaid = factories.makePrepaid({ joiners: [{ userID: this.joiner1.id }, { userID: this.joiner2.id }] });
    this.store = require('core/store');
    this.store.registerModule('modal', ShareLicensesStoreModule);
    this.store.commit('modal/clearData');
    spyOn(api.prepaids, 'fetchJoiners').and.returnValue(Promise.resolve([
        _.pick(this.joiner1.attributes, '_id', 'name', 'email', 'firstName', 'lastName'),
        _.pick(this.joiner2.attributes, '_id', 'name', 'email', 'firstName', 'lastName')
      ])
    );
    spyOn(this.store, 'commit').and.stub();
    return done();
  });
  
  return describe('setJoiners', () => it('fetches and attaches joiner information', function(done) {
    return this.store.dispatch('modal/setPrepaid', this.prepaid.attributes)
    .then(() => {
      expect(api.prepaids.fetchJoiners).toHaveBeenCalled();
      expect(ShareLicensesStoreModule.state.error).toBe('');
      expect(this.store.commit).toHaveBeenCalled();
      const storedPrepaid = this.store.commit.calls.argsFor(0)[1];
      expect(storedPrepaid._id).toEqual(this.prepaid.attributes._id);
      expect(storedPrepaid.joiners[0]).toDeepEqual(_.assign({}, _.pick(this.joiner1.attributes, 'firstName', 'lastName', 'name', 'email', '_id'), {userID: this.joiner1.get('_id')}));
      expect(storedPrepaid.joiners[1]).toDeepEqual(_.assign({}, _.pick(this.joiner2.attributes, 'firstName', 'lastName', 'name', 'email', '_id'), {userID: this.joiner2.get('_id')}));
      return done();
    });
  }));
});

function __guardMethod__(obj, methodName, transform) {
  if (typeof obj !== 'undefined' && obj !== null && typeof obj[methodName] === 'function') {
    return transform(obj, methodName);
  } else {
    return undefined;
  }
}