<script>
import LayoutSplit from './layout/LayoutSplit'
import CloseModalBar from './layout/CloseModalBar'
import { tryCopy } from 'ozaria/site/common/ozariaUtils'

export default {

  components: {
    LayoutSplit,
    CloseModalBar
  },
  props: {
    classCode: {
      type: String,
      required: true
    }
  },

  computed: {
    classCodeURL () {
      return `${document.location.origin}/hoc?_cc=${this.classCode}`
    }
  },

  methods: {
    copyClassCode () {
      this.$refs.classCodeRef.select()
      tryCopy()
    },

    copyUrl () {
      this.$refs.urlCodeRef.select()
      tryCopy()
    },

    refreshTeacherLogin () {
      window.location.reload()
    }
  }
}
</script>

<template>
  <LayoutSplit :show-back-button="false">
    <CloseModalBar
      style="margin-bottom: -10px;"
      @click="$emit('closeModal')"
    />
    <div id="educator-completed-sign-up">
      <h1>{{ $t("hoc_2019.invite_students") + ":" }}</h1>
      <div class="form-group">
        <label
          class="label-cc"
          for="classCode"
        >{{ $t('hoc_2019.class_code') }}</label>
        <input
          id="class-code-input-field"
          ref="classCodeRef"
          class="ozaria-input-field"
          type="text"

          :value="classCode"

          readonly
        >
        <a @click="copyClassCode"><img src="/images/pages/modal/hoc2019/Copy.png"></a>
      </div>
      <p>{{ $t("hoc_2019.enter_code") }}</p>
      <div class="or">
        <div class="yellow-bar-1" />
        <div class="or-text">
          <span>{{ $t("general.or") }}</span>
        </div>
        <div class="yellow-bar-2" />
      </div>
      <div class="form-group">
        <label
          class="label-cc"
          for="classCode"
        >{{ $t("hoc_2019.class_url") }}</label>
        <input
          ref="urlCodeRef"
          class="ozaria-input-field"

          :value="classCodeURL"
          type="text"

          readonly
        >
        <a @click="copyUrl"><img src="/images/pages/modal/hoc2019/Copy.png"></a>
      </div>
      <p>{{ $t("hoc_2019.share_url") }}</p>
      <div class="text-center">
        <button
          class="ozaria-btn"
          @click="refreshTeacherLogin"
        >
          {{ $t("hoc_2019.start_activity") }}
        </button>
      </div>
    </div>
  </LayoutSplit>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#educator-completed-sign-up {
  width: 590px;
  padding: 0 42px 40px 36px;

  h1 {
    font-family: Work Sans;
    color: $pitch;
    font-size: 24px;
    line-height: 28px;
    letter-spacing: 0.83px;
    margin-top: 0;
    margin-bottom: 30px;
  }
  p {
    font-family: Work Sans;
    color: $color-tertiary-brand;
    font-size: 14px;
    letter-spacing: 0.23px;
    line-height: 16px;
  }

  .form-group {
    display: flex;
    align-items: center;
    flex-direction: row;
    justify-content: space-between;

    label {
      color: $pitch;
      font-family: Work Sans;
      font-size: 18px;
      line-height: 30px;
      letter-spacing: 0.4px;
      margin-bottom: 0;
    }

    .ozaria-input-field {
      height: 46px;
      width: 292px;

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

    img {
      width: 33px;
    }
  }

  // TODO: Refactor these out to be a standard button across the codebase:
  .ozaria-btn {
    text-shadow: unset;
    font-family: Work Sans, "Open Sans", sans-serif;
    font-size: 20px;
    font-weight: 600;
    letter-spacing: 0.4px;
    line-height: 24px;
    min-height: 60px;
    min-width: 261px;

    color: $pitch;
    background-image: unset;
    background-color: $dusk;
    border: unset;

    margin-top: 16px;

    &:hover {
      background-color: $dusk-dark;
    }
  }

  .or {
    display: flex;
    flex-direction: row;
    align-items: center;
    margin-bottom: 10px;

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
</style>
