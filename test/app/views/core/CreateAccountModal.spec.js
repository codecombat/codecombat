/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const CreateAccountModal = require('views/core/CreateAccountModal');
const Classroom = require('models/Classroom');
//COPPADenyModal = require 'views/core/COPPADenyModal'
const forms = require('core/forms');
const factories = require('test/app/factories');

const SchoolInfoPanel = Vue.extend(require('views/core/CreateAccountModal/teacher/SchoolInfoPanel'));
const TeacherSignupStoreModule = require('views/core/CreateAccountModal/teacher/TeacherSignupStoreModule');

// TODO: Figure out why these tests break Travis. Suspect it has to do with the
// asynchronous, Promise system. On the browser, these work, but in Travis, they
// sometimes fail, so it's some sort of race condition.

const responses = {
  signupSuccess: { status: 200, responseText: JSON.stringify({ email: 'some@email.com' })}
};


xdescribe('CreateAccountModal', function() {

  let modal = null;

//  initModal = (options) -> ->
//    application.facebookHandler.fakeAPI()
//    application.gplusHandler.fakeAPI()
//    modal = new CreateAccountModal(options)
//    jasmine.demoModal(modal)

  describe('click SIGN IN button', () => it('switches to AuthModal', function() {
    modal = new CreateAccountModal();
    modal.render();
    jasmine.demoModal(modal);
    spyOn(modal, 'openModalView');
    modal.$('.login-link').click();
    return expect(modal.openModalView).toHaveBeenCalled();
  }));

  describe('ChooseAccountTypeView', function() {
    beforeEach(function() {
      modal = new CreateAccountModal();
      modal.render();
      return jasmine.demoModal(modal);
    });

    describe('click sign up as TEACHER button', function() {
      beforeEach(function() {
        spyOn(application.router, 'navigate');
        return modal.$('.teacher-path-button').click();
      });

      return it('switches to BasicInfoView and sets "path" to "teacher"', function() {
        expect(modal.signupState.get('path')).toBe('teacher');
        return expect(modal.signupState.get('screen')).toBe('basic-info');
      });
    });

    describe('click sign up as STUDENT button', function() {
      beforeEach(() => modal.$('.student-path-button').click());

      return it('switches to SegmentCheckView and sets "path" to "student"', function() {
        expect(modal.signupState.get('path')).toBe('student');
        return expect(modal.signupState.get('screen')).toBe('segment-check');
      });
    });

    return describe('click sign up as INDIVIDUAL button', function() {
      beforeEach(() => modal.$('.individual-path-button').click());

      return it('switches to SegmentCheckView and sets "path" to "individual"', function() {
        expect(modal.signupState.get('path')).toBe('individual');
        return expect(modal.signupState.get('screen')).toBe('segment-check');
      });
    });
  });

  describe('SegmentCheckView', function() {

    let segmentCheckView = null;

    describe('INDIVIDUAL path', function() {
      beforeEach(function(done) {
        modal = new CreateAccountModal();
        modal.render();
        jasmine.demoModal(modal);
        modal.$('.individual-path-button').click();
        segmentCheckView = modal.subviews.segment_check_view;
        return _.defer(done);
      });

      return it('has a birthdate form', () => expect(modal.$('.birthday-form-group').length).toBe(1));
    });

    return describe('STUDENT path', function() {
      beforeEach(function(done) {
        modal = new CreateAccountModal();
        modal.render();
        jasmine.demoModal(modal);
        modal.$('.student-path-button').click();
        segmentCheckView = modal.subviews.segment_check_view;
        spyOn(segmentCheckView, 'checkClassCodeDebounced');
        return _.defer(done);
      });

      it('has a classCode input', () => expect(modal.$('.class-code-input').length).toBe(1));

      it('checks the class code when the input changes', function() {
        modal.$('.class-code-input').val('test').trigger('input');
        return expect(segmentCheckView.checkClassCodeDebounced).toHaveBeenCalled();
      });

      describe('fetchClassByCode()', () => it('is memoized', function() {
        const promise1 = segmentCheckView.fetchClassByCode('testA');
        const promise2 = segmentCheckView.fetchClassByCode('testA');
        const promise3 = segmentCheckView.fetchClassByCode('testB');
        expect(promise1).toBe(promise2);
        return expect(promise1).not.toBe(promise3);
      }));

      describe('checkClassCode()', () => it('shows a success message if the classCode is found', function() {
        let request = jasmine.Ajax.requests.mostRecent();
        expect(_.string.startsWith(request.url, '/db/classroom')).toBe(false);
        modal.$('.class-code-input').val('test').trigger('input');
        segmentCheckView.checkClassCode();
        request = jasmine.Ajax.requests.mostRecent();
        expect(_.string.startsWith(request.url, '/db/classroom')).toBe(true);
        return request.respondWith({
          status: 200,
          responseText: JSON.stringify({
            data: factories.makeClassroom({name: 'Some Classroom'}).toJSON(),
            owner: factories.makeUser({name: 'Some Teacher'}).toJSON()
          })
        });
      }));

      return describe('on submit with class code', function() {

        let classCodeRequest = null;

        beforeEach(function() {
          const request = jasmine.Ajax.requests.mostRecent();
          expect(_.string.startsWith(request.url, '/db/classroom')).toBe(false);
          modal.$('.class-code-input').val('test').trigger('input');
          modal.$('form.segment-check').submit();
          classCodeRequest = jasmine.Ajax.requests.mostRecent();
          return expect(_.string.startsWith(classCodeRequest.url, '/db/classroom')).toBe(true);
        });

        describe('when the classroom IS found', function() {
          beforeEach(function(done) {
            classCodeRequest.respondWith({
              status: 200,
              responseText: JSON.stringify({
                data: factories.makeClassroom({name: 'Some Classroom'}).toJSON(),
                owner: factories.makeUser({name: 'Some Teacher'}).toJSON()
              })
            });
            return _.defer(done);
          });

          it('navigates to the BasicInfoView', () => expect(modal.signupState.get('screen')).toBe('basic-info'));

          return describe('on the BasicInfoView for students', function() {});
        });


        return describe('when the classroom IS NOT found', function() {
          beforeEach(function(done) {
            classCodeRequest.respondWith({
              status: 404,
              responseText: '{}'
            });
            return segmentCheckView.once('special-render', done);
          });

          return it('shows an error', () => expect(modal.$('[data-i18n="signup.classroom_not_found"]').length).toBe(1));
        });
      });
    });
  });

  describe('CoppaDenyView', function() {

    let coppaDenyView = null;

    beforeEach(function() {
      modal = new CreateAccountModal();
      modal.signupState.set({
        path: 'individual',
        screen: 'coppa-deny'
      });
      modal.render();
      jasmine.demoModal(modal);
      return coppaDenyView = modal.subviews.coppa_deny_view;
    });

    return it('shows an input for a parent\'s email address to sign up their child', () => expect(modal.$('#parent-email-input').length).toBe(1));
  });


  describe('BasicInfoView', function() {

    let basicInfoView = null;

    beforeEach(function() {
      modal = new CreateAccountModal();
      modal.signupState.set({
        path: 'student',
        screen: 'basic-info'
      });
      modal.render();
      jasmine.demoModal(modal);
      return basicInfoView = modal.subviews.basic_info_view;
    });

    it('checks for name conflicts when the name input changes', function() {
      spyOn(basicInfoView, 'checkName');
      basicInfoView.$('#username-input').val('test').trigger('change');
      return expect(basicInfoView.checkName).toHaveBeenCalled();
    });

    describe('checkEmail()', function() {
      beforeEach(function() {
        basicInfoView.$('input[name="email"]').val('some@email.com');
        return basicInfoView.checkEmail();
      });

      it('shows checking', () => expect(basicInfoView.$('[data-i18n="signup.checking"]').length).toBe(1));

      describe('if email DOES exist', function() {
        beforeEach(function(done) {
          jasmine.Ajax.requests.mostRecent().respondWith({
            status: 200,
            responseText: JSON.stringify({exists: true})
          });
          return _.defer(done);
        });

        return it('says an account already exists and encourages to sign in', function() {
          expect(basicInfoView.$('[data-i18n="signup.account_exists"]').length).toBe(1);
          return expect(basicInfoView.$('.login-link[data-i18n="signup.sign_in"]').length).toBe(1);
        });
      });

      return describe('if email DOES NOT exist', function() {
        beforeEach(function(done) {
          jasmine.Ajax.requests.mostRecent().respondWith({
            status: 200,
            responseText: JSON.stringify({exists: false})
          });
          return _.defer(done);
        });

        return it('says email looks good', () => expect(basicInfoView.$('[data-i18n="signup.email_good"]').length).toBe(1));
      });
    });

    describe('checkName()', function() {
      beforeEach(function() {
        basicInfoView.$('input[name="name"]').val('Some Name').trigger('change');
        return basicInfoView.checkName();
      });

      it('shows checking', () => expect(basicInfoView.$('[data-i18n="signup.checking"]').length).toBe(1));

      // does not work in travis since en.coffee is not included. TODO: Figure out workaround
//      describe 'if name DOES exist', ->
//        beforeEach (done) ->
//          jasmine.Ajax.requests.mostRecent().respondWith({
//            status: 200
//            responseText: JSON.stringify({conflicts: true, suggestedName: 'test123'})
//          })
//          _.defer done
//
//        it 'says name is taken and suggests a different one', ->
//          expect(basicInfoView.$el.text().indexOf('test123') > -1).toBe(true)

      return describe('if email DOES NOT exist', function() {
        beforeEach(function(done) {
          jasmine.Ajax.requests.mostRecent().respondWith({
            status: 200,
            responseText: JSON.stringify({conflicts: false})
          });
          return _.defer(done);
        });

        return it('says name looks good', () => expect(basicInfoView.$('[data-i18n="signup.name_available"]').length).toBe(1));
      });
    });

    return describe('onSubmitForm()', function() {
      it('shows required errors for empty fields when on INDIVIDUAL path', function() {
        modal.signupState.set('path', 'individual');
        basicInfoView.$('input').val('');
        basicInfoView.$('#basic-info-form').submit();
        return expect(basicInfoView.$('.form-group.has-error').length).toBe(3);
      });

      it('shows required errors for empty fields when on STUDENT path', function() {
        modal.signupState.set('path', 'student');
        modal.render();
        basicInfoView.$('#basic-info-form').submit();
        return expect(basicInfoView.$('.form-group.has-error').length).toBe(4);
      }); // includes first and last name, not email

      return describe('submit with password', function() {
        beforeEach(function() {
          forms.objectToForm(basicInfoView.$el, {
            email: 'some@email.com',
            password: 'password',
            name: 'A Username',
            firstName: 'First',
            lastName: 'Last'
          });
          return basicInfoView.$('form').submit();
        });

        it('checks for email and name conflicts', function() {
          const emailCheck = _.find(jasmine.Ajax.requests.all(), r => _.string.startsWith(r.url, '/auth/email'));
          const nameCheck = _.find(jasmine.Ajax.requests.all(), r => _.string.startsWith(r.url, '/auth/name'));
          return expect(_.all([emailCheck, nameCheck])).toBe(true);
        });

        describe('a check does not pass', function() {
          beforeEach(function(done) {
            const nameCheck = _.find(jasmine.Ajax.requests.all(), r => _.string.startsWith(r.url, '/auth/name'));
            nameCheck.respondWith({
              status: 200,
              responseText: JSON.stringify({conflicts: false})
            });
            const emailCheck = _.find(jasmine.Ajax.requests.all(), r => _.string.startsWith(r.url, '/auth/email'));
            emailCheck.respondWith({
              status: 200,
              responseText: JSON.stringify({ exists: true })
            });
            return _.defer(done);
          });

          return it('re-enables the form and shows which field failed', function() {});
        });

        return describe('both checks do pass', function() {
          beforeEach(function(done) {
            const nameCheck = _.find(jasmine.Ajax.requests.all(), r => _.string.startsWith(r.url, '/auth/name'));
            nameCheck.respondWith({
              status: 200,
              responseText: JSON.stringify({conflicts: false})
            });
            const emailCheck = _.find(jasmine.Ajax.requests.all(), r => _.string.startsWith(r.url, '/auth/email'));
            emailCheck.respondWith({
              status: 200,
              responseText: JSON.stringify({ exists: false })
            });
            return _.defer(done);
          });

          it('saves the user', function() {
            const request = jasmine.Ajax.requests.mostRecent();
            expect(_.string.startsWith(request.url, '/db/user')).toBe(true);
            const body = JSON.parse(request.params);
            expect(body.firstName).toBe('First');
            expect(body.lastName).toBe('Last');
            return expect(body.emails.generalNews.enabled).toBe(true);
          });

          describe('saving the user FAILS', function() {
            beforeEach(function(done) {
              const request = jasmine.Ajax.requests.mostRecent();
              request.respondWith({
                status: 422,
                responseText: JSON.stringify({
                  message: 'Some error happened'
                })
              });
              return _.defer(done);
            });

            return it('displays the server error', () => expect(basicInfoView.$('.alert-danger').length).toBe(1));
          });

          return describe('saving the user SUCCEEDS', function() {
            beforeEach(function(done) {
              const request = jasmine.Ajax.requests.mostRecent();
              request.respondWith({
                status: 200,
                responseText: '{}'
              });
              return _.defer(done);
            });

            it('signs the user up with the password', function() {
              const request = jasmine.Ajax.requests.mostRecent();
              return expect(_.string.endsWith(request.url, 'signup-with-password')).toBe(true);
            });

            describe('after signup STUDENT', function() {
              beforeEach(function(done) {
                basicInfoView.signupState.set({
                  path: 'student',
                  classCode: 'ABC',
                  classroom: new Classroom()
                });
                const request = jasmine.Ajax.requests.mostRecent();
                request.respondWith(responses.signupSuccess);
                return _.defer(done);
              });

              return it('joins the classroom', function() {
                const request = jasmine.Ajax.requests.mostRecent();
                return expect(request.url).toBe('/db/classroom/~/members');
              });
            });

            return describe('signing the user up SUCCEEDS', function() {
              beforeEach(function(done) {
                spyOn(basicInfoView, 'finishSignup');
                const request = jasmine.Ajax.requests.mostRecent();
                request.respondWith(responses.signupSuccess);
                return _.defer(done);
              });

              return it('calls finishSignup()', () => expect(basicInfoView.finishSignup).toHaveBeenCalled());
            });
          });
        });
      });
    });
  });

  describe('ConfirmationView', function() {
    let confirmationView = null;

    beforeEach(function() {
      modal = new CreateAccountModal();
      modal.signupState.set('screen', 'confirmation');
      modal.render();
      jasmine.demoModal(modal);
      return confirmationView = modal.subviews.confirmation_view;
    });

    return it('(for demo testing)', function() {
      me.set('name', 'A Sweet New Username');
      me.set('email', 'some@email.com');
      return confirmationView.signupState.set('ssoUsed', 'gplus');
    });
  });

  describe('SingleSignOnConfirmView', function() {
    let singleSignOnConfirmView = null;

    beforeEach(function() {
      modal = new CreateAccountModal();
      modal.signupState.set({
        screen: 'sso-confirm',
        email: 'some@email.com'
      });
      modal.render();
      jasmine.demoModal(modal);
      return singleSignOnConfirmView = modal.subviews.single_sign_on_confirm_view;
    });

    return it('(for demo testing)', function() {
      me.set('name', 'A Sweet New Username');
      me.set('email', 'some@email.com');
      return singleSignOnConfirmView.signupState.set('ssoUsed', 'facebook');
    });
  });

  return describe('CoppaDenyView', function() {
    let coppaDenyView = null;

    beforeEach(function() {
      modal = new CreateAccountModal();
      modal.signupState.set({
        screen: 'coppa-deny'
      });
      modal.render();
      jasmine.demoModal(modal);
      return coppaDenyView = modal.subviews.coppa_deny_view;
    });

    return it('(for demo testing)', function() {});
  });
});

