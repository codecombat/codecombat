<template>
  <div class="start-page center-div">
    <div class="info">
      <div class="lang">
        <label for="language-select">
          Programming Language:
        </label>
        <select
          id="language-select"
          v-model="codeLanguage"
          :disabled="!isNewUser || disableCodeLang"
          class="form-control"
        >
          <option
            v-for="lang in avaliableLanguages"
            :key="lang"
            :value="lang"
            class="lang-option"
          >
            {{ lang[0].toUpperCase() + lang.slice(1) }}
          </option>
        </select>
      </div>
      <div
        v-if="isNewUser"
        class="timer-tip"
      >
        <input
          id="timer-checkbox"
          v-model="timer"
          name="timer"
          type="checkbox"
        >
        <label for="timer-checkbox"> {{ $t('exams.timer_tip') }} </label>
      </div>
    </div>
    <div class="start center-div">
      <input
        :disabled="!hasPermission || !timer"
        type="button"
        :value="buttonValue"
        class="btn btn-lg btn-success"
        @click="localStartExam"
      >
      <div
        v-if="loading"
        class="loading"
      >
        {{ $t('common.loading') }}
      </div>
      <div
        v-if="!hasPermission"
        class="no-permission"
      >
        {{ $t('exams.no_permission') }}
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
const storage = require('app/core/storage')
export default {
  props: {
    examId: {
      type: String,
      required: true,
    },
    codeLang: {
      type: String,
      required: false,
      default: '',
    },
  },
  data () {
    return {
      codeLanguage: 'python',
      timer: false,
      loading: false,
      disableCodeLang: false,
    }
  },
  computed: {
    ...mapGetters('exams', [
      'getExamById',
      'userExam',
    ]),
    exam () {
      return this.getExamById(this.examId)
    },
    avaliableLanguages () {
      return this.exam?.languages || ['python', 'javascript']
    },
    hasPermission () {
      if (this.exam?._id === '-') {
        return true
      }
      if (this.exam?.examInfo?.userTypesAllowed.includes('stem')) {
        if (me.isMtoStem()) {
          return true
        }
      }
      if (this.exam?.examInfo?.userTypesAllowed.includes('neo')) {
        if (me.isMtoNeo()) {
          return true
        }
      }
      return false
    },
    buttonValue () {
      if (this.isNewUser) {
        return $.i18n.t('exams.start_exam')
      } else {
        return $.i18n.t('exams.continue_exam')
      }
    },
    limitedDuration () {
      return this.userExam?.duration || this.exam?.duration
    },
    isNewUser () {
      return !this.userExam
    },
    isOldUser () {
      return this.userExam && !this.userExam.archived
    },
    hasArchivedExam () {
      return this.userExam && this.userExam.archived
    },
    isExamEnded () {
      return this.userExam?.submitted
    },
  },
  mounted () {
    this.checkingUserExam()
    if (this.userExam?.codeLanguage) {
      this.codeLanguage = this.userExam.codeLanguage
    } else if (this.codeLang && this.avaliableLanguages.includes(this.codeLang)) {
      this.codeLanguage = this.codeLang
      this.disableCodeLang = true
    }
  },
  methods: {
    ...mapActions('exams', [
      'startExam',
    ]),
    setupLocalStorage () {
      storage.save(`exam-${me.id}`, this.exam, this.limitedDuration)
    },
    async localStartExam () {
      this.loading = true
      if (this.isExamEnded && !this.hasArchivedExam) {
        noty({
          text: 'Exam has ended',
          type: 'error',
          timeout: 5000,
        })
        this.loading = false
        return
      }
      try {
        if (this.isNewUser) {
          await this.startExam({ examId: this.examId, codeLanguage: this.codeLanguage })
        } else if (this.hasArchivedExam) {
          await this.startExam({ examId: this.examId, codeLanguage: this.codeLanguage, duration: this.userExam.extraDuration })
        }
      } catch (err) {
        noty({
          text: err?.message || 'Start exam failed',
          type: 'error',
          timeout: 5000,
        })
        this.loading = false
        return
      }
      this.setupLocalStorage()
      this.loading = false
      application.router.navigate(window.location.pathname.replace(/start$/, 'progress'), { trigger: true })
    },
    checkingUserExam () {
      if (this.isNewUser) {
        return
      }
      this.timer = true // default value for old users
      if (this.hasArchivedExam) {
        return
      }
      const startDate = new Date(this.userExam.startDate)
      const duration = (new Date().getTime() - startDate.getTime()) / (1000 * 60)
      if (duration >= this.limitedDuration) {
        application.router.navigate(window.location.pathname.replace(/start$/, 'end'), { trigger: true })
      }
    },
  },
}

</script>

<style scoped lang="scss">
.center-div {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 15px;
}
.no-permission {
  margin-top: 10px;
  color: red;
}
.lang {
  display: flex;
  align-items: center;
  gap: 10px;
}
.timer-tip {
  margin-top: 10px;
}
</style>
