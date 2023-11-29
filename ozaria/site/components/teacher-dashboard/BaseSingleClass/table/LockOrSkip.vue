<script>
import Datepicker from 'vuejs-datepicker'
import { mapActions, mapGetters, mapMutations } from 'vuex'

import utils from 'app/core/utils'
import LevelAccessStatusButton from '../../common/buttons/LevelAccessStatusButton'

export default {
  components: {
    Datepicker,
    LevelAccessStatusButton
  },
  props: {
    allOriginals: {
      type: Array,
      required: false,
      default: null
    },
    defaultOriginals: {
      type: Array,
      required: false,
      default: () => []
    },
    shown: {
      type: Boolean,
      required: false,
      default: false
    }
  },

  data () {
    return {
      action: { modifiers: [], value: null },
      selectedDate: new Date(),
      showDatepicker: false,
      userSelectedOriginals: null,
      userSelectedStudents: null,
      LOCK: { modifiers: ['locked'], value: true },
      UNLOCK: { modifiers: ['locked'], value: false },
      SKIP: { modifiers: ['locked', 'optional'], value: true },
      UNSKIP: { modifiers: ['locked', 'optional'], value: false },
      MAKE_OPTIONAL: { modifiers: ['optional'], value: true },
      REMOVE_OPTIONAL: { modifiers: ['optional'], value: false }
    }
  },

  computed: {
    ...mapGetters({
      classroom: 'teacherDashboard/getCurrentClassroom',
      selectedCourseId: 'teacherDashboard/getSelectedCourseIdCurrentClassroom',
      selectedStudentIds: 'baseSingleClass/selectedStudentIds',
      selectableStudentIds: 'baseSingleClass/selectableStudentIds',
      selectableOriginals: 'baseSingleClass/selectableOriginals',
      selectedOriginals: 'baseSingleClass/selectedOriginals'
    }),

    originals () {
      return this.defaultOriginals.length ? this.defaultOriginals : this.selectedOriginals
    }
  },

  watch: {
    shown (newValue) {
      if (newValue) {
        if (this.selectedOriginals.length == 0) {
          this.userSelectedOriginals = false
          this.selectAllOriginals()
        } else {
          this.userSelectedOriginals = true
        }
        if (this.selectedStudentIds.length == 0) {
          this.userSelectedStudents = false
          this.selectAllStudentIds()
        } else {
          this.userSelectedStudents = true
        }
      } else {
        if (this.userSelectedOriginals === false) {
          this.deselectAllOriginals()
        }
        if (this.userSelectedStudents === false) {
          this.deselectAllStudentIds()
        }
      }
    }
  },

  methods: {
    ...mapActions({
      updateLevelAccessStatusForSelectedStudents: 'baseSingleClass/updateLevelAccessStatusForSelectedStudents',
      addStudentSelectedId: 'baseSingleClass/addStudentSelectedId',
      removeStudentSelectedId: 'baseSingleClass/removeStudentSelectedId'
    }),

    ...mapMutations({
      replaceSelectedOriginals: 'baseSingleClass/replaceSelectedOriginals',
      updateSelectedOriginals: 'baseSingleClass/updateSelectedOriginals'
    }),

    isActionActive (action) {
      return action.value == this.action.value && action.modifiers.every(modifier => this.action.modifiers.includes(modifier))
    },

    toggleDatepicker () {
      this.showDatepicker = !this.showDatepicker
    },

    submit () {
      this.updateLevelAccessStatus()
      this.deselectAllOriginals()
      this.deselectAllStudentIds()
    },

    updateLevelAccessStatus () {
      const date = (this.action === this.LOCK && this.showDatepicker && this.selectedDate) || null
      this.updateLevelAccessStatusForSelectedStudents({
        classroom: this.classroom,
        currentCourseId: this.selectedCourseId,
        levels: this.originals,
        modifiers: this.action.modifiers,
        onSuccess: () => {
          window.tracker?.trackEvent(`Update LevelAccessStatus ${this.action.modifiers.join(',')}: Success`, {
            category: 'Teachers',
            label: `${utils.courseAcronyms?.[this.selectedCourseId]}`
          })
        },
        modifierValue: this.action.value,
        date
      })
    },
    selectAllOriginals () {
      this.replaceSelectedOriginals(this.allOriginals || this.selectableOriginals)
    },
    deselectAllOriginals () {
      this.replaceSelectedOriginals([])
    },
    selectAllStudentIds () {
      this.selectableStudentIds.forEach(id => this.addStudentSelectedId({ studentId: id }))
    },
    deselectAllStudentIds () {
      this.selectableStudentIds.forEach(id => this.removeStudentSelectedId({ studentId: id }))
    }
  }
}
</script>