xdescribe('CreateAccountModal Vue Components', () => describe('TeacherSignupComponent', function() {
  beforeEach(function() {
    return this.store = {};});

  describe('SchoolInfoPanel', function() {
    describe('updateValue', function() {
      beforeEach(function() {
        this.store = {
          state: {
            modal: {
              trialRequestProperties: {
                organization: 'suggested school',
                district: 'suggested district',
                nces_id: 'school NCES id',
                nces_district_id: 'district NCES id',
                nces_phone: 'school NCES phone'
              }
            }
          }
        };
        this.schoolInfoPanel = new SchoolInfoPanel({
          store: this.store
        });
        return null;
      });

      describe('when you type into the school field', () => it('clears the school NCES info', function() {
        expect(this.schoolInfoPanel.organization).not.toBe('');
        expect(this.schoolInfoPanel.district).not.toBe('');
        expect(this.schoolInfoPanel.nces_id).not.toBe('');
        expect(this.schoolInfoPanel.nces_phone).not.toBe('');
        expect(this.schoolInfoPanel.nces_district_id).not.toBe('');
        this.schoolInfoPanel.updateValue('organization', 'homeschool');
        expect(this.schoolInfoPanel.organization).toBe('homeschool');
        expect(this.schoolInfoPanel.district).toBe('suggested district');
        expect(this.schoolInfoPanel.nces_id).toBe('');
        expect(this.schoolInfoPanel.nces_phone).toBe('');
        return expect(this.schoolInfoPanel.nces_district_id).toBe('district NCES id');
      }));

      return describe('when you type into the district field', () => it('clears the school and district NCES info', function() {
        expect(this.schoolInfoPanel.organization).not.toBe('');
        expect(this.schoolInfoPanel.district).not.toBe('');
        expect(this.schoolInfoPanel.nces_id).not.toBe('');
        expect(this.schoolInfoPanel.nces_phone).not.toBe('');
        expect(this.schoolInfoPanel.nces_district_id).not.toBe('');
        this.schoolInfoPanel.updateValue('district', 'homedistrict');
        expect(this.schoolInfoPanel.organization).toBe('suggested school');
        expect(this.schoolInfoPanel.district).toBe('homedistrict');
        expect(this.schoolInfoPanel.nces_id).toBe('');
        expect(this.schoolInfoPanel.nces_phone).toBe('');
        return expect(this.schoolInfoPanel.nces_district_id).toBe('');
      }));
    });

    describe('clearDistrictNcesValues', function() {});

    describe('clearSchoolNcesValues', function() {});

    describe('applySuggestion', function() {
      beforeEach(function() {
        this.store = {
          state: {
            modal: {
              trialRequestProperties: {
                organization: 'suggested school',
                district: 'suggested district',
                nces_id: 'school NCES id',
                nces_district_id: 'district NCES id',
                nces_phone: 'school NCES phone'
              }
            }
          }
        };
        return this.schoolInfoPanel = new SchoolInfoPanel({
          store: this.store
        });
      });

      describe('when choosing a suggested school', () => it('sets the school name', function() {
        this.schoolInfoPanel.applySuggestion('name', {
          name: 'suggested school 2',
          district: 'suggested district 2',
          city: 'suggested city 2',
          state: 'suggested state 2',
          id: 'suggested nces_id 2',
          district_id: 'suggested nces_district_id 2',
          phone: 'suggested nces_phone 2'
        });
        expect(this.schoolInfoPanel.organization).toBe('suggested school 2');
        expect(this.schoolInfoPanel.district).toBe('suggested district 2');
        expect(this.schoolInfoPanel.city).toBe('suggested city 2');
        expect(this.schoolInfoPanel.state).toBe('suggested state 2');
        expect(this.schoolInfoPanel.nces_id).toBe('suggested nces_id 2');
        expect(this.schoolInfoPanel.nces_phone).toBe('suggested nces_phone 2');
        return expect(this.schoolInfoPanel.nces_district_id).toBe('suggested nces_district_id 2');
      }));

      return describe('when choosing a suggested district', () => it('sets the district and leaves the school name alone', function() {
        this.schoolInfoPanel.applySuggestion('district', {
          name: 'suggested name 2',
          district: 'suggested district 2',
          city: 'suggested city 2',
          state: 'suggested state 2',
          id: 'suggested nces_id 2',
          district_id: 'suggested nces_district_id 2',
          phone: 'suggested nces_phone'
        });
        expect(this.schoolInfoPanel.organization).toBe('suggested school');
        expect(this.schoolInfoPanel.district).toBe('suggested district 2');
        expect(this.schoolInfoPanel.city).toBe('suggested city 2');
        expect(this.schoolInfoPanel.state).toBe('suggested state 2');
        expect(this.schoolInfoPanel.nces_id).toBe('');
        expect(this.schoolInfoPanel.nces_phone).toBe('');
        return expect(this.schoolInfoPanel.nces_district_id).toBe('suggested nces_district_id 2');
      }));
    });

    describe('commitValues', function() {
      beforeEach(function() {
        this.store = {
          state: {
            modal: {
              trialRequestProperties: {}
            }
          },
          commit: jasmine.createSpy()
        };
        return this.schoolInfoPanel = new SchoolInfoPanel({
          store: this.store,
          data: {
            organization: 'some name',
            district: 'some district',
            city: 'some city',
            state: 'some state',
            country: 'some country',
            nces_id: 'some nces_id',
            nces_name: 'some name',
            nces_students: 'some students',
            nces_phone: 'some nces_phone',
            nces_district_id: 'some nces_district_id',
            nces_district_schools: 'some nces_district_schools',
            nces_district_students: 'some nces_district_students'
          }
        });
      });

      return it('Commits all of the important values', function() {
        this.schoolInfoPanel.commitValues();
        const [storeName, attrs] = Array.from(this.store.commit.calls.argsFor(0));
        expect(storeName).toBe('modal/updateTrialRequestProperties');
        expect(attrs.organization).toBe('some name');
        expect(attrs.district).toBe('some district');
        expect(attrs.city).toBe('some city');
        expect(attrs.state).toBe('some state');
        expect(attrs.country).toBe('some country');
        expect(attrs.nces_id).toBe('some nces_id');
        expect(attrs.nces_name).toBe('some name');
        expect(attrs.nces_students).toBe('some students');
        expect(attrs.nces_phone).toBe('some nces_phone');
        expect(attrs.nces_district_id).toBe('some nces_district_id');
        expect(attrs.nces_district_schools).toBe('some nces_district_schools');
        return expect(attrs.nces_district_students).toBe('some nces_district_students');
      });
    });

    describe('clickContinue', function() {});

    return describe('clickBack', function() {});
  });

  describe('NcesSearchInput', function() {});

  describe('SetupAccountPanel', function() {});

  return describe('TeacherRolePanel', function() {});
}));

