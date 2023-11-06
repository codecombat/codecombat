// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CreateAccountModal;
require('app/styles/modal/create-account-modal/create-account-modal.sass');
const ModalView = require('views/core/ModalView');
const AuthModal = require('views/core/AuthModal');
const ChooseAccountTypeView = require('./ChooseAccountTypeView');
const SegmentCheckView = require('./SegmentCheckView');
const CoppaDenyView = require('./CoppaDenyView');
const EUConfirmationView = require('./EUConfirmationView');
const OzVsCocoView = require('./OzVsCocoView');
const BasicInfoView = require('./BasicInfoView');
const SingleSignOnAlreadyExistsView = require('./SingleSignOnAlreadyExistsView');
const SingleSignOnConfirmView = require('./SingleSignOnConfirmView');
const ExtrasView = require('./ExtrasView');
const ConfirmationView = require('./ConfirmationView');
const TeacherSignupComponent = require('./teacher/TeacherSignupComponent');
const TeacherSignupStoreModule = require('./teacher/TeacherSignupStoreModule');
const State = require('models/State');
const template = require('app/templates/core/create-account-modal/create-account-modal');
const forms = require('core/forms');
const User = require('models/User');
const errors = require('core/errors');
const utils = require('core/utils');
const store = require('core/store');
const storage = require('core/storage');

/*
CreateAccountModal is a wizard-style modal with several subviews, one for each
`screen` that the user navigates forward and back through.

There are three `path`s, one for each account type (individual, student).
Teacher account path will be added later; for now it defers to /teachers/signup)
Each subview handles only one `screen`, but all three `path` variants because
their logic is largely the same.

They `screen`s are:
  choose-account-type: Sets the `path`.
  segment-check: Checks required info for the path (age, )
    coppa-deny: Seen if the indidual segment-check age is < 13 years old
  basic-info: This is the form for username/password/email/etc.
              It asks for whatever is needed for this type of user.
              It also handles the actual user creation.
              A user may create their account here, or connect with facebook/g+
    sso-confirm: Alternate version of basic-info for new facebook/g+ users
  sso-already-exists: When facebook/g+ user already exists, this prompts them to sign in.
  extras: Not yet implemented
  confirmation: When an account has been successfully created, this view shows them their info and
    links them to a landing page based on their account type.

NOTE: BasicInfoView's two children (SingleSignOn...View) inherit from it.
This allows them to have the same form-handling logic, but different templates.
*/

// "Teacher signup started" event for reaching the Create Teacher form.
const startSignupTracking = function() {
  const properties = {
    category: utils.isCodeCombat ? 'Homepage' : 'Home',
    user: me.get('role') || (me.isAnonymous() && "anonymous") || "homeuser"
  };
  return (window.tracker != null ? window.tracker.trackEvent(
    'Teacher signup started',
    properties) : undefined);
};

