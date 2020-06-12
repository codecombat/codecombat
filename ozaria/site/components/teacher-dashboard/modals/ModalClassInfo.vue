<script>
  import PrimaryButton from '../common/buttons/PrimaryButton'
  import SecondaryButton from '../common/buttons/SecondaryButton'
  import { tryCopy } from 'ozaria/site/common/ozariaUtils'

  import ButtonGoogleClassroom from './common/ButtonGoogleClassroom'
  import ModalDivider from './common/ModalDivider'

  export default Vue.extend({
    components: {
      PrimaryButton,
      SecondaryButton,
      ButtonGoogleClassroom,
      ModalDivider
    },
    props: {
      classroomCode: {
        type: String,
        default: '',
        required: true
      },
      classroom: {
        type: Object,
        default: () => {}
      },
      showGoogleClassroom: {
        type: Boolean,
        default: false
      }
    },
    computed: {
      classroomUrl () {
        return `${document.location.origin}/students?_cc=${this.classroomCode}`
      }
    },
    methods: {
      copyCode () {
        this.$refs['classCode'].select()
        tryCopy()
        noty({ type: 'info', text: 'Link copied to clipboard', layout: 'topCenter', timeout: 2000 })
      },
      copyUrl () {
        this.$refs['classUrl'].select()
        tryCopy()
        noty({ type: 'info', text: 'Link copied to clipboard', layout: 'topCenter', timeout: 2000 })
      }
    }
  })
</script>

<template>
  <div class="style-ozaria teacher-form">
    <div
      v-if="showGoogleClassroom"
      class="google-classroom-div"
    >
      <button-google-classroom
        text="Sync Google Classroom"
        @click="$emit('syncGoogleClassroom')"
      />
      <modal-divider />
    </div>
    <div class="form-container">
      <span class="sub-title"> {{ $t("teachers.class_info_modal_sub_title") }} </span>
      <div class="class-code">
        <span class="form-label"> {{ $t("teachers.class_code") }} </span>
        <div class="form-input">
          <input
            ref="classCode"
            type="text"
            class="form-control"
            :value="classroomCode"
            readonly
          >
          <img
            class="copy-icon"
            src="/images/ozaria/teachers/dashboard/svg_icons/IconCopy.svg"
            @click="copyCode"
          >
        </div>
      </div>
      <span class="sub-text"> {{ $t("teachers.class_code_desc") }} </span>
      <div class="class-url">
        <span class="form-label"> {{ $t("teachers.class_url") }} </span>
        <div class="form-input">
          <input
            ref="classUrl"
            type="text"
            class="form-control"
            :value="classroomUrl"
            readonly
          >
          <img
            class="copy-icon"
            src="/images/ozaria/teachers/dashboard/svg_icons/IconCopy.svg"
            @click="copyUrl"
          >
        </div>
      </div>
      <span class="sub-text"> {{ $t("teachers.class_url_desc") }} </span>
      <primary-button
        class="invite-button"
        @click="$emit('inviteStudents')"
      >
        {{ $t("teachers.invite_by_email") }}
      </primary-button>
    </div>
    <secondary-button
      class="done-button"
      @click="$emit('done')"
    >
      {{ $t("common.done") }}
    </secondary-button>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/ozaria/_ozaria-style-params.scss";
.teacher-form {
  margin: 20px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}
.form-container {
  margin-bottom: 170px;
}

.google-classroom-div {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.sub-title {
  @include font-p-2-paragraph-medium-gray;
}

.class-code, .class-url {
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: flex-start;
  margin-top: 20px;
}

.form-label {
  @include font-h-4-nav-uppercase-black;
  width: 30%;
  text-align: left;
}
.form-input {
  margin-left: 20px;
  display: flex;
  width: 410px;
}
.copy-icon {
  height: 30px;
  cursor: pointer;
  margin: 0px 20px;
}
.sub-text {
  @include font-p-4-paragraph-smallest-gray;
}
.invite-button {
  display: block;
  width: 190px;
  height: 35px;
  margin-top: 20px;
}

.done-button {
  width: 150px;
  height: 35px;
  align-self: flex-end;
}
</style>