<template>
  <div id="lock-or-skip">
    <h3 class="text-h3">
      {{ $t('teacher.edit_student_access_title') }}
    </h3>

    <p class="text-p">
      {{
        $t('teacher.edit_student_access_subtitle', { levels: originals.length, students: selectedStudentIds.length })
      }}
    </p>

    <div class="buttons">
      <LevelAccessStatusButton
        :active="isActionActive(LOCK)"
        :text="$t('teacher_dashboard.lock')"
        icon-name="IconLock"
        @click="action=LOCK"
      />
      <LevelAccessStatusButton
        :active="isActionActive(UNLOCK)"
        :text="$t('teacher_dashboard.unlock')"
        @click="action=UNLOCK"
      />

      <div
        v-if="action===LOCK"
        class="datepicker-container"
      >
        <div class="btn-group btn-toggle btn-group-xs">
          <label>
            <input
              v-model="showDatepicker"
              type="checkbox"
            > {{ $t('teacher_dashboard.lock_until_date') }}
          </label>
          <datepicker
            v-if="showDatepicker"
            v-model="selectedDate"
          />
        </div>
      </div>

      <LevelAccessStatusButton
        :active="isActionActive(SKIP)"
        :text="$t('teacher_dashboard.skip')"
        icon-name="IconSkippedLevel"
        @click="action=SKIP"
      />
      <LevelAccessStatusButton
        :active="isActionActive(UNSKIP)"
        :text="$t('teacher_dashboard.unskip')"
        @click="action=UNSKIP"
      />
      <LevelAccessStatusButton
        :active="isActionActive(MAKE_OPTIONAL)"
        :text="$t('teacher_dashboard.make_optional')"
        icon-name="IconOptionalLevel"
        @click="action=MAKE_OPTIONAL"
      />
      <LevelAccessStatusButton
        :active="isActionActive(REMOVE_OPTIONAL)"
        :text="$t('teacher_dashboard.remove_optional')"
        @click="action=REMOVE_OPTIONAL"
      />
    </div>

    <div class="lock-btn-row">
      <a
        href="#"
        @click="submit"
      >{{ $t('common.submit') }}</a>
    </div>

    <div class="level-access-status-blurb">
      <p>{{ $t('teacher_dashboard.level_access_status_blurb') }}</p>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#lock-or-skip {
  .text-h3 {
    background: #413C55;
    text-align: center;
    padding: 10px;
    font-family: 'Work Sans';
    font-style: normal;
    font-weight: 600;
    font-size: 18px;
    line-height: 94%;
    letter-spacing: 0.333333px;
    color: #FFFFFF;
    margin: -1px;
    border-radius: 6px 6px 0 0;
  }

  .text-p {
    font-family: 'Work Sans';
    font-style: normal;
    font-weight: 400;
    font-size: 14px;
    line-height: 129%;
    letter-spacing: 0.266667px;
    color: #131B25;
    padding: 15px;
  }

  .buttons {
    display: flex;
    flex-wrap: wrap;
    justify-content: space-evenly;
    margin: 10px 0;
    gap: 15px;

    > * {
      width: calc(50% - 15px);
    }

    .datepicker-container {
      width: 80%;
      margin-bottom: 10px;

      .btn-group {
        display: flex;
        justify-content: space-between;
      }
    }

  }

  .lock-btn-row {
    text-align: right;
    padding: 15px;
  }

  .level-access-status-blurb {
    padding: 15px;
  }
}
</style>
