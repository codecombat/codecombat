require('app/styles/account/auth-view.sass')
const RootView = require('views/core/RootView')
const utils = require('core/utils')
const forms = require('core/forms')
const errors = require('core/errors')
const RecoverModal = require('views/core/RecoverModal')
const contact = require('core/contact')
const User = require('models/User')
const State = require('models/State')
const store = require('core/store')
const globalVar = require('core/globalVar')
const userUtils = require('lib/user-utils')
const { isCodeCombat } = require('core/utils')
const { logInWithClever } = require('core/social-handlers/CleverHandler')
const SchoologyHandler = require('core/social-handlers/SchoologyHandler')
const ClassLinkHandler = require('core/social-handlers/ClassLinkHandler')
const template = require('app/templates/account/auth-view')

class AuthView extends RootView {
  static initClass () {
    this.prototype.id = 'auth-view'
    this.prototype.template = template

    this.prototype.events = {
      'click .auth-mode-link': 'onClickModeLink',
      'click .auth-path-button': 'onClickPathButton',
      'click .auth-back-link': 'onClickBackLink',
      'change input[name="birthdayMonth"]': 'onInputBirthday',
      'change input[name="birthdayDay"]': 'onInputBirthday',
      'change input[name="birthdayYear"]': 'onInputBirthday',
      'submit form.auth-birthday-form': 'onSubmitBirthdayForm',
      'click .auth-parent-email-back': 'onClickParentEmailBack',
      'change input[name="parentEmail"]': 'onChangeParentEmail',
      'submit form.auth-parent-email-form': 'onSubmitParentEmailForm',
      'click .auth-reveal-email': 'onClickRevealEmailForm',
      'click .auth-hide-email': 'onClickHideEmailForm',
      'change input[name="email"]': 'onChangeEmail',
      'change input[name="name"]': 'onChangeName',
      'change input[name="password"]': 'onChangePassword',
      'submit form.auth-individual-form': 'onSubmitIndividualForm',
      'submit form.auth-login-form': 'onSubmitForm',
      'click #link-to-recover': 'openRecoverModal',
      'click #google-signup-button': 'onClickGoogleSignupButton',
      'click #facebook-signup-btn': 'onClickFacebookSignupButton',
      'click #clever-signup-btn': 'onClickCleverSignupButton',
      'click #schoology-signup-btn': 'onClickSchoologySignupButton',
      'click #classlink-signup-btn': 'onClickClasslinkSignupButton',
      'click #google-login-button': 'onClickGPlusLoginButton',
      'click #facebook-login-btn': 'onClickFacebookLoginButton',
      'click #clever-login-btn': 'onClickCleverLoginButton',
      'click #schoology-login-btn': 'onClickSchoologyLoginButton',
      'click #classlink-login-btn': 'onClickClasslinkLoginButton',
    }
  }

  initialize (options = {}) {
    super.initialize(options)
    this.utils = utils
    this.onFacebookLoginError = this.onFacebookLoginError.bind(this)
    this.signupState = new State({
      path: this.getInitialPath(),
      step: this.getInitialSignupStep(),
      birthday: new Date(''),
      birthdayMonth: this.getInitialBirthdayMonth(),
      birthdayDay: '',
      birthdayYear: '',
      parentEmail: '',
      parentEmailSent: false,
      parentEmailSending: false,
      parentEmailError: false,
      dontUseOurEmailSilly: false,
      ssoUsed: null,
      ssoAttrs: null,
      ssoResp: null,
      signupForm: {
        email: '',
        name: '',
        password: '',
      },
      authModalInitialValues: {},
    })
    this.state = new State({
      showEmailForm: false,
      checkEmailState: 'standby',
      checkEmailValue: null,
      checkEmailPromise: null,
      checkNameState: 'standby',
      checkNameValue: null,
      checkNamePromise: null,
      suggestedName: '',
      suggestedNameText: '...',
      error: '',
      loginError: '',
    })
    this.hideEmail = isCodeCombat ? userUtils.shouldHideEmail() : false
    this.showLibraryIdInsteadOfUsername = isCodeCombat ? userUtils.shouldShowLibraryLoginModal() : false
    this.listenTo(this.signupState, 'change', () => this.render())
    this.listenTo(this.state, 'change', () => this.render())
  }

