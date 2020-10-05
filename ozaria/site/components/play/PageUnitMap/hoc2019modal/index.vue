<script>
import BaseModalContainer from '../../../common/BaseModalContainer'
import ModalStartJourney from './ModalStartJourney'
import ModalSignIn from './ModalSignIn'
import ModalRecoverPassword from './ModalRecoverPassword'
import ModalStudentClassCode from './StudentSignup/ModalStudentClassCode'
import ModalEducatorSignUp from './ModalEducatorSignUp'
import ModalStudentSignUp from './StudentSignup/ModalStudentSignup'
import ModalEducatorCompletedSignUp from './ModalEducatorCompletedSignUp'
import ModalStudentAccountCreated from './StudentSignup/ModalStudentAccountCreated'
import TeacherSignupStoreModule from 'app/views/core/CreateAccountModal/teacher/TeacherSignupStoreModule'
import StudentAuthStoreModule from 'ozaria/site/store/StudentAuthStoreModule'
import store from 'app/core/store'

const utils = require('core/utils')

const STARTJOURNEY = 'ModalStartJourney'
const SIGNIN = 'ModalSignIn'
const RECOVERPASSWORD = 'ModalRecoverPassword'
const STUDENTCLASSCODE = 'ModalStudentClassCode'
const EDUCATORSIGNUP = 'ModalEducatorSignUp'
const STUDENTSIGNUP = 'ModalStudentSignUp'
const EDUCATORCOMPLETESIGNUP = 'ModalEducatorCompletedSignUp'
const STUDENTACCOUNTCREATED = 'ModalStudentAccountCreated'

const viewData = {
  [STARTJOURNEY] : {
    kind: STARTJOURNEY,
    id: 'start-journey-modal'
  },
  [SIGNIN] : {
    kind: SIGNIN,
    id: 'auth-modal-container'
  },
  [RECOVERPASSWORD] : {
    kind: RECOVERPASSWORD,
    id: 'recover-password'
  },
  [STUDENTCLASSCODE]: {
    kind: STUDENTCLASSCODE,
    id: 'student-class-code-container'
  },
  [EDUCATORSIGNUP] : {
    kind: EDUCATORSIGNUP,
    id: 'educator-sign-up-container'
  },
  [STUDENTSIGNUP] : {
    kind: STUDENTSIGNUP,
    id: 'ozaria-modal-container'
  },
  [EDUCATORCOMPLETESIGNUP] : {
    kind: EDUCATORCOMPLETESIGNUP,
    id: 'ozaria-modal-container'
  },
  [STUDENTACCOUNTCREATED] : {
    kind: STUDENTACCOUNTCREATED,
    id: 'ozaria-modal-container'
  }
}

