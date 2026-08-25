<template>
  <div>
    <div
      v-if="isOzaria"
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
            :class="{ selected: grades.includes('elementary')}"
            @click="updateGrades"
          >
            {{ $t('teachers.elementary') }}
          </button>
          <button
            type="button"
            class="btn middle"
            name="middle"
            :class="{ selected: grades.includes('middle')}"
            @click="updateGrades"
          >
            {{ $t('teachers.middle') }}
          </button>
          <button
            type="button"
            class="btn high"
            name="high"
            :class="{ selected: grades.includes('high')}"
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
          v-model="classroomItems"
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
          v-model="disablePaste"
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
          v-model="liveCompletion"
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
          v-model="remix"
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
          v-model="levelChat"
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
          v-model="classroomDescription"
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
          v-model="averageStudentExp"
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
      v-if="moreOptions && isCodeCombat"
      class="form-group row"
    >
      <div class="col-md-12">
        <label for="type">
          <span class="control-label"> {{ $t("courses.class_type_label") }} </span>
        </label>
        <select
          id="type"
          v-model="classroomType"
          name="type"
          class="form-control"
        >
          <option value="">
            {{ $t('courses.avg_student_exp_select') }}
          </option>
          <option
            value="in-school"
          >
            {{ $t('courses.class_type_in_school') }}
          </option>
          <option value="after-school">
            {{ $t('courses.class_type_after_school') }}
          </option>
          <option
            value="online"
          >
            {{ $t('courses.class_type_online') }}
          </option>
          <option
            value="camp"
          >
            {{ $t('courses.class_type_camp') }}
          </option>
          <option
            value="homeschool"
          >
            {{ $t('courses.class_type_homeschool') }}
          </option>
          <option
            value="other"
          >
            {{ $t('courses.class_type_other') }}
          </option>
        </select>
      </div>
    </div>
    <class-start-end-date-component
      v-if="moreOptions && isCodeCombat"
      :class-date-start="classDateStart"
      :class-date-end="classDateEnd"
      @classDateStartUpdated="updateClassDateStart"
      @classDateEndUpdated="updateClassDateEnd"
    />
    <div
      v-if="moreOptions && isCodeCombat"
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
            v-model="classesPerWeek"
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
            v-model="minutesPerClass"
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
    value: {
      type: Object,
      required: true,
    },
  },
  data () {
    return {
      // Local UI-only state - whether the advanced section is expanded, not part of the draft.
      moreOptions: false,
    }
  },
  computed: {
    // Proxies onto the single draft object owned by the parent (this.value) -
    // no local copy, so there is only ever one source of truth for the draft.
    classroomItems: {
      get () { return this.value.classroomItems },
      set (val) { this.updateDraft({ classroomItems: val }) },
    },
    disablePaste: {
      get () { return this.value.disablePaste },
      set (val) { this.updateDraft({ disablePaste: val }) },
    },
    liveCompletion: {
      get () { return this.value.liveCompletion },
      set (val) { this.updateDraft({ liveCompletion: val }) },
    },
    remix: {
      get () { return this.value.remix },
      set (val) { this.updateDraft({ remix: val }) },
    },
    levelChat: {
      get () { return this.value.levelChat },
      set (val) { this.updateDraft({ levelChat: val }) },
    },
    classroomDescription: {
      get () { return this.value.classroomDescription },
      set (val) { this.updateDraft({ classroomDescription: val }) },
    },
    averageStudentExp: {
      get () { return this.value.averageStudentExp },
      set (val) { this.updateDraft({ averageStudentExp: val }) },
    },
    classroomType: {
      get () { return this.value.classroomType },
      set (val) { this.updateDraft({ classroomType: val }) },
    },
    classesPerWeek: {
      get () { return this.value.classesPerWeek },
      set (val) { this.updateDraft({ classesPerWeek: val }) },
    },
    minutesPerClass: {
      get () { return this.value.minutesPerClass },
      set (val) { this.updateDraft({ minutesPerClass: val }) },
    },
    classDateStart: {
      get () { return this.value.classDateStart },
      set (val) { this.updateDraft({ classDateStart: val }) },
    },
    classDateEnd: {
      get () { return this.value.classDateEnd },
      set (val) { this.updateDraft({ classDateEnd: val }) },
    },
    grades: {
      get () { return this.value.grades || [] },
      set (val) { this.updateDraft({ grades: val }) },
    },
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
  methods: {
    updateDraft (patch) {
      this.$emit('input', { ...this.value, ...patch })
    },
    updateGrades (event) {
      const grade = event.target.name
      this.grades = this.grades.includes(grade)
        ? this.grades.filter(g => g !== grade)
        : [...this.grades, grade]
    },
    updateClassDateStart (newV) {
      this.classDateStart = newV
    },
    updateClassDateEnd (newV) {
      this.classDateEnd = newV
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
