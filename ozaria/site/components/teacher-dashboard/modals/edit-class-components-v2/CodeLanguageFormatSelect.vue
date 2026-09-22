<template>
  <div class="code-language-format">
    <div
      class="form-group row language"
    >
      <div class="col-xs-12">
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
          v-model="codeLanguage"
          class="form-control"
          :class="{ 'placeholder-text': !codeLanguage }"
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
    </div>

    <div
      v-if="enableBlocks"
      class="form-group row code-format"
    >
      <div class="col-xs-12">
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
                {{ $t("teachers.code_formats_disabled_by", { language: codeLanguageObject[codeLanguage]?.name }) }}
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
                v-model="codeFormats"
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
    </div>

    <div
      v-if="enableBlocks"
      class="form-group row default-code-format"
    >
      <div class="col-xs-12">
        <label for="default-code-format-select">
          <span class="control-label"> {{ $t("teachers.default_code_format") }} </span>
        </label>
        <input
          v-if="enabledCodeFormats.length === 1"
          v-model="codeFormatDefault"
          type="text"
          class="form-control"
          disabled
        >
        <select
          v-else
          id="default-code-format-select"
          v-model="codeFormatDefault"
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
    value: {
      type: Object,
      required: true,
    },
    courses: {
      type: Array,
      default: () => [],
    },
  },
  computed: {
    ...mapGetters({
      getCourseInstances: 'courseInstances/getCourseInstancesOfClass',
    }),
    // Proxies onto the single draft object owned by the parent (this.value) -
    // no local copy, so there is only ever one source of truth for the draft.
    codeLanguage: {
      get () { return this.value.codeLanguage },
      set (val) { this.updateDraft({ codeLanguage: val }) },
    },
    codeFormats: {
      get () { return this.value.codeFormats },
      set (val) { this.updateDraft({ codeFormats: val }) },
    },
    codeFormatDefault: {
      get () { return this.value.codeFormatDefault },
      set (val) { this.updateDraft({ codeFormatDefault: val }) },
    },
    isCodeCombat () {
      return utils.isCodeCombat
    },
    notChapter () {
      return !this.courses.includes(utils.allCourseIDs.CHAPTER_ONE)
    },
    enableBlocks () {
      return this.hasJunior && ['python', 'javascript'].includes(this.codeLanguage || 'python')
    },
    hasOzaria () {
      return this.courses.includes(utils.allCourseIDs.CHAPTER_ONE)
    },
    hasJunior () {
      return this.hasCourse(utils.courseIDs.JUNIOR)
    },
    hasHackstack () {
      return this.hasCourse(utils.courseIDs.HACKSTACK)
    },
    hasOnlyHackstack () {
      const hsCourses = this.courses.filter(c => utils.HACKSTACK_COURSE_IDS.includes(c))
      return this.courses.length === hsCourses.length
    },
    availableCodeFormats () {
      const codeFormats = JSON.parse(JSON.stringify(this.codeFormatObject))
      if (!this.hasJunior) {
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
      return this.availableCodeFormats.filter(cf => !cf.disabled && this.codeFormats.includes(cf.id))
    },
    codeFormatObject () {
      return utils.getCodeFormats()
    },
    codeLanguageObject () {
      return utils.getCodeLanguages()
    },
    availableLanguages () {
      const languages = JSON.parse(JSON.stringify(this.codeLanguageObject))
      delete languages.coffeescript
      delete languages.lua

      if (this.hasOnlyHackstack) {
        for (const lang of Object.values(languages)) {
          lang.disabled = true
        }
      }
      if (this.hasOzaria) {
        delete languages.cpp
        delete languages.java
      }

      return Object.values(languages)
    },
  },
  watch: {
    // Reads/writes are computed from the watcher args rather than re-reading this.codeFormats,
    // since a proxied prop only reflects a write after the parent's next render pass.
    // Every branch is guarded to only updateDraft when the derived value actually differs -
    // this watcher re-fires on any upstream reference churn (e.g. the `courses` prop being a
    // fresh array each render), and an unconditional emit there becomes an infinite render loop:
    // emit -> parent re-renders -> new `courses` array -> watcher fires -> emit -> ...
    availableCodeFormats () {
      const ava = this.availableCodeFormats.filter(cf => !cf.disabled).map(cf => cf.id)
      const filtered = this.codeFormats.filter(cf => ava.includes(cf))
      const newCodeFormats = filtered.length > 0 ? filtered : (ava.length ? [ava[0]] : [])
      const patch = {}
      if (!_.isEqual(newCodeFormats, this.codeFormats)) {
        patch.codeFormats = newCodeFormats
      }
      const effectiveCodeFormats = patch.codeFormats || this.codeFormats
      if (!effectiveCodeFormats.includes(this.codeFormatDefault)) {
        patch.codeFormatDefault = effectiveCodeFormats[0]
      }
      if (Object.keys(patch).length > 0) {
        this.updateDraft(patch)
      }
    },
    // immediate: true so a class that mounts with Junior selected but no blocks-icons
    // (e.g. a fresh aceConfig defaulting to ['text-code']) gets normalized before save,
    // rather than only on a subsequent user-driven change to codeFormats.
    codeFormats: {
      immediate: true,
      handler (newV, oldV) {
        if (_.isEqual(newV, oldV)) {
          return
        }
        if (!newV.includes('blocks-icons') && this.enableBlocks) {
          this.updateDraft({ codeFormats: [...newV, 'blocks-icons'] })
          return
        }
        if (newV.length === 0 && oldV) {
          this.$nextTick(() => {
            this.updateDraft({ codeFormats: oldV })
          })
          return
        }
        if (!newV.includes(this.codeFormatDefault)) {
          this.updateDraft({ codeFormatDefault: newV[0] })
        }
      },
    },
  },
  methods: {
    hasCourse (courseId) {
      return this.courses.includes(courseId)
    },
    updateDraft (patch) {
      this.$emit('input', { ...this.value, ...patch })
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
