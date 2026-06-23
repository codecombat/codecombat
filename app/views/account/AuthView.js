require('app/styles/account/auth-view.sass')
const RootView = require('views/core/RootView')
const utils = require('core/utils')
const forms = require('core/forms')
const errors = require('core/errors')
const RecoverModal = require('views/core/RecoverModal')
const User = require('models/User')
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
      'submit form.auth-login-form': 'onSubmitForm',
      'click #link-to-recover': 'openRecoverModal',
      'click #google-login-button': 'onClickGPlusLoginButton',
      'click #facebook-login-btn': 'onClickFacebookLoginButton',
      'click #clever-signup-btn': 'onClickCleverSignupButton',
      'click #clever-login-btn': 'onClickCleverLoginButton',
      'click #schoology-login-btn': 'onClickSchoologyLoginButton',
      'click #classlink-login-btn': 'onClickClasslinkLoginButton',
    }
  }

  initialize (options = {}) {
    super.initialize(options)
    this.utils = utils
    this.onFacebookLoginError = this.onFacebookLoginError.bind(this)
  }

  getRenderData () {
    const context = super.getRenderData()
    context.mode = this.getMode()
    context.showClever = !/^\/play/.test(window.location.pathname)
    context.previousFormInputs = {
      email: '',
      password: '',
    }
    return context
  }

  getMode () {
    return /\/login$/i.test(document.location.pathname) ? 'login' : 'signup'
  }

  getTitle () {
    return $.i18n.t(this.getMode() === 'login' ? 'login.log_in' : 'nav.create_free_account')
  }

  afterRender () {
    super.afterRender()
    if (!me.useSocialSignOn()) { return }

    application.gplusHandler.loadAPI({
      success: () => {
        if (!this.destroyed) {
          this.$('#google-login-button').attr('disabled', false)
        }
      },
    })

    if (utils.isCodeCombat) {
      application.facebookHandler.loadAPI({
        success: () => {
          if (!this.destroyed) {
            this.$('#facebook-login-btn').attr('disabled', false)
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
        return application.router.navigate('/signup?type=individual', { trigger: true })
    }
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