export default {
  components: {
    BaseModalContainer,
    ModalStartJourney,
    ModalSignIn,
    ModalRecoverPassword,
    ModalStudentClassCode,
    ModalEducatorSignUp,
    ModalStudentSignUp,
    ModalEducatorCompletedSignUp,
    ModalStudentAccountCreated
  },

  props: {
    saveProgressModal: {
      type: Boolean,
      default: false
    }
  },

  data: () => ({
    currentView: STARTJOURNEY,
    modalHistory: [],
    classCode: ''
  }),

  mounted () {
    this.$store.registerModule('studentModal', StudentAuthStoreModule)
    this.$store.registerModule('teacherModal', TeacherSignupStoreModule)
    const { _cc } = utils.getQueryVariables()
    if (!_cc) {
      return this.openStartJourney();
    }
    this.openStudentClassCode()
  },

  destroyed () {
    this.$store.unregisterModule('studentModal')
    this.$store.unregisterModule('teacherModal')
  },

  methods: {
    openSignInView () {
      this.navigateToView(SIGNIN)
    },

    openStartJourney () {
      this.modalHistory = []

      /**
       * There are two flows. The anonymous user begin journey flow, and the
       * student who has been playing anonymously for a while and signs up later.
       */
      if (this.saveProgressModal) {
        this.navigateToView(STUDENTSIGNUP)
      } else {
        this.navigateToView(STARTJOURNEY)
      }
    },

    openRecoverPassword () {
      this.navigateToView(RECOVERPASSWORD)
    },

    openEducatorSignUp () {
      this.navigateToView(EDUCATORSIGNUP)
    },

    openStudentClassCode () {
      this.navigateToView(STUDENTCLASSCODE)
    },

    openStudentSignUp () {
      this.navigateToView(STUDENTSIGNUP)
    },

    openEducatorCompletedSignUp () {
      this.navigateToView(EDUCATORCOMPLETESIGNUP)
    },

    completeStudentSignUp () {
      if (!this.saveProgressModal) {
        this.completeSignUp()
      } else {
        this.navigateToView(STUDENTACCOUNTCREATED)
      }
    },

    completeSignUp () {
      this.closeModal()
      window.location.reload();
    },

    completeLogin () {
      window.location.reload();
    },

    navigateBack () {
      if (this.modalHistory.length <= 0) {
        return this.openStartJourney()
      }
      const destination = this.modalHistory.pop();
      this.currentView = destination;
    },

    navigateToView (view) {
      if (!Object.keys(viewData).includes(view)) {
        throw new Error(`View '${view}' isn't registered or doesn't exist.`)
      }
      this.modalHistory.push(this.currentView)
      this.currentView = view
    },

    closeModal () {
      this.$emit('closeModal')
    },

    setClassCode (classCode) {
      this.classCode = classCode;
      this.$store.dispatch('classrooms/setMostRecentClassCode', classCode)
    }
  },

  computed: {
    viewId() {
      return viewData[this.currentView].id
    }
  }
}
</script>

<template>
  <base-modal-container
    :id="viewId"
    class="hoc2019-modal"
    :fade="Boolean(saveProgressModal)"
  >
    <ModalStartJourney
      v-if="currentView === 'ModalStartJourney'"
      @clickEducator="openEducatorSignUp"
      @clickStudent="openStudentClassCode"
      @closeModal="closeModal"
    />
    <ModalSignIn
      v-if="currentView === 'ModalSignIn'"
      :saveProgressModal="saveProgressModal"
      @switchToSignup="openStartJourney"
      @clickRecoverModal="openRecoverPassword"
      @done="completeLogin"
    />
    <ModalRecoverPassword
      v-if="currentView === 'ModalRecoverPassword'"
      @successfullyRecovered="closeModal"
    />
    <keep-alive>
      <ModalStudentClassCode
        v-if="currentView === 'ModalStudentClassCode'"

        @done="openStudentSignUp"
        @closeModal="closeModal"
        @back="navigateBack"
      />
    </keep-alive>
    <ModalStudentSignUp
      v-if="currentView === 'ModalStudentSignUp'"

      :saveProgressModal="saveProgressModal"

      @back="navigateBack"
      @closeModal="closeModal"
      @done="completeStudentSignUp"
      @signIn="openSignInView"
    />
    <ModalStudentAccountCreated
      v-if="currentView === 'ModalStudentAccountCreated'"

      @done="completeSignUp"
    />
    <ModalEducatorSignUp
      v-if="currentView === 'ModalEducatorSignUp'"

      @done="openEducatorCompletedSignUp"
      @back="navigateBack"
      @closeModal="closeModal"
      @signIn="openSignInView"
      @retrievedClassCode="setClassCode"
    />
    <ModalEducatorCompletedSignUp
      v-if="currentView === 'ModalEducatorCompletedSignUp'"
      :classCode="classCode"
      @closeModal="completeSignUp"
    />

  </base-modal-container>
</template>

<style lang="scss">
.hoc2019-modal {
  width: 100vw;
  height: 100vh;
  position: absolute;
  top: 0;
  left: 0;

  h1, h2, h3 {
    font-style: Work Sans;
    font-variant: normal;
  }

  & > .modal-container {
    background: transparent;
    transition: unset;
  }

}
</style>
