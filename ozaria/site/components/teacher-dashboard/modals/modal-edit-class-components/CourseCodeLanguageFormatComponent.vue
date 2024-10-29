<template>
  <div class="form-group row">
    <div
      v-if="isCodeCombat && isNewClassroom && !asClub"
      class="col-xs-12 initial-free-courses"
    >
      <label class="control-label">
        {{ $t("teachers.initial_free_courses") }}
      </label>
      <div class="initial-courses">
        <div
          v-for="initialFreeCourse in initialFreeCourses"
          :key="initialFreeCourse.id"
          class="initial-course"
        >
          <label
            class="checkbox-inline"
          >
            <input
              v-model="newInitialFreeCourses"
              :value="initialFreeCourse.id"
              type="checkbox"
              name="initialFreeCourses"
            >
            <span class="initial-course-name">
              {{ initialFreeCourse.name }} <questionmark-view popover-placement="top">
                <template #popover><span>{{ initialFreeCourse.blurb }}</span></template>
              </questionmark-view>
            </span>
          </label>
        </div>
      </div>
      <p class="help-block small text-navy">
        {{ $t('teachers.initial_free_courses_description') }}
      </p>
    </div>
    <div
      v-if="!hideCodeLanguageAndFormat"
      class="language"
    >
      <div class="col-xs-12">
        <label for="form-lang-item">
          <span class="control-label"> {{ $t("teachers.programming_language") }} </span>
        </label>
        <select
          id="form-lang-item"
          v-model="newProgrammingLanguage"
          class="form-control"
          :class="{ 'placeholder-text': !newProgrammingLanguage }"
          name="classLanguage"
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
        <span class="help-block small text-navy"> {{ $t("teachers.programming_language_edit_desc_new") }} </span>
      </div>
    </div>

    <div
      v-if="isCodeCombat && !hideCodeLanguageAndFormat"
      class="code-format"
    >
      <div class="col-xs-12">
        <label>
          <span class="control-label"> {{ $t("teachers.code_formats") }} </span>
        </label>
        <div class="form-group">
          <label
            v-for="codeFormat in availableCodeFormats"
            :key="codeFormat.id"
            class="checkbox-inline"
            :disabled="codeFormat.disabled"
          >
            <input
              v-model="newCodeFormats"
              :value="codeFormat.id"
              :disabled="codeFormat.disabled"
              name="codeFormats"
              type="checkbox"
            >
            <span>{{ codeFormat.name }}</span>
          </label>
          <span class="help-block small text-navy">{{ $t("teachers.code_formats_description") }}</span>
          <p
            v-if="!enableBlocks"
            class="help-block small text-navy"
          >
            {{ $t("teachers.code_formats_disabled_by", { language: codeLanguageObject[newProgrammingLanguage]?.name }) }}
          </p>
          <p class="help-block small text-navy">
            {{ $t('teachers.code_formats_mobile') }}
          </p>
          <p class="help-block small text-navy">
            {{ $t('teachers.code_formats_fallback') }}
          </p>
        </div>
      </div>
    </div>
    <div
      v-if="isCodeCombat"
      class="default-code-format"
    >
      <div class="col-xs-12">
        <label for="default-code-format-select">
          <span class="control-label"> {{ $t("teachers.default_code_format") }} </span>
        </label>
        <select
          id="default-code-format-select"
          v-model="newCodeFormatDefault"
          class="form-control"
          name="codeFormatDefault"
        >
          <option
            v-for="codeFormat in enabledCodeFormats"
            :key="codeFormat.id"
            :value="codeFormat.id"
          >
            {{ codeFormat.name }}
          </option>
        </select>
        <span class="help-block small text-navy">{{ $t("teachers.default_code_format_description") }}</span>
      </div>
    </div>
  </div>
</template>

<script>
import utils from 'core/utils'
import { mapGetters } from 'vuex'
import QuestionmarkView from '../../../../../../app/views/ai-league/QuestionmarkView.vue'

