<template>
  <div class="form-group row code-language-format">
    <div
      v-if="!hideCodeLanguageAndFormat"
      class="col-xs-12 language"
    >
      <label
        for="form-lang-item"
        class="q-tooltip"
      >
        <span class="control-label"> {{ $t("teachers.programming_language") }} </span>
        <questionmark-view
          v-if="isCodeCombat"
          popover-placement="top"
        >
          <template #popover>
            <p class="help-block small text-navy">
              {{ $t("teachers.hackstack_no_code_language_format") }}
            </p>
          </template>
        </questionmark-view>
      </label>
      <select
        id="form-lang-item"
        v-model="newAce.codeLanguage"
        class="form-control"
        :class="{ 'placeholder-text': !newAce.codeLanguage }"
        name="classLanguage"
        :disabled="availableLanguages?.filter(l => !l.disabled).length === 0"
      >
        <option
          v-for="enabledLanguage in availableLanguages"
          :key="enabledLanguage.id"
          :value="enabledLanguage.id"
          :disabled="enabledLanguage.disabled"
        >
          {{ enabledLanguage.name }}
        </option>
      </select>
      <span
        v-if="!isNewClassroom"
        class="help-block small text-navy"
      >
        {{ $t("teachers.programming_language_edit_desc_new") }}
      </span>
    </div>

    <div
      v-if="isCodeCombat && notChapter && !hideCodeLanguageAndFormat"
      class="code-format col-xs-12"
    >
      <label
        class="code-format-label q-tooltip checkbox-label"
      >
        <span class="control-label"> {{ $t("teachers.code_formats") }} </span>
        <questionmark-view popover-placement="top">
          <template #popover>
            <p
              v-if="!enableBlocks"
              class="help-block small text-navy"
            >
              {{ $t("teachers.code_formats_disabled_by", { language: codeLanguageObject[newAce.codeLanguage]?.name }) }}
            </p>
            <p
              v-if="!hasJunior"
              class="help-block small text-navy"
            >
              {{ $t("teachers.junior_code_format_only") }}
            </p>
            <p
              v-if="hasHackstack"
              class="help-block small text-navy"
            >
              {{ $t("teachers.hackstack_no_code_language_format") }}
            </p>
            <p class="help-block small text-navy">
              {{ $t('teachers.code_formats_mobile') }}
            </p>
            <p class="help-block small text-navy">
              {{ $t('teachers.code_formats_fallback') }}
            </p>
          </template>
        </questionmark-view>
      </label>
      <div class="options">
        <div
          v-for="codeFormat in availableCodeFormats"
          :key="codeFormat.id"
          class="option"
        >
          <label
            class="checkbox-inline"
            :disabled="codeFormat.disabled"
          >
            <input
              v-model="newAce.codeFormats"
              :value="codeFormat.id"
              :disabled="codeFormat.disabled"
              name="codeFormats"
              type="checkbox"
            >
            <span class="option-name">{{ codeFormat.name }}</span>
            <span
              v-if="codeFormat.helpText"
              class="small text-navy"
            >
              ({{ codeFormat.helpText }})
            </span>
          </label>
        </div>
      </div>
      <span class="help-block small text-navy">{{ $t("teachers.code_formats_description") }}</span>
    </div>
    <div
      v-if="isCodeCombat && notChapter"
      class="col-xs-12 default-code-format"
    >
      <label for="default-code-format-select">
        <span class="control-label"> {{ $t("teachers.default_code_format") }} </span>
      </label>
      <input
        v-if="enabledCodeFormats.length === 1"
        v-model="newAce.codeFormatDefault"
        type="text"
        class="form-control"
        disabled
      >
      <select
        v-else
        id="default-code-format-select"
        v-model="newAce.codeFormatDefault"
        class="form-control"
        name="codeFormatDefault"
        :disabled="enabledCodeFormats.length === 0"
      >
        <option
          v-for="codeFormat in enabledCodeFormats"
          :key="codeFormat.id"
          :value="codeFormat.id"
        >
          {{ codeFormat.name }}
        </option>
      </select>
      <span
        v-if="!hasOnlyHackstack"
        class="help-block small text-navy"
      >
        {{ $t("teachers.default_code_format_description") }}
      </span>
      <span
        v-if="hasOnlyHackstack"
        class="help-block small text-navy"
      >
        {{ $t("teachers.hackstack_no_code_language_format") }}
      </span>
    </div>
  </div>
