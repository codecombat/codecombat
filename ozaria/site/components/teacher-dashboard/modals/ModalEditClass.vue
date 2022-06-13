<script>
  import { mapActions, mapGetters } from 'vuex'
  import Modal from '../../common/Modal'
  import SecondaryButton from '../common/buttons/SecondaryButton'
  import TertiaryButton from '../common/buttons/TertiaryButton'

  export default Vue.extend({
    components: {
      Modal,
      SecondaryButton,
      TertiaryButton
    },

    props: {
      classroom: {
        type: Object,
        required: true,
        default: () => {}
      }
    },

    data: () => {
      return {
        newClassName: '',
        newProgrammingLanguage: '',
      }
    },

    computed: {
      ...mapGetters({
        getSessionsMapForClassroom: 'levelSessions/getSessionsMapForClassroom'
      }),
      classroomName () {
        return (this.classroom || {}).name
      },
      language () {
        return ((this.classroom || {}).aceConfig || {}).language
      },
      archived () {
        return (this.classroom || {}).archived
      }
    },

    mounted () {
      this.newClassName = this.classroomName
      this.newProgrammingLanguage = this.language
    },

    methods: {
      ...mapActions({
        updateClassroom: 'classrooms/updateClassroom',
        fetchClassroomSessions: 'levelSessions/fetchForClassroomMembers'
      }),
      archiveClass () {
        noty({
          text: "If you haven't done so already, please revoke your students' licenses before archiving the class so that you can re-apply them to other students. Please confirm that you’d like to proceed:",
          type: 'info',
          layout: 'center',
          buttons: [
            { text: 'Cancel', onClick: ($noty) => $noty.close() },
            { text: 'Archive',
              onClick: ($noty) => {
                this.updateClassroom({ classroom: this.classroom, updates: { archived: true } })
                $noty.close()
              }
            }
          ]
        })
        this.$emit('close')
      },
      unarchiveClass () {
        this.updateClassroom({ classroom: this.classroom, updates: { archived: false } })
        if (!this.getSessionsMapForClassroom(this.classroom._id)) {
          this.fetchClassroomSessions({ classroom: this.classroom })
        }
        this.$emit('close')
      },
      saveClass () {
        const updates = {}
        if (this.newClassName && this.newClassName !== this.classroomName) {
          updates.name = this.newClassName
        }
        if (this.newProgrammingLanguage && this.newProgrammingLanguage !== this.language) {
          const aceConfig = _.clone((this.classroom || {}).aceConfig || {})
          aceConfig.language = this.newProgrammingLanguage
          updates.aceConfig = aceConfig
        }
        if (_.size(updates)) {
          this.updateClassroom({ classroom: this.classroom, updates: updates })
          this.$emit('close')
        }
      }
    }
  })
</script>

<template>
  <modal
    title="Edit Class Information"
    @close="$emit('close')"
  >
    <div class="style-ozaria teacher-form edit-class">
      <div class="form-container">
        <div class="form-group row class-name">
          <div class="col-xs-12">
            <span class="control-label"> {{ $t("teachers.class_name") }} </span>
            <input
              v-model="newClassName"
              type="text"
              class="form-control"
            >
          </div>
        </div>
        <div class="form-group row language">
          <div class="col-xs-12">
            <span class="control-label"> {{ $t("teachers.programming_language") }} </span>
            <select
              v-model="newProgrammingLanguage"
              class="form-control"
              name="classLanguage"
            >
              <option value="javascript">
                JavaScript
              </option>
              <option value="python">
                Python
              </option>
            </select>
            <span class="control-label-desc"> {{ $t("teachers.programming_language_edit_desc_new") }} </span>
          </div>
        </div>
        <div class="form-group row buttons">
          <div class="col-xs-12 buttons">
            <tertiary-button
              v-if="archived"
              @click="unarchiveClass"
            >
              <img src="/images/ozaria/teachers/dashboard/svg_icons/IconUnarchive.svg">
              {{ $t("teacher.unarchive_class") }}
            </tertiary-button>
            <tertiary-button
              v-if="!archived"
              @click="archiveClass"
            >
              <img src="/images/ozaria/teachers/dashboard/svg_icons/IconArchive.svg">
              {{ $t("teacher.archive_class") }}
            </tertiary-button>
            <secondary-button
              @click="saveClass"
            >
              {{ $t("common.save_changes") }}
            </secondary-button>
          </div>
        </div>
      </div>
    </div>
  </modal>
</template>

<style lang="scss" scoped>
@import "app/styles/ozaria/_ozaria-style-params.scss";

.edit-class {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  margin: 15px 15px 0px 15px;
  width: 600px;
}

.form-container {
  width: 100%;
  min-width: 600px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;

  .form-group .control-label-desc {
    display: inline-block;
    text-align: justify;
    line-height: 19px;
    margin-top: 3px;
  }
}

.class-name, .language {
  width: 100%;
}

.language input {
  text-transform: capitalize;
}

.buttons {
  align-self: flex-end;
  display: flex;
  margin-top: 15px;

  button {
    width: 180px;
    height: 35px;
    margin: 0 10px;
    text-transform: capitalize;
    display: flex;
    align-items: center;
    justify-content: space-evenly;
  }
}

</style>