  getInitialPath () {
    if (this.getMode() !== 'signup') { return null }
    const type = new URLSearchParams(window.location.search).get('type')
    return type === 'individual' ? 'individual' : null
  }

  getInitialSignupStep () {
    if (this.getMode() !== 'signup') { return null }
    return this.getInitialPath() === 'individual' ? 'birthday' : 'chooser'
  }

  getInitialBirthdayMonth () {
    return new Date().getUTCMonth() + 1
  }

  getRenderData () {
    const context = super.getRenderData()
    context.mode = this.getMode()
    context.showClever = !/^\/play/.test(window.location.pathname)
    context.previousFormInputs = {
      email: '',
      password: '',
    }
    context.signupPath = this.signupState.get('path')
    context.signupStep = this.signupState.get('step')
    context.signupForm = this.signupState.get('signupForm')
    context.signupBirthdayMonth = this.signupState.get('birthdayMonth')
    context.signupBirthdayDay = this.signupState.get('birthdayDay')
    context.signupBirthdayYear = this.signupState.get('birthdayYear')
    context.parentEmail = this.signupState.get('parentEmail')
    context.parentEmailSent = this.signupState.get('parentEmailSent')
    context.parentEmailSending = this.signupState.get('parentEmailSending')
    context.parentEmailError = this.signupState.get('parentEmailError')
    context.dontUseOurEmailSilly = this.signupState.get('dontUseOurEmailSilly')
    context.authState = this.state.attributes
    context.hideEmail = this.hideEmail
    context.showLibraryIdInsteadOfUsername = this.showLibraryIdInsteadOfUsername
    context.months = [
      'calendar.january',
      'calendar.february',
      'calendar.march',
      'calendar.april',
      'calendar.may',
      'calendar.june',
      'calendar.july',
      'calendar.august',
      'calendar.september',
      'calendar.october',
      'calendar.november',
      'calendar.december',
    ]
    context.currentYear = new Date().getFullYear()
    return context
  }

  getMode () {
    return /\/login$/i.test(document.location.pathname) ? 'login' : 'signup'
  }

  getTitle () {
    if (this.getMode() === 'login') {
      return $.i18n.t('login.log_in')
    }
    if (this.signupState.get('step') === 'birthday') {
      return $.i18n.t('nav.create_free_account')
    }
    return $.i18n.t('nav.create_free_account')
  }

  afterRender () {
    super.afterRender()
    if (!me.useSocialSignOn()) { return }

    application.gplusHandler.loadAPI({
      success: () => {
        if (!this.destroyed) {
          this.$('#google-login-button').attr('disabled', false)
          this.$('#google-signup-button').attr('disabled', false)
        }
      },
    })

    if (utils.isCodeCombat) {
      application.facebookHandler.loadAPI({
        success: () => {
          if (!this.destroyed) {
            this.$('#facebook-login-btn').attr('disabled', false)
            this.$('#facebook-signup-btn').attr('disabled', false)
          }
        },
      })
    }
  }

  onClickModeLink (e) {
    e.preventDefault()
    const mode = $(e.currentTarget).data('mode')
    application.router.navigate(`/${mode}`, { trigger: true })
  }

  onClickBackLink (e) {
    e.preventDefault()
    const step = $(e.currentTarget).data('step')
    this.signupState.set({ step })
  }

  onClickPathButton (e) {
    e.preventDefault()
    const path = $(e.currentTarget).data('path')
    switch (path) {
      case 'teacher':
        window.tracker?.trackEvent('Teachers Create Account Loaded', { category: 'Teachers' })
        return application.router.navigate('/teachers/signup', { trigger: true })
      case 'parent':
        window.location.href = '/parents/signup'
        return
      case 'student':
        return application.router.navigate('/students', { trigger: true })
      case 'individual':
        this.signupState.set({ path: 'individual', step: 'birthday' })
        this.state.set({ showEmailForm: false, error: '' })
        window.history.replaceState({}, '', '/signup?type=individual')
    }
  }

