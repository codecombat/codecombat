<script>
  import { mapMutations, mapActions } from 'vuex'
  import LayoutSplit from './layout/LayoutSplit'
  import CloseModalBar from './layout/CloseModalBar'

  const Classroom = require('core/api/classrooms')
  const utils = require('core/utils')
  const CourseInstances = require('core/api/course-instances')
  const User = require('models/User')

  export default {
    components: {
      LayoutSplit,
      CloseModalBar
    },

    data: () => ({
      languageSelected: 'Python',
      firstName: '',
      lastName: '',
      email: '',
      password: '',
      loading: {
        isLoading: false
      }
    }),

    mounted () {
      this.setHourOfCode()
    },

    methods: {
      ...mapMutations({
        updateSso: 'teacherModal/updateSso',
        updateSignupForm: 'teacherModal/updateSignupForm',
        updateTrialRequestProperties: 'teacherModal/updateTrialRequestProperties',
        updateClassLanguage: 'teacherModal/updateClassLanguage',
        setHourOfCode: 'teacherModal/setHourOfCode'
      }),

      ...mapActions({
        createAccount: 'teacherModal/createAccount'
      }),

      async createClassroom () {
        const resp = await Classroom.post({
          aceConfig: {
            language: this.languageSelected.toLowerCase()
          },
          name: 'Hour of Code 2019' // TODO use utils.hourOfCodeOptions
        })
        const { codeCamel, _id } = resp

        this.$emit('retrievedClassCode', codeCamel)

        await CourseInstances.post({
          classroomID: _id,
          courseID: utils.courseIDs.CHAPTER_ONE // TODO use utils.hourOfCodeOptions
        })
      },

      async onSubmitForm (e) {
        this.loading.isLoading = true;
        const emailExists = await this.checkEmail(this.email)
        if (emailExists) {
          this.loading.isLoading = false;
          return
        }
        this.updateSso({ ssoUsed: 'email' })
        await this.createTeacherAccount()
        this.loading.isLoading = false;
      },
      async googleSignUp () {
        try {
          await new Promise((resolve, reject) =>
            application.gplusHandler.loadAPI({
              success: resolve,
              error: reject
            }))

          await new Promise((resolve, reject) =>
            application.gplusHandler.connect({
              context: this,
              success: resolve
            }))
          const gplusAttrs = await new Promise((resolve, reject) =>
            application.gplusHandler.loadPerson({
              context: this,
              success: resolve,
              error: reject
            }))
          const { email, firstName, lastName } = gplusAttrs
          const emailExists = await this.checkEmail(email)
          if (emailExists) {
            return
          }
          this.email = email
          this.firstName = firstName
          this.lastName = lastName
          this.updateSso({
            ssoUsed: 'gplus',
            ssoAttrs: gplusAttrs
          })
        } catch (err) {
          console.error('Error in teacher signup', err)
          noty({ text: err.message || 'Error during signup', type: 'error', layout: 'center', timeout: 2000 })
          return
        }
        await this.createTeacherAccount()
      },
      async createTeacherAccount () {
        this.updateClassLanguage({ language: this.languageSelected.toLowerCase() })

        this.updateSignupForm({
          email: this.email,
          password: this.password,
          firstName: this.firstName,
          lastName: this.lastName
        })
        let trialReqCountry = ''
        if (me.get('country')) {
          trialReqCountry = (utils.countries || []).find((c) => c.country === me.get('country')).countryCode
          if (trialReqCountry === 'US') {
            trialReqCountry = 'USA'
          }
        }
        let trialReqName = this.firstName
        if (this.lastName) {
          trialReqName += ' ' + this.lastName
        }
        this.updateTrialRequestProperties({
          country: trialReqCountry,
          role: 'teacher',
          firstName: this.firstName,
          lastName: this.lastName,
          name: trialReqName,
          email: this.email
        })
        try {
          await this.createAccount()
          await this.createClassroom()
          // update user (TODO: Refactor into TeacherSignupStoreModule.coffee, used in SetupAccountPanel also)
          const emails = _.assign({}, me.get('emails'))
          emails.generalNews = emails.generalNews || {}
          emails.teacherNews = emails.teacherNews || {}
          if (me.inEU()) {
            emails.generalNews.enabled = false
            emails.teacherNews.enabled = false
            me.set('unsubscribedFromMarketingEmails', true)
          } else if (this.email) {
            emails.generalNews.enabled = true
            emails.teacherNews.enabled = true
          }
          me.set('emails', emails)
          me.set('firstName', this.firstName)
          if (this.lastName) {
            me.set('lastName', this.lastName)
          }
          await new Promise(me.save().then)
          this.$emit('done')
        } catch (err) {
          console.error('Error in teacher signup', err)
          noty({ text: err.message || 'Error during signup', type: 'error', layout: 'center', timeout: 2000 })
        }
      },
      async checkEmail (email) {
        if (email) {
          const { exists } = await User.checkEmailExists(email)
          if (exists) {
            const errMessage = '<p>You already have an account.</p><p>Please click the link below to login.</p><p>If you want to try the Ozaria Hour of Code activity with another class, create a new class from your Teacher Dashboard after logging in.</p>'
            noty({
              text: errMessage,
              type: 'info',
              layout: 'center',
              buttons: [
                {
                  addClass: 'btn btn-primary', text: 'Ok', onClick: function($noty) {
                  $noty.close();
                }
              }
              ]
            })
            return true
          }
        }
        return false
      }
    }
  }
</script>