</template>

<script>
import utils from 'core/utils'
import { mapGetters } from 'vuex'
import QuestionmarkView from '../../../../../../app/views/ai-league/QuestionmarkView.vue'

export default {
  name: 'CodeLanguageFormatComponent',
  components: {
    QuestionmarkView,
  },
  props: {
    isNewClassroom: {
      type: Boolean,
      default: false,
    },
    classroomId: {
      type: String,
      default: '',
    },
    asClub: {
      type: Boolean,
      default: false,
    },
    value: {
      type: Object,
      required: true,
    },
    course: {
      type: String,
      default: '',
    },
  },
  data () {
    return {
      newAce: {
        codeLanguage: this.value.codeLanguage || 'python',
        codeFormats: this.value.codeFormats,
        codeFormatDefault: this.value.codeFormatDefault,
      },
    }
  },
  computed: {
    ...mapGetters({
      getCourseInstances: 'courseInstances/getCourseInstancesOfClass',
    }),
    isCodeCombat () {
      return utils.isCodeCombat
    },
    notChapter () {
      return this.course !== utils.allCourseIDs.CHAPTER_ONE
    },
    hideCodeLanguageAndFormat () {
      return this.asClub && ['club-esports', 'club-roblox', 'club-hackstack', 'camp-esports'].includes(this.newClubType)
    },
    enableBlocks () {
      return ['python', 'javascript', 'lua'].includes(this.newAce.codeLanguage || 'python')
    },
    hasJunior () {
      return this.hasCourse(utils.courseIDs.JUNIOR)
    },
    hasHackstack () {
      return this.hasCourse(utils.courseIDs.HACKSTACK)
    },
    hasOnlyHackstack () {
      if (this.isNewClassroom) {
        return this.newInitialFreeCourses.includes(utils.courseIDs.INTRO_TO_AI) && this.newInitialFreeCourses?.length === 1
      } else {
        const courseInstances = this.getCourseInstances(this.classroomId)
        return courseInstances?.every(ci => utils.HACKSTACK_COURSE_IDS.includes(ci.courseID))
      }
    },
    availableCodeFormats () {
      const codeFormats = JSON.parse(JSON.stringify(this.codeFormatObject))
      if (!this.hasJunior) {
        codeFormats['blocks-icons'].disabled = true
      }
      if (!this.enableBlocks) {
        codeFormats['blocks-icons'].disabled = true
        codeFormats['blocks-and-code'].disabled = true
        codeFormats['blocks-text'].disabled = true
      }
      if (this.hasOnlyHackstack) {
        codeFormats['text-code'].disabled = true
        codeFormats['blocks-icons'].disabled = true
        codeFormats['blocks-and-code'].disabled = true
        codeFormats['blocks-text'].disabled = true
      }
      return Object.values(codeFormats)
    },
    enabledCodeFormats () {
      return this.availableCodeFormats.filter(cf => !cf.disabled && this.newAce.codeFormats.includes(cf.id))
    },
    codeFormatObject () {
      return utils.getCodeFormats()
    },
    codeLanguageObject () {
      return utils.getCodeLanguages()
    },
    availableLanguages () {
      const languages = JSON.parse(JSON.stringify(this.codeLanguageObject))
      // ozaria do not have these 2 langs
      delete languages.coffeescript
      delete languages.lua

      if (this.hasOnlyHackstack) {
        for (const lang of Object.values(languages)) {
          lang.disabled = true
        }
      }

      return Object.values(languages)
    },
    initialFreeCourses () {
      if (!this.isCodeCombat) {
        return []
      }
      const freeCocoCourseIDs = [...utils.freeCocoCourseIDs, utils.OZ_COURSE_IDS_MAP.CHAPTER_ONE]
      return [
        ...freeCocoCourseIDs.map(id => {
          const course = this.courses.find(({ _id }) => _id === id)
          if (!course) {
            // computed value uses in template before mounted, so no courses yet
            return {}
          }
          return {
            id,
            name: utils.i18n(course, 'name'),
            blurb: $.i18n.t(`teachers.free_course_blurb_${course.slug}`),
          }
        }),
      ]
    },
  },
  watch: {
    availableCodeFormats () {
      const ava = this.availableCodeFormats.filter(cf => !cf.disabled).map(cf => cf.id)
      const filtered = this.newAce.codeFormats.filter(cf => ava.includes(cf))
      this.newAce.codeFormats = filtered.length > 0 ? filtered : (ava.length ? [ava[0]] : [])
      if (!this.newAce.codeFormats.includes(this.newAce.codeFormatDefault)) {
        this.newAce.codeFormatDefault = this.newAce.codeFormats[0]
      }
    },
    newAce: {
      deep: true,
      handler (newV, oldV) {
        if (this.hasJunior && !newV.codeFormats.includes('blocks-icons') && this.enableBlocks) {
          this.newAce.codeFormats.push('blocks-icons')
          return // change newAce call self again, so prevent multiple $emit
        }
        if (newV.codeFormats.length === 0) {
          this.$nextTick(() => {
            this.newAce.codeFormats = oldV.codeFormats
          })
        }
        if (!newV.codeFormats.includes(newV.codeFormatDefault)) {
          this.newAce.codeFormatDefault = newV.codeFormats[0]
          return
        }
        this.$emit('input', newV)
      },
    },
    newClubType (newVal) {
      if (['camp-junior', 'annual-plan-cn-coco'].includes(newVal)) {
        if (!this.newInitialFreeCourses.includes(utils.courseIDs.JUNIOR)) {
          this.newInitialFreeCourses.push(utils.courseIDs.JUNIOR)
          this.$emit('initialFreeCoursesUpdated', this.newInitialFreeCourses)
        }
      }
    },
  },
  mounted () {
    if (!this.newInitialFreeCourses?.length) {
      if (this.isNewClassroom && this.isCodeCombat) {
        this.newInitialFreeCourses = [utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE]
      } else {
        this.newInitialFreeCourses = Array.isArray(this.selectedInitialFreeCourses)
          ? [...this.selectedInitialFreeCourses]
          : []
      }
    }
  },
  methods: {
    hasCourse (courseId) {
      if (this.isNewClassroom) {
        return this.newInitialFreeCourses.includes(courseId)
      } else {
        return this.getCourseInstances(this.classroomId)?.some(ci => ci.courseID === courseId)
      }
    },
  },
}
</script>

<style lang="scss" scoped>
.initial-free-courses {
  .initial-course-blurb {
    margin-bottom: 0;
  }
}
p.help-block {
  margin-bottom: 0;
}
.q-tooltip {
  display: flex;
  align-items: center;
  gap: 2px;

  ::v-deep .plabel {
    height: 16px;
    width: 16px;
    border-radius: 16px;

    position: relative;
    top: -8px;

    .text-wrapper {
      font-size: 13px;
    }
  }
}
.checkbox-inline {
  input[type=checkbox] {
    margin-top: 8px;
  }
}
.options {
  display: flex;
  flex-wrap: wrap;
  column-gap: 15px;
  row-gap: 5px;

  .help-block {
    margin-bottom: 0;
  }
}
.initial-courses {
  margin-bottom: 5px;
}
.initial-course {
  flex: 0 1 auto;
}
.course-code-language-format {
  > *:not(:last-child) {
    margin-bottom: 15px;
  }
}
.option-name {
  font-size: 0.85em;
}
.checkbox-label {
  margin-bottom: 0;
}
</style>
