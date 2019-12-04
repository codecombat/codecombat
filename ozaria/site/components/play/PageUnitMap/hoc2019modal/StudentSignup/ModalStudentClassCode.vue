<script>
  import { mapMutations } from 'vuex'
  import LayoutSplit from '../layout/LayoutSplit'
  import CloseModalBar from '../layout/CloseModalBar'

  const Classroom = require('models/Classroom')
  const utils = require('core/utils')

  export default {
    data: () => ({
      classCode: '',
      classroom: {},
      validClassCodes: new Set()
    }),

    components: {
      LayoutSplit,
      CloseModalBar
    },

    mounted() {
      const { _cc } = utils.getQueryVariables()
      this.classCode = _cc
    },

    methods: {
      ...mapMutations({
        updateClassDetails: 'studentModal/updateClassDetails'
      }),

      async onSubmitForm (e) {
        const isValid = await this.isClassCodeValid()
        if (isValid) {
          this.updateClassDetails({ classCode: this.classCode, classroom: this.classroom.data })
          this.$emit('done')
        } else if (this.classCode) {
          noty({ text: 'Invalid class code', type: 'error', layout: 'center', timeout: 2000 })
        }
      },

      async isClassCodeValid () {
        if (!this.classCode) {
          return false
        }
        if (this.validClassCodes.has(this.classCode)) {
          return true
        }
        try {
          this.classroom = await new Promise(new Classroom().fetchByCode(this.classCode).then)
          if (this.classroom) {
            this.validClassCodes.add(this.classCode)
            return true
          }
          return false
        } catch (err) {
          console.error('Error in validating class code', err)
          return false
        }
      }
    }
  }
</script>

<template>
    <LayoutSplit @back="$emit('back')">
      <CloseModalBar @click="$emit('closeModal')"/>
      <div id="student-signup">

        <h1>{{$t("hoc_2019.want_to_save")}}</h1>
        <div>
          <h3>{{$t("hoc_2019.ask_teacher_class_code") + ":"}}</h3>
          <form @submit.prevent="onSubmitForm">
            <div class="form-group">
              <label class="label-cc" for="classCode">{{$t("hoc_2019.class_code")}}</label>
              <input
                class="ozaria-input-field"
                v-model="classCode"
                type="text"
                required
                :input="isClassCodeValid"
              >

              <button
                id="done-btn"
                class="ozaria-btn"
                type="submit"
                :disabled="!isClassCodeValid"
              >
                {{$t("play_level.done")}}
              </button>
            </div>
          </form>
        </div>
        <a @click="$emit('closeModal')">{{$t("hoc_2019.dont_have")}}</a>
      </div>
    </LayoutSplit>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#student-signup {
  width: 590px;
  padding: 0 30px 40px 24px;
  h1 {
    color: $pitch;
    font-family: Work Sans;
    font-size: 24px;
    line-height: 28px;
    letter-spacing: 0.83px;
    font-style: normal;
  }

  h3 {
    color: $pitch;
    font-family: Work Sans;
    font-size: 20px;
    line-height: 30px;
    letter-spacing: 0.3x;
  }

  label.label-cc {
    color: $pitch;
    font-family: Work Sans;
    font-size: 18px;
    line-height: 30px;
    letter-spacing: 0.4px;
  }

  a {
    font-family: Work Sans;
    font-size: 18px;
    color: #0170E9;
    letter-spacing: 0.3px;
    line-height: 24px;
    text-decoration: underline;
  }

  // hard coded spacing as per design
  h1 {
    margin-top: 55px;
  }
  h3 {
    margin-top: 52px;
  }
  a {
    display: block;
    margin-top: 42px;
  }

  .form-group {
    display: flex;
    align-items: center;
    flex-direction: row;
    justify-content: space-between;

    label {
      margin-bottom: 0;
    }

    .ozaria-input-field {
      height: 46px;
      width: 231px;

      box-sizing: border-box;
      border: 1px solid $dusk;
      border-radius: 2px;
      background-color: #FFFFFF;

      margin-left: 22px;

      font-family: Work Sans;
      padding-left: 12.5px;
      color: $pitch;
      font-size: 18px;
      line-height: 24px;
      letter-spacing: 0.2px;
    }

    // TODO: Refactor these out to be a standard button across the codebase:
    .ozaria-btn {
      text-shadow: unset;
      font-family: Work Sans, "Open Sans", sans-serif;
      font-size: 16px;
      font-weight: 600;
      letter-spacing: 0.27px;
      line-height: 24px;
      min-height: 40px;
      min-width: 150px;
      margin-left: 14px;
      color: $pitch;
      background-image: unset;
      background-color: $dusk;
      border: unset;

      &:hover {
        background-color: $dusk-dark;
      }
    }
  }
}
</style>