  onInputBirthday () {
    const birthdayMonth = parseInt(this.$('[name="birthdayMonth"]').val(), 10)
    const birthdayDay = parseInt(this.$('[name="birthdayDay"]').val(), 10)
    const birthdayYear = parseInt(this.$('[name="birthdayYear"]').val(), 10)
    const birthday = new Date(Date.UTC(birthdayYear, birthdayMonth - 1, birthdayDay))
    this.signupState.set({ birthdayMonth, birthdayDay, birthdayYear, birthday }, { silent: true })
    if (!_.isNaN(birthday.getTime())) {
      forms.clearFormAlerts(this.$el)
    }
  }

  onSubmitBirthdayForm (e) {
    e.preventDefault()
    this.onInputBirthday()
    const birthday = this.signupState.get('birthday')
    if (_.isNaN(birthday.getTime())) {
      forms.clearFormAlerts(this.$el)
      forms.setErrorToProperty(this.$el, 'birthdayDay', _.string.titleize($.i18n.t('common.required_field')))
      return
    }
    const age = (new Date().getTime() - birthday.getTime()) / 365.4 / 24 / 60 / 60 / 1000
    if (age > utils.ageOfConsent(me.get('country'), 13)) {
      this.signupState.set({ step: 'individual', path: 'individual' })
      this.state.set({ showEmailForm: false, error: '' })
    } else {
      this.signupState.set({ step: 'parent-email', path: 'individual' })
      this.state.set({ error: '' })
    }
  }

  onClickRevealEmailForm (e) {
    e.preventDefault()
    this.state.set({ showEmailForm: true })
  }

  onClickHideEmailForm (e) {
    e.preventDefault()
    this.state.set({ showEmailForm: false })
  }

  onClickParentEmailBack (e) {
    e.preventDefault()
    this.signupState.set({ step: 'birthday' })
  }

  onChangeParentEmail (e) {
    const parentEmail = $(e.currentTarget).val()
    this.signupState.set({ parentEmail }, { silent: true })
    this.signupState.set({
      dontUseOurEmailSilly: /team@codecombat.com/i.test(parentEmail),
      parentEmailError: false,
    })
  }

  onSubmitParentEmailForm (e) {
    e.preventDefault()
    const parentEmail = this.signupState.get('parentEmail')
    this.signupState.set({ parentEmailSending: true, parentEmailError: false })
    return contact.sendParentSignupInstructions(parentEmail)
      .then(() => {
        this.signupState.set({ parentEmailSent: true, parentEmailSending: false })
      })
      .catch(() => {
        this.signupState.set({ parentEmailError: true, parentEmailSending: false, parentEmailSent: false })
      })
  }

  updateAuthModalInitialValues (values) {
    this.signupState.set({
      authModalInitialValues: _.merge(this.signupState.get('authModalInitialValues'), values),
    }, { silent: true })
  }

  onChangeEmail (e) {
    const email = this.$(e.currentTarget).val()
    this.signupState.get('signupForm').email = email
    this.updateAuthModalInitialValues({ email })
    return this.checkEmail()
  }

  onChangeName (e) {
    const name = this.$(e.currentTarget).val()
    this.signupState.get('signupForm').name = name
    this.updateAuthModalInitialValues({ name })
    return this.checkName()
  }

  onChangePassword (e) {
    const password = this.$(e.currentTarget).val()
    this.signupState.get('signupForm').password = password
    this.updateAuthModalInitialValues({ password })
  }

  checkEmail () {
    const email = this.$('[name="email"]').val()

    if (this.hideEmail) {
      return Promise.resolve(true)
    }

    if (!_.isEmpty(email) && email === this.state.get('checkEmailValue')) {
      return this.state.get('checkEmailPromise')
    }

    if (!(email && forms.validateEmail(email))) {
      this.state.set({
        checkEmailState: 'standby',
        checkEmailValue: email,
        checkEmailPromise: null,
      })
      return Promise.resolve()
    }

    this.state.set({
      checkEmailState: 'checking',
      checkEmailValue: email,
      checkEmailPromise: User.checkEmailExists(email)
        .then(({ exists }) => {
          if (email !== this.$('[name="email"]').val()) { return }
          this.state.set({ checkEmailState: exists ? 'exists' : 'available' })
        })
        .catch(error => {
          this.state.set({ checkEmailState: 'standby' })
          throw error
        }),
    })
    return this.state.get('checkEmailPromise')
  }

