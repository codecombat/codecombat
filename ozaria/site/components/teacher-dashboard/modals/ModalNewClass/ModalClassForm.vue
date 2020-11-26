<script>
  import { validationMixin } from 'vuelidate'
  import { required, requiredIf } from 'vuelidate/lib/validators'
  import { mapActions, mapGetters } from 'vuex'

  import GoogleClassroomHandler from 'core/social-handlers/GoogleClassroomHandler'

  import ModalDivider from '../common/ModalDivider'
  import ButtonGoogleClassroom from '../common/ButtonGoogleClassroom'
  import SecondaryButton from '../../common/buttons/SecondaryButton'
  import TertiaryButton from '../../common/buttons/TertiaryButton'

  export default Vue.extend({
    components: {
      ModalDivider,
      ButtonGoogleClassroom,
      SecondaryButton,
      TertiaryButton
    },
    mixins: [validationMixin],
    data: () => ({
      showGoogleClassroom: me.showGoogleClassroom(),
      classLanguage: '',
      className: '',
      classGrades: [],
      googleClassId: '',
      googleClassrooms: null,
      isGoogleClassroomForm: false,
      googleSyncInProgress: false
    }),
    validations: {
      className: {
        required: requiredIf(function () { return !this.isGoogleClassroomForm })
      },
      googleClassId: {
        required: requiredIf(function () { return this.isGoogleClassroomForm })
      },
      classLanguage: {
        required
      },
      classGrades: {
        required
      }
    },
    computed: {
      ...mapGetters({
        courses: 'courses/sorted'
      }),
      isFormValid () {
        return !this.$v.$invalid
      },
      googleClassroomDisabled () {
        return !me.googleClassroomEnabled()
      }
    },
    methods: {
      ...mapActions({
        createClassroom: 'classrooms/createClassroom',
        createFreeCourseInstances: 'courseInstances/createFreeCourseInstances'
      }),
      updateGrades (event) {
        const grade = event.target.name
        if (this.classGrades.includes(grade)) {
          this.classGrades.splice(this.classGrades.indexOf(grade), 1)
        } else {
          this.classGrades.push(grade)
        }
        this.$v.classGrades.$touch()
      },
      async onClickDone () {
        if (this.isFormValid) {
          const eventLabel = this.isGoogleClassroomForm ? 'Google classroom' : 'Manual'
          window.tracker?.trackEvent('Add New Class: Create Clicked', { category: 'Teachers', label: eventLabel })
          const classOptions = {
            aceConfig: {
              language: this.classLanguage
            },
            name: this.className,
            grades: this.classGrades
          }
          if (this.isGoogleClassroomForm) {
            classOptions.googleClassroomId = this.googleClassId
            classOptions.name = this.googleClassrooms.find((c) => c.id === this.googleClassId).name
          }
          try {
            const classroom = await this.createClassroom(classOptions)
            await this.createFreeCourseInstances({ classroom: classroom, courses: this.courses })
            if (this.isGoogleClassroomForm) {
              await GoogleClassroomHandler.markAsImported(this.googleClassId)
              GoogleClassroomHandler.importStudentsToClassroom(classroom)
                .then((importedMembers) => {
                  if (importedMembers.length > 0) {
                    console.debug('Students imported to classroom:', importedMembers)
                  }
                })
                .catch((e) => {
                  noty({ text: 'Error in importing students', layout: 'topCenter', type: 'error', timeout: 2000 })
                })
            }
            window.tracker?.trackEvent('Add New Class: Create Successful', { category: 'Teachers', label: eventLabel })
            this.$emit('done', classroom)
          } catch (e) {
            console.error(e)
            noty({ type: 'error', text: 'Error during classroom creation', layout: 'topCenter', timeout: 2000 })
          }
        }
      },
      async linkGoogleClassroom () {
        window.tracker?.trackEvent('Add New Class: Link Google Classroom Clicked', { category: 'Teachers' })
        this.googleSyncInProgress = true
        await new Promise((resolve, reject) =>
          application.gplusHandler.loadAPI({
            success: resolve,
            error: reject
          }))
        await new Promise((resolve, reject) =>
          application.gplusHandler.connect({
            scope: GoogleClassroomHandler.scopes,
            context: this,
            success: resolve
          }))
        GoogleClassroomHandler.importClassrooms()
          .then(() => {
            this.googleClassrooms = me.get('googleClassrooms').filter((c) => !c.importedToOzaria && !c.deletedFromGC)
            this.isGoogleClassroomForm = true
            window.tracker?.trackEvent('Add New Class: Link Google Classroom Successful', { category: 'Teachers' })
          })
          .catch((e) => {
            noty({ text: $.i18n.t('teachers.error_in_importing_classrooms'), layout: 'topCenter', type: 'error', timeout: 2000 })
          })
        this.googleSyncInProgress = false
      }
    }
  })
</script>

