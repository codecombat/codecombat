<!-- NOTE this is code language select for teacher-dashboard -->
<!-- for student/home user side refer to: app/views/play/common/changeLanguageTab -->
<template>
  <div class="code-language-dropdown">
    <span class="select-language">{{ $t('courses.select_language') }}</span>
    <select @change="changeLanguage">
      <option
        v-for="(text, lang) in languages"
        :key="lang"
        :value="lang"
        :selected="getSelectedLanguage === lang"
      >
        {{ text }}
      </option>
    </select>
  </div>
</template>
<script>
import { mapMutations, mapGetters } from 'vuex'
import utils from 'core/utils'
export default {
  props: {
    courseName: {
      type: String,
      default: '',
    },
  },
  computed: {
    ...mapGetters({
      getSelectedLanguage: 'baseCurriculumGuide/getSelectedLanguage',
    }),
    languages () {
      const base = {
        python: 'Python',
        javascript: 'JavaScript',
      }
      if (this.courseName === 'Junior' || utils.isOzaria) {
        return base
      }
      return {
        ...base,
        cpp: 'C++',
        java: 'Java',
      }
    },
  },
  watch: {
    courseName (v) {
      if (v === 'Junior') {
        if (['cpp', 'java'].includes(this.getSelectedLanguage)) {
          this.setSelectedLanguage('python')
        }
      }
    },
  },
  methods: {
    ...mapMutations({
      setSelectedLanguage: 'baseCurriculumGuide/setSelectedLanguage',
    }),
    changeLanguage (e) {
      this.setSelectedLanguage(e.target.value)
      this.$emit('change-language')
    },
  },
}
</script>