export default {
  name: 'CourseCodeLanguageFormatComponent',
  components: {
    QuestionmarkView,
  },
  props: {
    isCodeCombat: {
      type: Boolean,
      required: true,
      default: true,
    },
    isNewClassroom: {
      type: Boolean,
      required: true,
      default: false,
    },
    classroomId: {
      type: String,
      required: true,
      default: '',
    },
    asClub: {
      type: Boolean,
      required: true,
      default: false,
    },
    newClubType: {
      type: String,
      required: true,
      default: '',
    },
    courses: {
      type: Array,
      required: true,
      default: () => [],
    },
    codeFormats: {
      type: Array,
      required: true,
      default: () => [],
    },
    codeFormatDefault: {
      type: String,
      required: true,
      default: '',
    },
    codeLanguage: {
      type: String,
      required: true,
      default: '',
    },
  },
  data () {
    return {
      newInitialFreeCourses: [utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE],
      newProgrammingLanguage: this.codeLanguage || 'python',
      newCodeFormats: this.codeFormats,
      newCodeFormatDefault: this.codeFormatDefault,
    }
  },
  computed: {
    ...mapGetters({
      getCourseInstances: 'courseInstances/getCourseInstancesOfClass',
    }),
    hideCodeLanguageAndFormat () {
      return this.asClub && ['club-esports', 'club-roblox', 'club-hackstack'].includes(this.newClubType)
    },
    enableBlocks () {
      return ['python', 'javascript', 'lua'].includes(this.newProgrammingLanguage || 'python')
    },
    hasJunior () {
      if (this.isNewClassroom) {
        return this.newInitialFreeCourses.includes(utils.courseIDs.JUNIOR)
      } else {
        return this.getCourseInstances(this.classroomId)?.some(ci => ci.courseID === utils.courseIDs.JUNIOR)
      }
    },
    availableCodeFormats () {
      const codeFormats = JSON.parse(JSON.stringify(this.codeFormatObject))
      if (!this.hasJunior) {
        codeFormats['blocks-icons'].disabled = true
      }
      if (!this.enableBlocks) {
        codeFormats['blocks-and-code'].disabled = true
        codeFormats['blocks-text'].disabled = true
      }
      return Object.values(codeFormats)
    },
    enabledCodeFormats () {
      return this.availableCodeFormats.filter(cf => !cf.disabled && this.newCodeFormats.includes(cf.id))
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

      return Object.values(languages)
    },
    initialFreeCourses () {
      if (!this.isCodeCombat) {
        return []
      }
      return [
        ...utils.freeCocoCourseIDs.map(id => {
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
    newProgrammingLanguage (newVal) {
      this.$emit('programmingLanguageUpdated', newVal)
    },
    newInitialFreeCourses (newVal) {
      this.$emit('initialFreeCoursesUpdated', newVal)
    },
    newCodeFormats (newVal) {
      this.$emit('codeFormatsUpdated', newVal)
    },
    newCodeFormatDefault (newVal) {
      this.$emit('codeFormatDefaultUpdated', newVal)
    },
  },
  mounted () {
    console.log('codeFormats mounted', this.newCodeFormats, this.newCodeFormatDefault, this.newProgrammingLanguage, this.codeFormats, this.codeFormatDefault, this.codeLanguage)
  },
}
</script>

<style lang="scss" scoped>
.initial-free-courses {
  margin-bottom: 10px;
  .initial-course-blurb {
    margin-bottom: 0;
  }
  .initial-course-name {
    font-size: 0.85em;
  }
}
p.help-block {
  margin-bottom: 0;
}
.initial-course-name {
  display: flex;
  align-items: center;
  gap: 2px;

  ::v-deep .plabel {
    height: 14px;
    width: 14px;
    border-radius: 14px;

    position: relative;
    top: -8px;

    .text-wrapper {
      font-size: 12px;
    }
  }
}
.checkbox-inline {
  input[type=checkbox] {
    margin-top: 8px;
  }
}
.initial-courses {
  display: flex;
  flex-wrap: wrap;
  gap: 15px;

  margin-bottom: 5px;
}
.initial-course {
  flex: 0 1 auto;
}
</style>
