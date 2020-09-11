<script>
  import { mapActions, mapGetters } from 'vuex'
  import PageStartSignup from './PageStartSignup'
  import PageBasicInfo from './PageBasicInfo'
  import PageRoleInfo from './PageRoleInfo'
  import PageSchoolInfo from './PageSchoolInfo/index'
  import ModalSignIn from 'ozaria/site/components/play/PageUnitMap/hoc2019modal/ModalSignIn' // TODO move to components/sign-in and update design
  import TeacherSignupStoreModule from 'app/views/core/CreateAccountModal/teacher/TeacherSignupStoreModule'

  import VueScrollTo from 'vue-scrollto'

  const STARTSIGNUP = 'PageStartSignup'
  const BASICINFO = 'PageBasicInfo'
  const ROLEINFO = 'PageRoleInfo'
  const SCHOOLINFO = 'PageSchoolInfo'

  const viewData = {
    [STARTSIGNUP]: {
      kind: STARTSIGNUP,
      id: 'start-signup-component'
    },
    [BASICINFO]: {
      kind: BASICINFO,
      id: 'basic-info-component'
    },
    [ROLEINFO]: {
      kind: ROLEINFO,
      id: 'role-info-component'
    },
    [SCHOOLINFO]: {
      kind: SCHOOLINFO,
      id: 'school-info-component'
    }
  }

  export default {
    components: {
      PageStartSignup,
      PageBasicInfo,
      PageRoleInfo,
      PageSchoolInfo,
      ModalSignIn
    },

    data: () => ({
      visibleViews: [],
      childFormsValid: false,
      signInModal: false,
      creatingTeacherAccountLoad: false
    }),

    computed: {
      ...mapGetters({
        trialReqProps: 'teacherSignup/getTrialRequestProperties'
      }),
      currentView () {
        return _.last(this.visibleViews)
      },
      firstView () {
        if (me.showChinaRegistration()) {
          return BASICINFO
        } else {
          return STARTSIGNUP
        }
      }
    },

    mounted () {
      if (!me.isAnonymous()) {
        return application.router.navigate('/', { trigger: true })
      }
      this.$store.registerModule('teacherSignup', TeacherSignupStoreModule)
      window.tracker?.trackEvent('Teachers Sign-up page Loaded', { category: 'Onboarding' })
      this.navigateToView(this.firstView)
    },

    updated () {
      this.$nextTick(function () {
        if (this.currentView && !this.signInModal) {
          const id = viewData[this.currentView].id
          this.$scrollTo(`#${id}`, 500, { cancelable: false })
        }
      })
    },

    destroyed () {
      if (this.$store.state.teacherSignup) {
        this.$store.unregisterModule('teacherSignup')
      }
    },

    methods: {
      ...mapActions({
        createAccount: 'teacherSignup/createAccount'
      }),

      async goToNextView (view) {
        if (!Object.keys(viewData).includes(view)) {
          throw new Error(`View '${view}' isn't registered or doesn't exist.`)
        }
        window.tracker?.trackEvent(`Teachers clicked Next on '${view}'`, { category: 'Onboarding' })
        if (view === BASICINFO) {
          this.navigateToView(ROLEINFO)
        } else if (view === ROLEINFO) {
          this.navigateToView(SCHOOLINFO)
        } else if (view === SCHOOLINFO) {
          await this.completeSignup()
        }
      },

      navigateToView (view) {
        if (!Object.keys(viewData).includes(view)) {
          throw new Error(`View '${view}' isn't registered or doesn't exist.`)
        }
        if (!this.visibleViews.includes(view)) {
          this.visibleViews.push(view) // this is scrolled-to after dom is re-rendered (in updated method)
        } else {
          const id = viewData[view].id
          this.$scrollTo(`#${id}`, 500, { cancelable: false })
        }
      },

      startSignup (signUpMethod) {
        if (signUpMethod === 'email') {
          this.clearVisibleViews()
          this.$nextTick(function () { // re-render the forms when signup method is changed
            this.navigateToView(BASICINFO)
          })
        } else if (signUpMethod === 'gplus') {
          this.clearVisibleViews()
          this.$nextTick(function () { // re-render the forms when signup method is changed
            this.navigateToView(ROLEINFO)
          })
        }
      },

      clearVisibleViews () {
        this.visibleViews.splice(1)
      },

      childFormValidityChange (val) {
        this.childFormsValid = val
      },

      async completeSignup () {
        if (!this.childFormsValid) {
          noty({ text: 'Correct the errors in signup form', type: 'error', layout: 'center', timeout: 2000 })
          return
        }

        this.creatingTeacherAccountLoad = true

        try {
          await this.createAccount()
          this.finishLogin()
        } catch (err) {
          console.error('Error in teacher signup', err)
          noty({ text: err.message || 'Error during signup', type: 'error', layout: 'center', timeout: 2000 })
          this.creatingTeacherAccountLoad = false
        }
      },

      finishLogin () {
        window.tracker?.trackEvent('Teachers Signup Success', { category: 'Onboarding' })
        window.location.replace('/teachers/classes')
      },

      isSchoolInfoForm (view) {
        return view === SCHOOLINFO
      },

      openSignInModal () {
        window.tracker?.trackEvent('Teachers Login Clicked from sign-up page', { category: 'Onboarding' })
        this.signInModal = true
      },

      closeSignInModal () {
        this.signInModal = false
      }
    }
  }
</script>

<template lang="pug">
  .style-ozaria.educator-sign-up.container
    .row
      .right-div.col-xs-7.col-xs-offset-5
        div(v-for="view of visibleViews")
          component(
            v-if="isSchoolInfoForm(view)"
            :key="trialReqProps.role+'-'+trialReqProps.country"
            :is="view"
            :creatingTeacherAccountLoad="creatingTeacherAccountLoad"
            @goToNext="goToNextView(view)"
            @startSignup="startSignup"
            @signIn="openSignInModal"
            @validityChange="childFormValidityChange"
          )
          component(
            v-else
            :is="view"
            @goToNext="goToNextView(view)"
            @startSignup="startSignup"
            @signIn="openSignInModal"
            @validityChange="childFormValidityChange"
          )
    ModalSignIn.sign-in-modal(v-if="signInModal" @switchToSignup="closeSignInModal" @done="finishLogin")
</template>

<style lang="sass" scoped>
.educator-sign-up
  width: 100vw
  margin-bottom: -50px
  background-image: url('/images/ozaria/common/signup_background.png')
  background-repeat: no-repeat
  background-size: cover
  background-attachment: fixed
  .right-div
    display: flex
    flex-direction: column
    justify-content: center
    align-items: flex-start
  .sign-in-modal
    position: absolute
    width: 100%
    height: 100%
    margin: auto
    top: 10%
</style>
