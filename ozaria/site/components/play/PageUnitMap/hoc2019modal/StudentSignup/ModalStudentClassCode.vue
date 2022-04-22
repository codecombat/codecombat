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
        <h1>{{$t("hoc_2019.have_a_class_code")}}</h1>
        <div>
          <p class="student-subtitle">{{ $t("hoc_2019.enter_it_here") }}</p>
          <form @submit.prevent="onSubmitForm">
            <div class="form-group">
              <label class="label-cc" for="class-code-input">{{$t("hoc_2019.class_code")}}</label>
              <input
                id="class-code-input"
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
                {{ $t("common.submit") }}
              </button>
            </div>
          </form>
        </div>

        <div class="or">
          <div class="yellow-bar-1"></div>
          <div class='or-text'><span>{{$t("general.or")}}</span></div>
          <div class="yellow-bar-2"></div>
        </div>

        <div class="text-center">
          <button class="play-now-btn" @click="$emit('closeModal')">{{ $t("new_home.play_now") }}</button>
        </div>
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
    height: 28px;
    width: 247px;
    color: #000000;
    font-family: "Work Sans";
    font-size: 24px;
    font-weight: 600;
    letter-spacing: 0.83px;
    line-height: 28px;
    margin-top: 55px;
    margin-bottom: 30px;
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
      border-radius: 1px;
      background-color: #F7D047;
      border: unset;

      &:hover {
        background-color: $dusk-dark;
      }
    }
  }

  .play-now-btn {
    text-shadow: unset;
    font-family: Work Sans, "Open Sans", sans-serif;
    font-size: 20px;
    font-weight: 600;
    letter-spacing: 0.4px;
    line-height: 24px;

    box-sizing: border-box;
    height: 50px;
    width: 200px;
    border: 1px solid #5DB9AC;
    border-radius: 1px;
    background-color: #5DB9AC;

    margin-bottom: 35px;
    margin-top: 20px;
  }

  .or {
    display: flex;
    flex-direction: row;
    align-items: center;
    margin: 40px 0 40px 0;

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

  .student-subtitle {
    height: 24px;
    width: 433px;
    color: #545B64;
    font-family: "Work Sans";
    font-size: 18px;
    letter-spacing: 0.3px;
    line-height: 24px;
  }
}
</style>
