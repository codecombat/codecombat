<script>
import { mapActions, mapGetters } from 'vuex'
import Modal from '../../common/Modal'
import SecondaryButton from '../common/buttons/SecondaryButton'
import TertiaryButton from '../common/buttons/TertiaryButton'
import Classroom from 'models/Classroom'
import utils from 'core/utils'
import _ from 'lodash'

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
        newLiveCompletion: true,
        newClassroomItems: true,
        newBlocks: 'hidden',
        newLevelChat: 'none',
        newClassroomDescription: '',
        newAverageStudentExp: '',
        newClassroomType: '',
        newClassDateStart: '',
        newClassDateEnd: '',
        newClassesPerWeek: '',
        newMinutesPerClass: '',            
      }
    },

    computed: {
      ...mapGetters({
        getSessionsMapForClassroom: 'levelSessions/getSessionsMapForClassroom'
      }),
      me () {
        return me
      },
      range () {
        return _.range
      },
      isCodeCombat () {
        return utils.isCodeCombat
      },
      classroomName () {
        return (this.classroom || {}).name
      },
      language () {
        return ((this.classroom || {}).aceConfig || {}).language
      },
      archived () {
        return (this.classroom || {}).archived
      },
      liveCompletion () {
        return _.assign({liveCompletion: true}, (this.classroom || {}).aceConfig).liveCompletion
      },
      classroomItems () {
        return (this.classroom || {}).classroomItems
      },
      blocks () {
        return ((this.classroom || {}).aceConfig || {}).blocks || 'hidden'
      },
      levelChat () {
        return _.assign({levelChat: 'none'}, (this.classroom || {}).aceConfig).levelChat
      },    
      classroomDescription () {
        return (this.classroom || {}).description
      },
      averageStudentExp () {
        return (this.classroom || {}).averageStudentExp
      },
      classroomType () {
        return (this.classroom || {}).type
      },
      classDateStart () {
        return (this.classroom || {}).classDateStart
      },
      classDateEnd () {
        return (this.classroom || {}).classDateEnd
      },
      classesPerWeek () {
        return (this.classroom || {}).classesPerWeek
      },
      minutesPerClass () {
        return (this.classroom || {}).minutesPerClass
      },
    },

    mounted () {
      this.newClassName = this.classroomName
      this.newProgrammingLanguage = this.language
      this.newLiveCompletion = this.liveCompletion
      this.newClassroomItems = this.classroomItems
      this.newBlocks = this.blocks;
      this.newLevelChat = this.levelChat
      this.newClassroomDescription = this.classroomDescription
      this.newAverageStudentExp = this.averageStudentExp
      this.newClassroomType = this.classroomType
      this.newClassDateStart = this.classDateStart
      this.newClassDateEnd = this.classDateEnd
      this.newClassesPerWeek = this.classesPerWeek
      this.newMinutesPerClass = this.minutesPerClass
    },

    methods: {
      ...mapActions({
        updateClassroom: 'classrooms/updateClassroom',
        fetchClassroomSessions: 'levelSessions/fetchForClassroomMembers'
      }),
      archiveClass () {
        this.updateClassroom({ classroom: this.classroom, updates: { archived: true } })
        const classroom = new Classroom(this.classroom)
        classroom.revokeStudentLicenses()
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
        const aceConfig = _.clone((this.classroom || {}).aceConfig || {})
        if (this.newProgrammingLanguage && this.newProgrammingLanguage !== this.language) {
          aceConfig.language = this.newProgrammingLanguage
          updates.aceConfig = aceConfig
        }
        if (this.newLiveCompletion !== this.liveCompletion) {
          aceConfig.liveCompletion = this.newLiveCompletion
          updates.aceConfig = aceConfig
        }
        if (this.newClassroomItems !== this.classroomItems) {
          updates.classroomItems = this.newClassroomItems
        }
        if (this.newBlocks !== this.blocks) {
          aceConfig.blocks = this.newBlocks;
          updates.aceConfig = aceConfig;
        }        
        if (this.newLevelChat !==  this.levelChat) {
          aceConfig.levelChat = this.newLevelChat
          updates.aceConfig = aceConfig
        }
        if (this.newClassroomDescription !== this.classroomDescription) {
          updates.description = this.newClassroomDescription;
        }
        if (this.newAverageStudentExp !== this.averageStudentExp) {
          updates.averageStudentExp = this.newAverageStudentExp;
        }
        if (this.newClassroomType !== this.classroomType) {
          updates.type = this.newClassroomType
        }
        if (this.newClassDateStart !== this.classDateStart) {
          updates.classDateStart = this.newClassDateStart
        }
        if (this.newClassDateEnd !== this.classDateEnd) {
          updates.classDateEnd = this.newClassDateEnd
        }  
        if (this.newClassesPerWeek !== this.classesPerWeek) {
          updates.classesPerWeek = String(this.newClassesPerWeek)
        }
        if (this.newMinutesPerClass !== this.minutesPerClass) {
          updates.minutesPerClass = String(this.newMinutesPerClass)
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
    <div class="style-ozaria teacher-form edit-class container">
      <div class="form-container container">
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
        <div v-if="isCodeCombat" class="form-group row">
          <div class="col-xs-12">
            <label>
              <span class="control-label">{{ $t('courses.classroom_items') }}</span>
              <span class="control-label">: </span>
              <input id="classroom-items" name="classroomItems" v-model="newClassroomItems" type='checkbox' />
            </label>
            <div class="control-label-desc"> {{ $t('teachers.classroom_items_description') }}</div>
          </div>
        </div>     
        <div class="form-group row autoComplete">
          <div class="col-xs-12">
            <span class="control-label"> {{ $t('courses.classroom_live_completion') }}</span>
            <input
              id="liveCompletion"
              v-model="newLiveCompletion"
              type="checkbox"
            >
            <span class="control-label-desc">{{ $t("teachers.classroom_live_completion") }}</span>
          </div>
        </div>
        <div v-if="isCodeCombat" class="form-group row">
          <div class="col-xs-12">
            <span class="control-label"> {{ $t("teachers.classroom_blocks") }} </span>
            <select
              v-model="newBlocks"
              class="form-control"
              id="blocks-select"
              name="blocks"
            >
              <option value="hidden">
                {{ $t("teachers.classroom_blocks_hidden") }}
              </option>
              <option value="opt-in">
                {{ $t("teachers.classroom_blocks_opt_in") }}
              </option>
              <option value="opt-out">
                {{ $t("teachers.classroom_blocks_opt_out") }}
              </option>
            </select>
            <span class="help-block small text-navy">{{ $t("teachers.classroom_blocks_description") }}</span>
          </div>
        </div>
        <div v-if="isCodeCombat" class="form-group row">
          <div class="col-xs-12">
            <span class="control-label"> {{ $t("teachers.classroom_level_chat") }} </span>
            <input
              v-model="newLevelChat"
              type="checkbox"
              id="level-chat"
              name="levelChat"
              value="fixed_prompt_only"
            />
            <span class="help-block small text-navy">{{ $t("teachers.classroom_level_chat_blurb") }}</span>
          </div>
        </div>     
        <div v-if="isCodeCombat" class="form-group row">
          <div class="col-lg-6 col-md-12">
            <label>
              <span class="control-label"> {{ $t("courses.classroom_announcement") }} </span>
              <i class="spl text-muted">{{ $t("signup.optional") }}</i>
              <button class="pick-image-button btn btn-middle btn-forest">{{ $t("common.pick_image") }}</button>
            </label>
            <textarea
              v-model="newClassroomDescription"
              id="classroom-announcement"
              name="description"
              rows="2"
              class="form-control"
            ></textarea>
          </div>
        </div>        
        <div v-if="isCodeCombat" class="form-group row hide">
          <div class="col-lg-6 col-md-12">
            <label>
              <span class="control-label"> {{ $t("courses.avg_student_exp_label") }} </span>
              <i class="spl text-muted">{{ $t("signup.optional") }}</i>
            </label>
            <select
              v-model="newAverageStudentExp"
              id="average-student-exp"
              name="averageStudentExp"
              class="form-control"
            >
              <option value="">{{ $t('courses.avg_student_exp_select') }}</option>
              <option value="none">{{ $t('courses.avg_student_exp_none') }}</option>
              <option value="beginner">{{ $t('courses.avg_student_exp_beginner') }}</option>
              <option value="intermediate">{{ $t('courses.avg_student_exp_intermediate') }}</option>
              <option value="advanced">{{ $t('courses.avg_student_exp_advanced') }}</option>
              <option value="varied">{{ $t('courses.avg_student_exp_varied') }}</option>
            </select>
          </div>
        </div>
        <div v-if="isCodeCombat" class="form-group row">
          <div class="col-lg-6 col-md-12">
            <label for="type">
              <span class="control-label"> {{ $t("courses.class_type_label") }} </span>
              <i v-if="!me.isILK()" class="spl text-muted">{{ $t("signup.optional") }}</i>
            </label>
            <select
              v-model="newClassroomType"
              id="type"
              name="type"
              class="form-control"
            >
              <option value="">{{ $t('courses.avg_student_exp_select') }}</option>
              <option value="in-school">{{ $t('courses.class_type_in_school') }}</option>
              <option value="after-school">{{ $t('courses.class_type_after_school') }}</option>
              <option value="online">{{ $t('courses.class_type_online') }}</option>
              <option value="camp">{{ $t('courses.class_type_camp') }}</option>
              <option value="homeschool">{{ $t('courses.class_type_homeschool') }}</option>
              <option value="other">{{ $t('courses.class_type_other') }}</option>
            </select>
          </div>
        </div>
        <div v-if="isCodeCombat" class="form-group row">
          <div class="col-xs-12">
            <span class="control-label"> {{ $t("courses.estimated_class_dates_label") }} </span>
            <input
              v-model="newClassDateStart"
              type="date"
              class="form-control"
            >
            <span class="spl.spr">{{ $t("courses.student_age_range_to") }}</span>
            <input
              v-model="newClassDateEnd"
              type="date"
              class="form-control"
            >
          </div>
        </div>
        <div v-if="isCodeCombat" class="form-group row">
          <div class="col-sm-5">
            <span class="control-label"> {{ $t("courses.estimated_class_frequency_label") }} </span>
            <select
              v-model="newClassesPerWeek"
              class="form-control"
            >
              <option v-for="i in range(1,6)" :key="i" :value="i">{{ i }}</option>
            </select>
            <span class="help-block small text-navy m-l-1">{{ $t("courses.classes_per_week") }}</span>
          </div>
          <div class="col-sm-5">
            <select
              v-model="newMinutesPerClass"
              class="form-control"
            >
              <option value="<30">&lt;30</option>
              <option value="30">30</option>
              <option value="50">50</option>
              <option value="75">75</option>
              <option value=">75">&gt;75</option>
            </select>
            <span class="help-block small text-navy m-l-1">{{ $t("courses.minutes_per_class") }}</span>
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

  &.container {
    max-width: 100%;
    .row {
      width: 100%;
    }
  }

  .form-group .control-label-desc {
    display: inline-block;
    text-align: justify;
    line-height: 19px;
    margin-top: 3px;
  }
}

.class-name, .language, .autoComplete {
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

#liveCompletion {
  marign-left: 15px;
  height: 18px;
  width: 18px;
}

</style>