<template>
  <div class="style-ozaria teacher-form">
    <div
      v-if="showGoogleClassroom && !isGoogleClassroomForm"
      class="google-classroom-div"
    >
      <button-google-classroom
        :inactive="googleClassroomDisabled"
        :in-progress="googleSyncInProgress"
        text="Link Google Classroom"
        @click="linkGoogleClassroom"
      />
      <modal-divider />
    </div>
    <form
      class="form-container"
      @submit.prevent="onClickDone"
    >
      <div
        v-if="isGoogleClassroomForm"
        class="form-group row google-class-id"
        :class="{ 'has-error': $v.googleClassId.$error }"
      >
        <div class="col-xs-12">
          <span class="control-label">
            <img
              class="small-google-icon"
              src="/images/ozaria/teachers/dashboard/svg_icons/IconGoogleClassroom.svg"
            >
            {{ $t("teachers.select_class") }}
          </span>
          <select
            v-model="$v.googleClassId.$model"
            class="form-control"
            :class="{ 'placeholder-text': !googleClassId }"
            name="googleClassId"
            :disabled="googleClassrooms.length === 0"
          >
            <option
              v-if="googleClassrooms.length === 0"
              disabled
              selected
              value=""
            >
              All google classrooms already imported
            </option>
            <option
              v-else
              disabled
              selected
              value=""
            >
              Select to Import from Google Classroom
            </option>
            <option
              v-for="classroom in googleClassrooms"
              :key="classroom.id"
              :value="classroom.id"
            >
              {{ classroom.name }}
            </option>
          </select>
          <span
            v-if="!$v.googleClassId.required"
            class="form-error"
          >
            {{ $t("form_validation_errors.required") }}
          </span>
        </div>
      </div>
      <div
        class="form-group row class-language"
        :class="{ 'has-error': $v.classLanguage.$error }"
      >
        <div class="col-xs-12">
          <span class="control-label"> {{ $t("teachers.programming_language") }} </span>
          <select
            v-model="$v.classLanguage.$model"
            class="form-control"
            :class="{ 'placeholder-text': !classLanguage }"
            name="classLanguage"
          >
            <option
              disabled
              selected
              value=""
            >
              {{ $t("teachers.select_desired_lang") }}
            </option>
            <option value="javascript">
              Javascript
            </option>
            <option value="python">
              Python
            </option>
          </select>
          <span
            v-if="!$v.classLanguage.required"
            class="form-error"
          >
            {{ $t("form_validation_errors.required") }}
          </span>
        </div>
      </div>
      <div
        v-if="!isGoogleClassroomForm"
        class="form-group row class-name"
        :class="{ 'has-error': $v.className.$error }"
      >
        <div class="col-xs-12">
          <span class="control-label"> {{ $t("teachers.class_name") }} </span>
          <input
            v-model="$v.className.$model"
            type="text"
            class="form-control"
            name="className"
          >
          <span
            v-if="!$v.className.required"
            class="form-error"
          >
            {{ $t("form_validation_errors.required") }}
          </span>
        </div>
      </div>
      <div
        class="form-group row class-grades"
        :class="{ 'has-error': $v.classGrades.$error }"
      >
        <div class="col-xs-12">
          <span class="control-label"> {{ $t("teachers.grades") }} </span>
          <span class="control-label-desc"> {{ $t("teachers.select_all_that_apply") }} </span>
          <div class="btn-group class-grades-input">
            <button
              type="button"
              class="btn elementary"
              name="elementary"
              :class="{ selected: classGrades.includes('elementary')}"
              @click="updateGrades"
            >
              {{ $t('teachers.elementary') }}
            </button>
            <button
              type="button"
              class="btn middle"
              name="middle"
              :class="{ selected: classGrades.includes('middle')}"
              @click="updateGrades"
            >
              {{ $t('teachers.middle') }}
            </button>
            <button
              type="button"
              class="btn high"
              name="high"
              :class="{ selected: classGrades.includes('high')}"
              @click="updateGrades"
            >
              {{ $t('teachers.high_school') }}
            </button>
          </div>
          <span
            v-if="!$v.classGrades.required"
            class="form-error"
          >
            {{ $t("form_validation_errors.required") }}
          </span>
        </div>
      </div>
      <div class="form-group row">
        <div class="col-xs-12 buttons">
          <tertiary-button
            v-if="isGoogleClassroomForm"
            @click="isGoogleClassroomForm = false"
          >
            {{ $t("common.back") }}
          </tertiary-button>
          <secondary-button
            type="submit"
            :inactive="!isFormValid"
          >
            {{ $t("common.next") }}
          </secondary-button>
        </div>
      </div>
    </form>
  </div>
</template>

<style lang="scss" scoped>
.teacher-form {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  margin: 15px 15px 0px 15px;
}
.google-classroom-div {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}
.form-container {
  width: 100%;
  min-width: 600px;
}
.small-google-icon {
  width: 30px;
  margin-bottom: 5px;
}
.class-grades-input {
  display: block;
}
.elementary {
  border-radius: 0px;
  border: 2px solid #D4B235;
  color: #D4B235;
  &.selected, &:hover {
    background: #D4B235;
    color: #131B25;
  }
}
.middle {
  border-radius: 0px;
  border: 2px solid #74C6DF;
  color: #74C6DF;
  &.selected, &:hover {
    background: #74C6DF;
    color: #131B25;
  }
}
.high {
  border-radius: 0px;
  border: 2px solid #FF8600;
  color: #FF8600;
  &.selected, &:hover {
    background: #FF8600;
    color: #131B25;
  }
}

.buttons {
  display: flex;
  flex-direction: row;
  justify-content: flex-end;
  align-items: flex-end;
  margin-top: 30px;

  button {
    width: 150px;
    height: 35px;
    margin: 0 10px;
  }
}
</style>