module.exports = (CreateAccountModal = (function() {
  CreateAccountModal = class CreateAccountModal extends ModalView {
    static initClass() {
      this.prototype.id = 'create-account-modal';
      this.prototype.template = template;
      this.prototype.closesOnClickOutside = false;
      this.prototype.retainSubviews = true;

      this.prototype.events = {
        'click .login-link': 'onClickLoginLink',
        'click .button.close': 'onClickDismiss'
      };
    }

    constructor (options) {
      if (options == null) { options = {} }
      super(options)
      this.utils = utils;
      const classCode = utils.getQueryVariable('_cc', undefined);
      this.signupState = new State({
        path: classCode ? 'student' : null,
        screen: classCode ? 'segment-check' : 'choose-account-type',
        ssoUsed: null, // or 'facebook', 'gplus'
        classroom: null, // or Classroom instance
        facebookEnabled: (application.facebookHandler != null ? application.facebookHandler.apiLoaded : undefined),
        gplusEnabled: (application.gplusHandler != null ? application.gplusHandler.apiLoaded : undefined),
        classCode,
        birthday: new Date(''), // so that birthday.getTime() is NaN
        authModalInitialValues: {},
        accountCreated: false,
        signupForm: {
          subscribe: ['on'], // checked by default
          email: options.email != null ? options.email : ''
        },
        subModalContinue: options.subModalContinue,
        accountRequiredMessage: options.accountRequiredMessage,
        wantInSchool: false
      });

      const { startOnPath } = options;
      switch (startOnPath) {
        case 'student': this.signupState.set({ path: 'student', screen: 'segment-check' }); break;
        case 'oz-vs-coco': this.signupState.set({ path: 'oz-vs-coco', screen: 'oz-vs-coco' }); break;
        case 'individual': this.signupState.set({ path: 'individual', screen: 'segment-check' }); break;
        case 'individual-basic': this.signupState.set({ path: 'individual', screen: 'basic-info' }); break;
        case 'teacher':
          startSignupTracking();
          if (utils.isCodeCombat) {
            this.signupState.set({ path: 'teacher', screen: this.euConfirmationRequiredInCountry() ? 'eu-confirmation' : 'basic-info' });
          } else {
            this.navigateToTeacherOnboarding();
          }
          break;
        default:
          if (utils.isCodeCombat && /^\/play/.test(location.pathname) && me.showIndividualRegister()) {
            this.signupState.set({ path: 'individual', screen: 'segment-check' });
          }
      }
      if ((this.signupState.get('screen') === 'segment-check') && (!this.signupState.get('path') === 'student') && !this.segmentCheckRequiredInCountry()) {
        this.signupState.set({screen: 'basic-info'});
      }

      this.listenTo(this.signupState, 'all', _.debounce(this.render));

      this.listenTo(this.insertSubView(new ChooseAccountTypeView({ signupState: this.signupState })), {
        'choose-path'(path) {
          if (path === 'teacher') {
            startSignupTracking();
            if (utils.isCodeCombat) {
              if (window.tracker != null) {
                window.tracker.trackEvent('Teachers Create Account Loaded', {category: 'Teachers'});
              } // This is a legacy event name
              return this.signupState.set({ path, screen: this.euConfirmationRequiredInCountry() ? 'eu-confirmation' : 'basic-info' });
            } else {
              return this.navigateToTeacherOnboarding();
            }
          } else if (path === 'oz-vs-coco') {
            return this.signupState.set({ path, screen: 'oz-vs-coco' });
          } else {
            if (path === 'student') {
              if (window.tracker != null) {
                window.tracker.trackEvent('CreateAccountModal Student Path Clicked', {category: 'Students'});
              }
            }
            if (path === 'individual') {
              if (window.tracker != null) {
                window.tracker.trackEvent('CreateAccountModal Individual Path Clicked', {category: 'Individuals'});
              }
            }
            return this.signupState.set({ path, screen: 'segment-check' });
          }
        }
      });

      this.listenTo(this.insertSubView(new SegmentCheckView({ signupState: this.signupState })), {
        'choose-path'(path) { return this.signupState.set({ path, screen: 'segment-check' }); },
        'nav-back'() { return this.signupState.set({ path: null, screen: 'choose-account-type' }); },
        'nav-forward'(screen) { return this.signupState.set({ screen: screen || 'basic-info' }); }
      });

      this.listenTo(this.insertSubView(new CoppaDenyView({ signupState: this.signupState })),
        {'nav-back'() { return this.signupState.set({ screen: 'segment-check' }); }});

      this.listenTo(this.insertSubView(new EUConfirmationView({ signupState: this.signupState })), {
        'nav-back'() {
          if (this.signupState.get('path') === 'teacher') {
            return this.signupState.set({ path: null, screen: 'choose-account-type' });
          } else {
            return this.signupState.set({ screen: 'segment-check' });
          }
        },
        'nav-forward'(screen) { return this.signupState.set({ screen: screen || 'basic-info' }); }
      });

      this.listenTo(this.insertSubView(new OzVsCocoView({ signupState: this.signupState })), {
        'nav-forward'(path) { return this.signupState.set({ path: 'teacher', screen: this.euConfirmationRequiredInCountry() ? 'eu-confirmation' : 'basic-info' }); },
        'nav-back'(path) { return this.signupState.set({ path: null, screen: 'choose-account-type' }); }
      });

      this.listenTo(this.insertSubView(new BasicInfoView({ signupState: this.signupState })), {
        'sso-connect:already-in-use'() { return this.signupState.set({ screen: 'sso-already-exists' }); },
        'sso-connect:new-user'() { return this.signupState.set({screen: 'sso-confirm'}); },
        'nav-back'() {
          if (this.euConfirmationRequiredInCountry()) {
            return this.signupState.set({ screen: 'eu-confirmation' });
          } else if (this.signupState.get('path') === 'teacher') {
            return this.signupState.set({ screen: 'choose-account-type' });
          } else {
            return this.signupState.set({ screen: 'segment-check' });
          }
        },
        'signup'() {
          if (this.signupState.get('path') === 'student') {
            if (utils.isOzaria || me.skipHeroSelectOnStudentSignUp()) {
              return this.signupState.set({ screen: 'confirmation', accountCreated: true });
            } else {
              return this.signupState.set({ screen: 'extras', accountCreated: true });
            }
          } else if (this.signupState.get('path') === 'teacher') {
            store.commit('modalTeacher/updateSso', _.pick(this.signupState.attributes, 'ssoUsed', 'ssoAttrs'));
            store.commit('modalTeacher/updateSignupForm', this.signupState.get('signupForm'));
            const trProperties = _.pick(this.signupState.get('signupForm'), 'firstName', 'lastName');
            if (utils.getQueryVariable('referrerEvent')) {
              trProperties.marketingReferrer = utils.getQueryVariable('referrerEvent');
            }
            store.commit('modalTeacher/updateTrialRequestProperties', trProperties);
            return this.signupState.set({ screen: 'teacher-signup-component' });
          } else if (this.signupState.get('subModalContinue')) {
            storage.save('sub-modal-continue', this.signupState.get('subModalContinue'));
            return window.location.reload();
          } else {
            return this.signupState.set({ screen: 'confirmation', accountCreated: true });
          }
        }
      });

      this.listenTo(this.insertSubView(new SingleSignOnAlreadyExistsView({ signupState: this.signupState })),
        {'nav-back'() { return this.signupState.set({ screen: 'basic-info' }); }});

      this.listenTo(this.insertSubView(new SingleSignOnConfirmView({ signupState: this.signupState })), {
        'nav-back'() { return this.signupState.set({ screen: 'basic-info' }); },
        'signup'() {
          if (this.signupState.get('path') === 'student') {
            if (utils.isOzaria || me.skipHeroSelectOnStudentSignUp()) {
              return this.signupState.set({ screen: 'confirmation', accountCreated: true });
            } else {
              return this.signupState.set({ screen: 'extras', accountCreated: true });
            }
          } else if (this.signupState.get('path') === 'teacher') {
            store.commit('modalTeacher/updateSso', _.pick(this.signupState.attributes, 'ssoUsed', 'ssoAttrs'));
            store.commit('modalTeacher/updateSignupForm', this.signupState.get('signupForm'));
            return this.signupState.set({ screen: 'teacher-signup-component' });
          } else if (this.signupState.get('subModalContinue')) {
            storage.save('sub-modal-continue', this.signupState.get('subModalContinue'));
            return window.location.reload();
          } else {
            return this.signupState.set({ screen: 'confirmation', accountCreated: true });
          }
        }
      });

      this.listenTo(this.insertSubView(new ExtrasView({ signupState: this.signupState })),
        {'nav-forward'() { return this.signupState.set({ screen: 'confirmation' }); }});

      this.insertSubView(new ConfirmationView({ signupState: this.signupState }));

      if (me.useSocialSignOn()) {
        // TODO: Switch to promises and state, rather than using defer to hackily enable buttons after render
        application.facebookHandler.loadAPI({ success: () => { if (!this.destroyed) { return this.signupState.set({ facebookEnabled: true }); } } });
        application.gplusHandler.loadAPI({ success: () => { if (!this.destroyed) { return this.signupState.set({ gplusEnabled: true }); } } });
      }

      return this.once('hidden', function() {
        if (this.signupState.get('accountCreated') && !application.testing) {
          // ensure logged in state propagates through the entire app
          if (window.nextURL) {
            window.location.href = window.nextURL;
            return;
          }

          if (me.isStudent()) {
            application.router.navigate('/students', {trigger: true});
          } else if (me.isTeacher()) {
            application.router.navigate('/teachers/classes', {trigger: true});
          }
          return window.location.reload();
        }
      });
    }

    navigateToTeacherOnboarding() {
      if (window.location.pathname === '/sign-up/educator') {
        return this.hide();
      } else {
        return application.router.navigate('/sign-up/educator', {trigger: true});
      }
    }

    afterRender() {
      super.afterRender();
      const target = this.$el.find('#teacher-signup-component');
      if (!target[0]) { return; }
      if (this.teacherSignupComponent) {
        return target.replaceWith(this.teacherSignupComponent.$el);
      } else {
        this.teacherSignupComponent = new TeacherSignupComponent({
          el: target[0],
          store
        });
        return this.teacherSignupComponent.$on('back', () => {
          if (this.signupState.get('ssoUsed')) {
            this.signupState.set({ssoUsed: undefined, ssoAttrs: undefined});
          }
          return this.signupState.set('screen', 'basic-info');
        });
      }
    }

    destroy() {
      if (this.teacherSignupComponent) {
        this.teacherSignupComponent.$destroy();
      }
      return super.destroy();
    }

    onClickLoginLink() {
      const properties = {
        category: utils.isCodeComba ? 'Homepage' : 'Home',
        subview: this.signupState.get('path') || "choosetype"
      };
      if (window.tracker != null) {
        window.tracker.trackEvent('Log in from CreateAccount', properties);
      }
      return this.openModalView(new AuthModal({ initialValues: this.signupState.get('authModalInitialValues'), subModalContinue: this.signupState.get('subModalContinue') }));
    }

    onClickDismiss() {
      // Force back to root (in case url changed) or reload to avoid issues with sign up state and CTA's for signing up on the home page:
      application.router.navigate('/', {trigger: true});
      return window.location.reload();
    }

    segmentCheckRequiredInCountry() {
      let needle;
      if (!me.get('country')) { return true; }
      if (me.inEU() || (needle = me.get('country'), ['united-states', 'israel'].includes(needle))) { return true; }
      return false;
    }

    euConfirmationRequiredInCountry() {
      return me.get('country') && me.inEU();
    }
  };
  CreateAccountModal.initClass();
  return CreateAccountModal;
})());
