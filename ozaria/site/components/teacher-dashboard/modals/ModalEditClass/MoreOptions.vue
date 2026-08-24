<template>
  <div>
    <div
      v-if="isOzaria && !me.isCodeNinja()"
      class="form-group row class-grades"
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
      </div>
    </div>
    <div
      v-if="moreOptions && isCodeCombat"
      class="form-group row classroom-items"
    >
      <div class="col-xs-12">
        <label for="classroom-items">
          <span class="control-label">{{ $t('courses.classroom_items') }}:</span>
        </label>
        <input
          id="classroom-items"
          v-model="newClass.classroomItems"
          name="classroomItems"
          type="checkbox"
        >
        <div class="help-block small text-navy">
          {{ $t('teachers.classroom_items_description') }}
        </div>
      </div>
    </div>
    <div
      v-if="moreOptions"
      class="form-group row disable-paste"
    >
      <div class="col-xs-12">
        <label for="paste">
          <span class="control-label"> {{ $t('courses.classroom_disable_paste') }}</span>
        </label>
        <input
          id="paste"
          v-model="newClass.disablePaste"
          type="checkbox"
        >
        <span class="help-block small text-navy">{{ $t("teachers.classroom_disable_paste") }}</span>
      </div>
    </div>
    <div
      v-if="moreOptions"
      class="form-group row autoComplete"
    >
      <div class="col-xs-12">
        <label for="liveCompletion">
          <span class="control-label"> {{ $t('courses.classroom_live_completion') }}</span>
        </label>
        <input
          id="liveCompletion"
          v-model="newClass.liveCompletion"
          type="checkbox"
        >
        <span class="help-block small text-navy">{{ $t("teachers.classroom_live_completion") }}</span>
      </div>
    </div>
    <div
      v-if="moreOptions && isCodeCombat"
      class="form-group row remix"
    >
      <div class="col-xs-12">
        <label for="remix">
          <span class="control-label"> {{ $t("teachers.ai_hs_remix") }} </span>
        </label>
        <input
          id="remix"
          v-model="newClass.remix"
          type="checkbox"
          name="remix"
        >
        <span class="help-block small text-navy">{{ $t("teachers.ai_hs_remix_blurb") }}</span>
      </div>
    </div>
    <div
      v-if="moreOptions"
      class="form-group row level-chat"
    >
      <div class="col-xs-12">
        <label for="level-chat">
          <span class="control-label"> {{ $t("teachers.classroom_level_chat") }} </span>
        </label>
        <input
          id="level-chat"
          v-model="newClass.levelChat"
          type="checkbox"
          name="levelChat"
        >
        <span class="help-block small text-navy">{{ $t("teachers.classroom_level_chat_blurb") }}</span>
      </div>
    </div>
    <div
      v-if="moreOptions && isCodeCombat"
      class="form-group row announcement"
    >
      <div class="col-md-12">
        <label>
          <span class="control-label"> {{ $t("courses.classroom_announcement") }} </span>
          <i class="spl text-muted">{{ $t("signup.optional") }}</i>
          <button class="pick-image-button btn btn-middle btn-forest">{{ $t("common.pick_image") }}</button>
        </label>
        <textarea
          id="classroom-announcement"
          v-model="newClass.classroomDescription"
          name="description"
          rows="2"
          class="form-control"
        />
      </div>
    </div>
    <div
      v-if="moreOptions && isCodeCombat"
      class="form-group row hide"
    >
      <div class="col-md-12">
        <label>
          <span class="control-label"> {{ $t("courses.avg_student_exp_label") }} </span>
          <i class="spl text-muted">{{ $t("signup.optional") }}</i>
        </label>
        <select
          id="average-student-exp"
          v-model="newClass.averageStudentExp"
          name="averageStudentExp"
          class="form-control"
        >
          <option value="">
            {{ $t('courses.avg_student_exp_select') }}
          </option>
          <option value="none">
            {{ $t('courses.avg_student_exp_none') }}
          </option>
          <option value="beginner">
            {{ $t('courses.avg_student_exp_beginner') }}
          </option>
          <option value="intermediate">
            {{ $t('courses.avg_student_exp_intermediate') }}
          </option>
          <option value="advanced">
            {{ $t('courses.avg_student_exp_advanced') }}
          </option>
          <option value="varied">
            {{ $t('courses.avg_student_exp_varied') }}
          </option>
        </select>
      </div>
    </div>
    <div
      v-if="!asClub && (moreOptions && isCodeCombat || me.isCodeNinja())"
      class="form-group row"
    >
      <div class="col-md-12">
        <label for="type">
          <span class="control-label"> {{ $t("courses.class_type_label") }} </span>
          <i
            v-if="!me.isILK()"
            class="spl text-muted"
          >{{ $t("signup.optional") }}</i>
        </label>
        <select
          id="type"
          v-model="newClass.classroomType"
          name="type"
          class="form-control"
        >
          <option value="">
            {{ $t('courses.avg_student_exp_select') }}
          </option>
          <option
            v-if="!me.isCodeNinja()"
            value="in-school"
          >
            {{ $t('courses.class_type_in_school') }}
          </option>
          <option value="after-school">
            {{ $t('courses.class_type_after_school') }}
          </option>
          <option
            v-if="!me.isCodeNinja()"
            value="online"
          >
            {{ $t('courses.class_type_online') }}
          </option>
          <option
            v-if="!me.isCodeNinja()"
            value="camp"
          >
            {{ $t('courses.class_type_camp') }}
          </option>
          <option
            v-if="!me.isCodeNinja()"
            value="homeschool"
          >
            {{ $t('courses.class_type_homeschool') }}
          </option>
          <option
            v-if="!me.isCodeNinja()"
            value="other"
          >
            {{ $t('courses.class_type_other') }}
          </option>
        </select>
      </div>
    </div>
    <class-start-end-date-component
      v-if="!asClub && (moreOptions && isCodeCombat || me.isCodeNinja())"
      :class-date-start="newClass.classDateStart"
      :class-date-end="newClass.classDateEnd"
      @classDateStartUpdated="updateClassDateStart"
      @classDateEndUpdated="updateClassDateEnd"
    />
    <div
      v-if="moreOptions && isCodeCombat && !me.isCodeNinja()"
      class="form-group row"
    >
      <div class="col-sm-12">
        <label for="form-new-classes-per-week">
          <span class="control-label"> {{ $t("courses.estimated_class_frequency_label") }} </span>
        </label>
      </div>
      <div class="col-sm-12 new-classes-per-week-container">
        <div>
          <select
            id="form-new-classes-per-week"
            v-model="newClass.classesPerWeek"
            class="form-control"
          >
            <option
              v-for="i in range(1,6)"
              :key="i"
              :value="i"
            >
              {{ i }}
            </option>
          </select>
          <span class="help-block small text-navy m-l-1">{{ $t("courses.classes_per_week") }}</span>
        </div>
        <div>
          <select
            v-model="newClass.minutesPerClass"
            class="form-control"
          >
            <option value="<30">
              &lt;30
            </option>
            <option value="30">
              30
            </option>
            <option value="50">
              50
            </option>
            <option value="75">
              75
            </option>
            <option value=">75">
              &gt;75
            </option>
          </select>
          <span class="help-block small text-navy m-l-1">{{ $t("courses.minutes_per_class") }}</span>
        </div>
      </div>
    </div>
    <div
      class="more-options-text-container"
    >
      <!-- eslint-disable vue/no-v-html -->
      <a
        href="#"
        class="more-options-text"
        @click.prevent="toggleMoreOptions"
      >
        {{ $t('courses.more_options') }}
        <span v-html="moreOptionsIcon" />
      </a>
      <!--eslint-enable-->
    </div>
  </div>
