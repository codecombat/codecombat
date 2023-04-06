<script>
import Datepicker from 'vuejs-datepicker'
import { mapActions, mapGetters } from 'vuex'

import utils from 'app/core/utils'
import LevelAccessStatusButton from '../../common/buttons/LevelAccessStatusButton'

export default {
  components: {
    Datepicker,
    LevelAccessStatusButton
  },
  props: {
    defaultOriginals: {
      type: Array,
      required: false,
      default: () => []
    }
  },

  data () {
    return {
      action: { modifiers: [], value: null },
      selectedDate: new Date(),
      showDatepicker: false,
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
      selectedOriginals: 'baseSingleClass/selectedOriginals'
    }),

    originals () {
      return this.defaultOriginals.length ? this.defaultOriginals : this.selectedOriginals
    }
  },

  methods: {
    ...mapActions({
      updateLevelAccessStatusForSelectedStudents: 'baseSingleClass/updateLevelAccessStatusForSelectedStudents',
    }),

    toggleDatepicker () {
      this.showDatepicker = !this.showDatepicker
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
    }
  }
}
</script>

<template>
  <div id="lock-or-skip">
    <h3 class="text-h3">{{ $t('teacher.edit_student_access_title') }}</h3>

    <p class="text-p">
      {{
        $t('teacher.edit_student_access_subtitle', { levels: originals.length, students: selectedStudentIds.length })
      }}
    </p>

    <div class="buttons">
      <LevelAccessStatusButton :active="action===LOCK" @click="action=LOCK" :text="$t('teacher_dashboard.lock')" icon-name="IconLock"/>
      <LevelAccessStatusButton :active="action===UNLOCK" @click="action=UNLOCK" :text="$t('teacher_dashboard.unlock')"/>

      <div class="datepicker-container" v-if="action===LOCK">
        <div class="btn-group btn-toggle btn-group-xs">
          <label>
            <input type="checkbox" v-model="showDatepicker"> {{ $t('teacher_dashboard.lock_until_date') }}
          </label>
          <datepicker v-if="showDatepicker" v-model="selectedDate"></datepicker>
        </div>
      </div>

      <LevelAccessStatusButton :active="action===SKIP" @click="action=SKIP" :text="$t('teacher_dashboard.skip')" icon-name="IconSkippedLevel"/>
      <LevelAccessStatusButton :active="action===UNSKIP" @click="action=UNSKIP" :text="$t('teacher_dashboard.unskip')"/>
      <LevelAccessStatusButton :active="action===MAKE_OPTIONAL" @click="action=MAKE_OPTIONAL" :text="$t('teacher_dashboard.make_optional')"
                               icon-name="IconOptionalLevel"/>
      <LevelAccessStatusButton :active="action===REMOVE_OPTIONAL" @click="action=REMOVE_OPTIONAL"
                               :text="$t('teacher_dashboard.remove_optional')"/>
    </div>

    <div class="lock-btn-row">
      <a @click="updateLevelAccessStatus" href="#">{{ $t('common.submit') }}</a>
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
}
</style>