  checkName () {
    const name = this.$('[name="name"]').val()

    if (name === this.state.get('checkNameValue')) {
      return this.state.get('checkNamePromise')
    }

    if (!name) {
      this.state.set({
        checkNameState: 'standby',
        checkNameValue: name,
        checkNamePromise: null,
      })
      return Promise.resolve()
    }

    this.state.set({
      checkNameState: 'checking',
      checkNameValue: name,
      checkNamePromise: User.checkNameConflicts(name)
        .then(({ suggestedName, conflicts }) => {
          if (name !== this.$('[name="name"]').val()) { return }
          if (conflicts) {
            const suggestedNameText = $.i18n.t('signup.name_taken').replace('{{suggestedName}}', suggestedName)
            this.state.set({ checkNameState: 'exists', suggestedName, suggestedNameText })
          } else {
            this.state.set({ checkNameState: 'available' })
          }
        })
        .catch(error => {
          this.state.set({ checkNameState: 'standby' })
          throw error
        }),
    })

    return this.state.get('checkNamePromise')
  }

  checkBasicInfo (data) {
    forms.clearFormAlerts(this.$el)

    if (data.name && forms.validateEmail(data.name)) {
      forms.setErrorToProperty(this.$el, 'name', $.i18n.t('signup.name_is_email'))
      return false
    }

    const res = tv4.validateMultiple(data, this.formSchema())
    if (res.errors && res.errors.some(err => err.dataPath === '/password')) {
      res.errors = res.errors.filter(err => err.dataPath !== '/password')
      res.errors.push({ dataPath: '/password', message: $.i18n.t('signup.invalid') })
    }
    if (!res.valid || ((res.errors != null ? res.errors.length : undefined) > 0)) {
      forms.applyErrorsToForm(this.$('form.auth-individual-form'), res.errors)
    }
    return res.valid && ((res.errors != null ? res.errors.length : undefined) === 0)
  }

  formSchema () {
    return {
      type: 'object',
      properties: {
        email: User.schema.properties.email,
        name: User.schema.properties.name,
        password: User.schema.properties.password,
      },
      required: ['name', 'password', 'email'],
    }
  }

  onSubmitIndividualForm (e) {
    e.preventDefault()
    this.state.unset('error')
    const data = forms.formToObject(e.currentTarget)
    const valid = this.checkBasicInfo(data)
    if (!valid) { return }

    this.displaySignupSubmitting()
    const abortError = new Error('abort')

    return this.checkEmail()
      .then(() => this.checkName())
      .then(() => {
        if (!(this.state.get('checkEmailState') === 'available' && this.state.get('checkNameState') === 'available')) {
          throw abortError
        }

        const emails = _.assign({}, me.get('emails'))
        if (emails.generalNews == null) { emails.generalNews = {} }
        if (me.inEU()) {
          emails.generalNews.enabled = false
          me.set('unsubscribedFromMarketingEmails', true)
        } else {
          emails.generalNews.enabled = !_.isEmpty(this.state.get('checkEmailValue'))
        }
        me.set('emails', emails)

        if (!_.isNaN(this.signupState.get('birthday')?.getTime())) {
          me.set('birthday', this.signupState.get('birthday').toISOString().slice(0, 7))
        }
        me.set(_.omit(this.signupState.get('ssoAttrs') || {}, 'email', 'facebookID', 'gplusID'))
        me.set('features', {
          ...(me.get('features') || {}),
          isNewDashboardActive: true,
        })
        const saveReq = me.save()
        if (!saveReq) {
          throw new Error('Could not save user')
        }
        return new Promise(saveReq.then)
      })
      .then(newUser => {
        globalVar.application.tracker.identifyAfterNextPageLoad()
        if (!User.isSmokeTestUser({ email: this.signupState.get('signupForm').email })) {
          store.dispatch('me/authenticated', newUser)
          globalVar.application.tracker.identify()
        }

        let signupReq
        switch (this.signupState.get('ssoUsed')) {
          case 'gplus': {
            const { email, gplusID } = this.signupState.get('ssoAttrs')
            signupReq = me.signupWithGPlus(data.name, email, gplusID)
            break
          }
          case 'facebook': {
            const { email, facebookID } = this.signupState.get('ssoAttrs')
            const facebookAccessToken = this.signupState.get('ssoResp')?.authResponse?.accessToken
            signupReq = me.signupWithFacebook(data.name, email, facebookID, { facebookAccessToken })
            break
          }
          case 'schoology':
          case 'classlink':
            signupReq = me.signupWithOauth2(data.email, { name: data.name })
            break
          default:
            signupReq = me.signupWithPassword(data.name, data.email, data.password)
        }

        return new Promise(signupReq.then)
      })
      .then(() => {
        globalVar.application.tracker.trackEvent('CreateAccountModal Individual BasicInfoView Submit Success', { category: 'Individuals' })
        window.location.reload()
      })
      .catch(error => {
        if (error === abortError || error.message === 'abort') {
          return this.displaySignupStandingBy()
        }
        this.displaySignupStandingBy()
        if (error.responseJSON?.i18n) {
          this.state.set({ error: $.i18n.t(error.responseJSON.i18n) || 'Unknown Error' })
        } else if (error.responseJSON?.message) {
          this.state.set({ error: error.responseJSON.message })
        } else {
          this.state.set({ error: 'Unknown Error' })
        }
      })
  }