<template>
  <LayoutSplit @back="$emit('back')">
    <CloseModalBar @click="$emit('closeModal')" style="margin-bottom: -9px;"/>
    <div id="educator-signup">
      <h1>{{$t("hoc_2019.create_a_class")}}</h1>

      <h3>{{$t("hoc_2019.choose_language")}}</h3>
      <div class="form-group">
        <label for="language-select">{{$t("hoc_2019.programming_language")}}</label>
        <select id="language-select" class="ozaria-input-field" v-model="languageSelected">
          <option>Python</option>
          <option>JavaScript</option>
        </select>
      </div>
      <h3>{{$t("hoc_2019.sign_up")}}</h3>
      <div class='text-center'>
        <a id="google-sso-signup" @click="googleSignUp">
          <img src="/images/ozaria/common/Google Sign Up.png"/>
        </a>
      </div>

      <div class="or">
        <div class="yellow-bar-1"></div>
        <div class='or-text'><span>{{$t("general.or")}}</span></div>
        <div class="yellow-bar-2"></div>
      </div>

      <form @submit.prevent="onSubmitForm">
        <div class="form-group">
          <label for="firstName">{{$t("general.first_name")}}</label>
          <input id="firstName" class="ozaria-input-field" v-model="firstName" type="text" required />
        </div>
        <div class="form-group">
          <label for="email">{{$t("general.email")}}</label>
          <input id="email" class="ozaria-input-field" v-model="email" type="email" required/>
        </div>
        <div class="form-group">
          <label for="password">{{$t("general.password")}}</label>
          <input id="password" class="ozaria-input-field" v-model="password" type="password" required minlength=4 />
        </div>
        <div class='text-center'>
          <button
            class="ozaria-btn"
            type="submit"
            :disabled="loading.isLoading"
          >
            {{loading.isLoading ? "Creating Account" : "Create Class and Try Activity"}}
          </button>
          <a class="sign-in" @click="$emit('signIn')">{{$t("hoc_2019.already_have_account")}}</a>
        </div>
      </form>
    </div>
    <template slot="aside">
      <div id="teacher-aside">
        <div class="teacher-asides">
          <img id="lessonplan-img" src="/images/pages/modal/hoc2019/LessonPlan.png"/>
          <a href="https://www.ozaria.com/teachers/hour-of-code" target="_blank">{{$t("hoc_2019.download_lesson_plan")}}</a>
        </div>
        <div class="teacher-asides">
          <img id="ozaria-img" src="/images/pages/modal/hoc2019/Ozaria.png"/>
          <a @click="$emit('closeModal')">{{$t("hoc_2019.try_activity_without_class")}}</a>
        </div>
      </div>
    </template>
  </LayoutSplit>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#educator-signup {
  width: 704px;
  padding: 0 30px 27px 47px;

  h1 {
    color: $pitch;
    font-family: Work Sans;
    font-size: 24px;
    line-height: 28px;
    letter-spacing: 0.83px;
    font-style: normal;

    margin-top: 0;
    padding-right: 15px; // Ensure that text never overlaps with close cross.
  }

  h3 {
    color: $pitch;
    font-family: Work Sans;
    font-size: 18px;
    line-height: 30px;
    letter-spacing: 0.4x;
  }

  .form-group {
    display: flex;
    align-items: center;
    flex-direction: row;
    justify-content: space-between;
    padding: 0 83px 0 58px;

    label {
      margin-bottom: 0;

      font-family: Work Sans;
      font-weight: 400;
      color: $color-tertiary-brand;
      font-size: 18px;
      letter-spacing: 0.2px;
      line-height: 24px;
    }

    .ozaria-input-field {
      height: 36px;
      width: 334px;

      box-sizing: border-box;
      border: 1px solid $dusk;
      border-radius: 2px;
      background-color: #FFFFFF;

      font-family: Work Sans;
      padding-left: 12.5px;
      color: $pitch;
      font-size: 18px;
      line-height: 24px;
      letter-spacing: 0.2px;
    }
  }
  // TODO: Refactor these out to be a standard button across the codebase:
  .ozaria-btn {
    text-shadow: unset;
    font-family: Work Sans, "Open Sans", sans-serif;
    font-size: 20px;
    font-weight: 600;
    letter-spacing: 0.4px;
    line-height: 22px;
    min-height: 60px;
    min-width: 261px;
    padding: 24px 32px;

    color: $pitch;
    background-image: unset;
    background-color: $dusk;
    border: unset;

    margin-top: 10px;

    &:hover {
      background-color: $dusk-dark;
    }
  }

  #google-sso-signup {
    img {
      height: 40px;
    }
  }

  a {
    font-family: Work Sans;
    font-size: 14px;
    color: #0170E9;
    letter-spacing: 0.23px;
    line-height: 18px;
    text-decoration: underline;

    &.sign-in {
      display: block;
      margin-top: 10px;
    }
  }

  .or {
    display: flex;
    flex-direction: row;
    align-items: center;
    margin-bottom: 10px;
    margin-top: 21px;

    .yellow-bar-1, .yellow-bar-2 {
      height: 8px;
      width: 230px;
      display: inline-block;
    }
    .yellow-bar-1 {
      background: linear-gradient(to left, #efc947 0%, #F7D047 80.4%, #F7D047 100%);
    }
    .yellow-bar-2 {
      background: linear-gradient(to left, #D1B147 0%, #D1B147 40%, #efc947 100%);
    }
    .or-text {
      width: 54px;
      text-align: center;
    }
    span {
      font-family: Work Sans;
      font-size: 28px;
      line-height: 32px;
      letter-spacing: 0.56px;
      color: $goldenlight;
      font-weight: 600;
    }
  }
}
#teacher-aside {
  .teacher-asides {
    display: flex;
    flex-direction: row;
    align-items: center;

    width: 254px;
    img {
      width: 60px;
    }
    a {
      color: white;
      text-decoration: underline;
      font-size: 16px;
      line-height: 24px;
      letter-spacing: 0.27px;
    }
  }
}
</style>