const api = require('core/api');
xdescribe('CreateAccountModal Vue Store', () => describe('actions.createAccount', function() {
  beforeEach(function() {
    spyOn(window, 'fetch').and.callFake(function() {
      throw "This shouldn't be called!";
    });
    spyOn(api.users, 'signupWithGPlus').and.returnValue(Promise.resolve());
    spyOn(api.users, 'signupWithFacebook').and.returnValue(Promise.resolve());
    spyOn(api.users, 'signupWithPassword').and.returnValue(Promise.resolve());
    spyOn(api.trialRequests, 'post').and.returnValue(Promise.resolve());
    this.dispatch = jasmine.createSpy();
    this.commit = jasmine.createSpy();
    this.rootState = {
      me: {
        _id: '12345'
      }
    };
    return this.state = {
      trialRequestProperties: {
        role: 'teacher',
        organization: 'some name',
        district: 'some district',
        city: 'some city',
        nces_id: 'some nces_id'
      },
      signupForm: {
        email: 'form email',
        name: 'form name',
        password: 'form password'
      },
      ssoAttrs: {
        email: '',
        gplusID: '',
        facebookID: ''
      },
      ssoUsed: ''
    };});

  it("uses the form email when SSO isn't used", function(done) {
    return TeacherSignupStoreModule.actions.createAccount({state: this.state, commit: this.commit, dispatch: this.dispatch, rootState: this.rootState}).then(function() {
      expect(api.users.signupWithPassword).toHaveBeenCalled();
      expect(api.users.signupWithGPlus).not.toHaveBeenCalled();
      expect(api.users.signupWithFacebook).not.toHaveBeenCalled();
      expect(__guard__(__guard__(api.users.signupWithPassword.calls.argsFor(0), x1 => x1[0]), x => x.email)).toBe('form email');
      expect(__guard__(__guard__(api.users.signupWithPassword.calls.argsFor(0), x3 => x3[0]), x2 => x2.name)).toBe('form name');
      return done();
    });
  });

  it("uses the SSO email when using GPlus SSO", function(done) {
    _.assign(this.state, {
      ssoAttrs: {
        email: 'sso email',
        gplusID: 'gplus ID'
      },
      ssoUsed: 'gplus'
    }
    );
    return TeacherSignupStoreModule.actions.createAccount({state: this.state, commit: this.commit, dispatch: this.dispatch, rootState: this.rootState}).then(function() {
      expect(api.users.signupWithPassword).not.toHaveBeenCalled();
      expect(api.users.signupWithGPlus).toHaveBeenCalled();
      expect(api.users.signupWithFacebook).not.toHaveBeenCalled();
      expect(__guard__(__guard__(api.users.signupWithGPlus.calls.argsFor(0), x1 => x1[0]), x => x.email)).toBe('sso email');
      expect(__guard__(__guard__(api.users.signupWithGPlus.calls.argsFor(0), x3 => x3[0]), x2 => x2.name)).toBe('form name');
      expect(__guard__(__guard__(api.users.signupWithGPlus.calls.argsFor(0), x5 => x5[0]), x4 => x4.gplusID)).toBe('gplus ID');
      return done();
    });
  });

  return it("uses the SSO email when using Facebook SSO", function(done) {
    _.assign(this.state, {
      ssoAttrs: {
        email: 'sso email',
        facebookID: 'facebook ID'
      },
      ssoUsed: 'facebook'
    }
    );
    return TeacherSignupStoreModule.actions.createAccount({state: this.state, commit: this.commit, dispatch: this.dispatch, rootState: this.rootState}).then(function() {
      expect(api.users.signupWithPassword).not.toHaveBeenCalled();
      expect(api.users.signupWithGPlus).not.toHaveBeenCalled();
      expect(api.users.signupWithFacebook).toHaveBeenCalled();
      expect(__guard__(__guard__(api.users.signupWithFacebook.calls.argsFor(0), x1 => x1[0]), x => x.email)).toBe('sso email');
      expect(__guard__(__guard__(api.users.signupWithFacebook.calls.argsFor(0), x3 => x3[0]), x2 => x2.name)).toBe('form name');
      expect(__guard__(__guard__(api.users.signupWithFacebook.calls.argsFor(0), x5 => x5[0]), x4 => x4.facebookID)).toBe('facebook ID');
      return done();
    });
  });
}));

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}