  displaySignupSubmitting () {
    this.$('#create-individual-account-btn').text($.i18n.t('signup.creating')).attr('disabled', true)
    this.$('input').attr('disabled', true)
  }

  displaySignupStandingBy () {
    this.$('#create-individual-account-btn').text($.i18n.t('login.sign_up')).attr('disabled', false)
    this.$('input').attr('disabled', false)
  }

  onClickGoogleSignupButton (e) {
    return this.onClickSsoSignupButton(e, 'gplus', application.gplusHandler)
  }

  onClickFacebookSignupButton (e) {
    return this.onClickSsoSignupButton(e, 'facebook', application.facebookHandler)
  }

  onClickSchoologySignupButton (e) {
    return this.onClickSsoSignupButton(e, 'schoology', application.schoologyHandler)
  }

  onClickClasslinkSignupButton (e) {
    return this.onClickSsoSignupButton(e, 'classlink', application.classlinkHandler)
  }

  onClickSsoSignupButton (e, ssoUsed, handler) {
    e.preventDefault()
    if (!handler) {
      console.error('Unsupported SSO provider', ssoUsed)
      return
    }
    return this.handleSSOConnect(handler, ssoUsed)
  }

  handleSSOConnect (handler, ssoUsed) {
    if (me.showChinaRegistration()) { return }
    return handler.connect({
      context: this,
      success (resp) {
        if (resp == null) { resp = {} }
        return handler.loadPerson({
          resp,
          context: this,
          success: ssoAttrs => {
            this.signupState.set({ ssoAttrs, ssoResp: resp })
            const { email } = ssoAttrs
            return User.checkEmailExists(email).then(({ exists }) => {
              this.signupState.set({ ssoUsed, email: ssoAttrs.email })
              const autoName = `${ssoAttrs.email.split('@')[0]}+${ssoUsed}`
              this.signupState.set('autoName', autoName)
              this.signupState.get('signupForm').email = ssoAttrs.email
              this.signupState.get('signupForm').name = this.signupState.get('signupForm').name || autoName
              this.state.set({ showEmailForm: true })
              if (exists) {
                return this.state.set({ error: $.i18n.t('signup.account_exists') })
              }
            })
          },
        })
      },
    })
  }

  openRecoverModal (e) {
    e.preventDefault()
    return this.openModalView(new RecoverModal())
  }

