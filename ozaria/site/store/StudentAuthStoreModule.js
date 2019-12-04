import api from 'core/api'
import User from 'models/User'
import Classroom from 'models/Classroom'

export default {
  namespaced: true,
  state: {
    classCode: '',
    email: '',
    classroom: new Classroom(),
    signupForm: {
      firstName: '',
      lastName: '',
      name: '',
      password: ''
    },
    ssoAttrs: {
      firstName: '',
      lastName: '',
      name: '',
      email: '',
      gplusId: '',
      facebookId: ''
    },
    ssoUsed: '', // 'gplus' or 'facebook'
    isHourOfCode: false
  },
  mutations: {
    updateClassDetails (state, { classCode, classroom }) {
      state.classCode = classCode
      state.classroom = classroom
    },
    updateSignupForm (state, updates) {
      _.assign(state.signupForm, updates)
    },
    updateSso (state, { ssoUsed, ssoAttrs }) {
      _.assign(state.ssoAttrs, ssoAttrs)
      state.ssoUsed = ssoUsed
    },
    updateEmail (state, { email }) {
      state.email = email
    },
    setHourOfCode (state) {
      state.isHourOfCode = true
    }
  },
  actions: {
    async createAccount ({ state, commit, dispatch, rootState }) {
      const signupForm = _.omit(state.signupForm, (attr) => attr === '')
      const ssoAttrs = _.omit(state.ssoAttrs, (attr) => attr === '')
      const attrs = _.assign({}, signupForm, ssoAttrs, { userID: rootState.me._id })
      if (state.ssoUsed === 'gplus') {
        await api.users.signupWithGPlus(attrs)
      } else if (state.ssoUsed === 'facebook') {
        await api.users.signupWithFacebook(attrs)
      } else {
        await api.users.signupWithPassword(attrs)
      }

      // update User
      const saveOptions = {
        firstName: state.signupForm.firstName || state.ssoAttrs.firstName,
        lastName: state.signupForm.lastName || state.ssoAttrs.lastName,
        role: 'student'
      }
      saveOptions.emails = _.assign({}, me.get('emails'))
      saveOptions.emails.generalNews = saveOptions.emails.generalNews || {}
      if (me.inEU()) {
        saveOptions.emails.generalNews.enabled = false
        saveOptions.unsubscribedFromMarketingEmails = true
      } else if (state.email) {
        saveOptions.emails.generalNews.enabled = true
      }

      if (state.isHourOfCode) {
        saveOptions.hourOfCode = true
        saveOptions.hourOfCode2019 = true
        if (!state.classCode) {
          saveOptions.hourOfCodeOptions = _.assign({}, me.get('hourOfCodeOptions'))
          saveOptions.hourOfCodeOptions.showHocProgress = true
          saveOptions.hourOfCodeOptions.hocCodeLanguage = 'python' // default language
        }
      }

      await dispatch('me/save', saveOptions, {
        root: true
      })

      if (window.tracker && !User.isSmokeTestUser({ email: state.email })) {
        window.tracker.identify()
      }
    },
    async joinClass ({ state }) {
      if (state.classCode && state.classroom) {
        const classroom = new Classroom(state.classroom)
        await new Promise(classroom.joinWithCode(state.classCode).then)
      }
    },
    async setHocOptions ({ state, commit, dispatch }) {
      const saveOptions = {}
      if (state.isHourOfCode) {
        saveOptions.hourOfCode = true
        saveOptions.hourOfCode2019 = true
        saveOptions.hourOfCodeOptions = _.assign({}, me.get('hourOfCodeOptions'))
        saveOptions.hourOfCodeOptions.showHocProgress = true
        saveOptions.hourOfCodeOptions.hocCodeLanguage = 'python' // default language
      }
      await dispatch('me/save', saveOptions, {
        root: true
      })
    }
  }
}