</template>

<script>
import utils from 'core/utils'
import ClassStartEndDateComponent from '../modal-edit-class-components/ClassStartEndDateComponent'
export default {
  components: {
    ClassStartEndDateComponent,
  },
  props: {
    classroom: {
      type: Object,
      required: true,
    },
    asClub: {
      type: Boolean,
      default: false,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  data () {
    const cItems = this.classroom?.classroomItems ?? this.value.classroomItems
    const cLiveCompletion = this.classroom?.aceConfig?.liveCompletion ?? this.value.liveCompletion
    const cDisablePaste = this.classroom?.aceConfig?.disablePaste ?? this.value.disablePaste
    const cLevelChat = this.classroom?.aceConfig?.levelChat ?? this.value.levelChat
    const cGrades = this.classroom?.grades || []
    return {
      moreOptions: false,
      newClass: {
        classroomItems: typeof cItems === 'undefined' ? true : cItems,
        disablePaste: typeof cDisablePaste === 'undefined' ? false : cDisablePaste,
        liveCompletion: typeof cLiveCompletion === 'undefined' ? true : cLiveCompletion,
        remix: this.classroom?.hackstackConfig?.remixAllowed || false,
        levelChat: typeof cLevelChat === 'undefined' ? true : cLevelChat === 'fixed_prompt_only',
        classroomDescription: this.classroom?.description || '',
        averageStudentExp: this.classroom?.averageStudentExp || '',
        classroomType: this.classroom?.type || '',
        classesPerWeek: this.classroom?.classesPerWeek || '',
        minutesPerClass: this.classroom?.minutesPerClass || '',
        classDateStart: this.classroom?.classDateStart || '',
        classDateEnd: this.classroom?.classDateEnd || '',
        classGrades: (utils.isOzaria && !me.isCodeNinja()) ? cGrades : null,
      },
    }
  },
  computed: {
    range () {
      return _.range
    },
    isCodeCombat () {
      return utils.isCodeCombat
    },
    me () {
      return window.me
    },
    isOzaria () {
      return utils.isOzaria
    },
    moreOptionsIcon () {
      return this.moreOptions ? '&nbsp;&and;' : '&nbsp;&or;'
    },

  },
  watch: {
    newClass: {
      deep: true,
      handler (newV) {
        this.$emit('input', newV)
      },
    },
  },
  methods: {
    updateGrades (event) {
      const grade = event.target.name
      if (this.classGrades.includes(grade)) {
        this.classGrades.splice(this.classGrades.indexOf(grade), 1)
      } else {
        this.classGrades.push(grade)
      }
      this.$set(this.newClass, 'grades', this.classGrades)
    },
    updateClassDateStart (newV) {
      this.$set(this.newClass, 'classDateStart', newV)
    },
    updateClassDateEnd (newV) {
      this.$set(this.newClass, 'classDateEnd', newV)
    },
    toggleMoreOptions () {
      this.moreOptions = !this.moreOptions
    },
  },
}
</script>
<style lang="scss" scoped>
.more-options-text-container {
  margin-bottom: -5px;
  margin-top: -5px;
  display: flex;
  justify-content: center;
}

.more-options-text {
  font-size: 15px;

  span {
    font-size: 18px;
    line-height: 15px;
  }
}
</style>