  onSubmitForm (e) {
    this.playSound('menu-button-click')
    e.preventDefault()
    forms.clearFormAlerts(this.$el)
    this.$('#unknown-error-alert').addClass('hide')
    const userObject = forms.formToObject(this.$el)
    const res = tv4.validateMultiple(userObject, formSchema)
    if (!res.valid) { return forms.applyErrorsToForm(this.$el, res.errors) }
    let showingError = false
    return new Promise(me.loginPasswordUser(userObject.emailOrUsername, userObject.password).then)
      .catch(jqxhr => {
        if (jqxhr.status === 401) {
          const { errorID } = jqxhr.responseJSON
          if (errorID === 'not-found') {
            forms.setErrorToProperty(this.$el, 'emailOrUsername', $.i18n.t('loading_error.user_not_found'))
            showingError = true
          }
          if (errorID === 'wrong-password') {
            forms.setErrorToProperty(this.$el, 'password', $.i18n.t('account_settings.wrong_password'))
            showingError = true
          }
          if (errorID === 'temp-password-expired') {
            forms.setErrorToProperty(this.$el, 'password', $.i18n.t('account_settings.temp_password_expired'))
            showingError = true
          }
        } else if (jqxhr.status === 429) {
          showingError = true
          forms.setErrorToProperty(this.$el, 'emailOrUsername', $.i18n.t('loading_error.too_many_login_failures'))
        }

        if (!showingError) {
          this.$('#unknown-error-alert').removeClass('hide')
        }
      })
      .then(() => {
        application.tracker.identifyAfterNextPageLoad()
        return application.tracker.identify()
      })
      .finally(() => {
        if (!showingError) {
          loginNavigate()
        }
      })
  }

  onClickGPlusLoginButton (e) {
    e.preventDefault()
    const btn = this.$('#google-login-button')
    return application.gplusHandler.connect({
      context: this,
      success (resp = {}) {
        btn.attr('disabled', true)
        return application.gplusHandler.loadPerson({
          resp,
          context: this,
          success (gplusAttrs) {
            const existingUser = new User()
            return existingUser.fetchGPlusUser(gplusAttrs.gplusID, gplusAttrs.email, {
              success: () => {
                return me.loginGPlusUser(gplusAttrs.gplusID, {
                  success: () => {
                    application.tracker.identifyAfterNextPageLoad()
                    return application.tracker.identify().finally(() => loginNavigate())
                  },
                  error: this.onGPlusLoginError,
                })
              },
              error: (res, jqxhr) => {
                if ((jqxhr.status === 409) && jqxhr.responseJSON.errorID === 'account-with-email-exists') {
                  const mergeLogin = attrs => me.loginGPlusUser(attrs.gplusID, {
                    data: { merge: true, email: attrs.email },
                    success: () => {
                      application.tracker.identifyAfterNextPageLoad()
                      return application.tracker.identify().finally(() => loginNavigate())
                    },
                    error: this.onGPlusLoginError,
                  })
                  if (gplusAttrs.email?.includes(User.getNapervilleDomain())) {
                    return mergeLogin(gplusAttrs)
                  }
                  return noty({
                    text: $.i18n.t('login.accounts_merge_confirmation'),
                    layout: 'topCenter',
                    type: 'info',
                    buttons: [
                      { text: 'Yes', onClick ($noty) { $noty.close(); return mergeLogin(gplusAttrs) } },
                      { text: 'No', onClick ($noty) { return $noty.close() } },
                    ],
                  })
                }
                return this.onGPlusLoginError(res, jqxhr)
              },
            })
          },
        })
      },
      error: e2 => {
        this.onGPlusLoginError()
        if (e2?.error && e2?.details && !e2.message) {
          e2.message = `Google login failed: ${e2.error} - ${e2.details}`
        }
        return noty({ text: e2?.message || e2?.details || e2?.toString?.() || 'Unknown Google login error', layout: 'topCenter', type: 'error', timeout: 5000, killer: false, dismissQueue: true })
      },
    })
  }

  onGPlusLoginError (res, jqxhr) {
    if (((jqxhr != null ? jqxhr.status : undefined) === 401) && jqxhr.responseJSON.errorID === 'individuals-not-supported') {
      forms.setErrorToProperty(this.$el, 'emailOrUsername', $.i18n.t('login.individual_users_not_supported'))
    } else if (arguments.length) {
      errors.showNotyNetworkError(...arguments)
    }

    const btn = this.$('#google-login-button')
    btn.attr('disabled', false)
    const signupBtn = this.$('#google-signup-button')
    signupBtn.attr('disabled', false)
  }

  onClickFacebookLoginButton (e) {
    e.preventDefault()
    const btn = this.$('#facebook-login-btn')
    return application.facebookHandler.connect({
      context: this,
      success: response => {
        btn.attr('disabled', true)
        return application.facebookHandler.loadPerson({
          context: this,
          success: facebookAttrs => {
            const existingUser = new User()
            return existingUser.fetchFacebookUser(facebookAttrs.facebookID, response?.authResponse?.accessToken, {
              success: () => {
                return me.loginFacebookUser(facebookAttrs.facebookID, response?.authResponse?.accessToken, {
                  success: () => {
                    application.tracker.identifyAfterNextPageLoad()
                    return application.tracker.identify().then(() => loginNavigate())
                  },
                  error: this.onFacebookLoginError,
                })
              },
              error: this.onFacebookLoginError,
            })
          },
        })
      },
    })
  }

  onFacebookLoginError (res) {
    this.$('#unknown-error-alert').addClass('hide')
    if (res.errorID === 'individuals-not-supported') {
      forms.setErrorToProperty(this.$el, 'emailOrUsername', $.i18n.t('login.individual_users_not_supported'))
      this.$('#unknown-error-alert').removeClass('hide')
    } else if (res.code === 404) {
      forms.setErrorToProperty(this.$el, 'emailOrUsername', $.i18n.t('loading_error.user_not_found'))
      this.$('#unknown-error-alert').removeClass('hide')
    }

    const btn = this.$('#facebook-login-btn')
    btn.attr('disabled', false)
    const signupBtn = this.$('#facebook-signup-btn')
    signupBtn.attr('disabled', false)
    return errors.showNotyNetworkError(...arguments)
  }

  onClickCleverSignupButton (e) {
    e.preventDefault()
    let cleverClientId, districtId, redirectTo
    if (['next.codecombat.com', 'localhost'].includes(window.location.hostname)) {
      cleverClientId = '943ece596555cac13fcc'
      redirectTo = 'https://next.codecombat.com/auth/login-clever'
      districtId = '5b2ad81a709e300001e2cd7a'
    } else {
      cleverClientId = 'ffce544a7e02c0daabf2'
      redirectTo = 'https://codecombat.com/auth/login-clever'
    }
    let url = `https://clever.com/oauth/authorize?response_type=code&redirect_uri=${encodeURIComponent(redirectTo)}&client_id=${cleverClientId}`
    if (districtId) {
      url += '&district_id=' + districtId
    }
    return window.open(url, '_blank')
  }

  onClickCleverLoginButton (e) {
    e.preventDefault()
    return logInWithClever()
  }

  async onClickSchoologyLoginButton (e) {
    e.preventDefault()
    const handler = new SchoologyHandler()
    return this.onClickEdlinkLoginButton(handler)
  }

  async onClickClasslinkLoginButton (e) {
    e.preventDefault()
    const handler = new ClassLinkHandler()
    return this.onClickEdlinkLoginButton(handler)
  }

  async onClickEdlinkLoginButton (handler) {
    const { loggedIn } = await handler.logInWithEdlink()
    if (loggedIn) {
      window.location.reload()
    } else {
      noty({ text: $.i18n.t('login.login_failed'), layout: 'topCenter', type: 'error', timeout: 5000, killer: false, dismissQueue: true })
    }
  }
}

AuthView.initClass()
module.exports = AuthView

const formSchema = {
  type: 'object',
  properties: {
    emailOrUsername: {
      $or: [
        User.schema.properties.name,
        User.schema.properties.email,
      ],
    },
  },
  required: ['emailOrUsername', 'password'],
}

function loginNavigate () {
  if (window.nextURL) {
    window.location.href = window.nextURL
    return
  }

  if (!me.isAdmin()) {
    if (me.isAPIClient()) {
      application.router.navigate('/partner-dashboard', { trigger: true })
    } else if (me.isStudent()) {
      application.router.navigate('/students', { trigger: true })
    } else if (me.isTeacher()) {
      if (me.isSchoolAdmin()) {
        if (utils.isCodeCombat) {
          application.router.navigate('/teachers/licenses', { trigger: true })
        } else {
          application.router.navigate('/school-administrator', { trigger: true })
        }
      } else {
        application.router.navigate('/teachers/classes', { trigger: true })
      }
    } else if (me.isParentHome()) {
      const routeStr = me.hasNoVerifiedChild() ? '/parents/add-another-child' : '/parents/dashboard'
      application.router.navigate(routeStr, { trigger: true })
    }
  }

  window.location.reload()
}
