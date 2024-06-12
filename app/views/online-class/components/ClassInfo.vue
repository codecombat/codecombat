<template>
  <div>
    <div class="form">
      <div class="form-group">
        <label>Code Language:</label>
        <select
          v-model="codeLanguage"
          name="codeLanguage"
          class="form-control"
        >
          <option
            v-for="lang in codeLanguages"
            :key="`cl-${lang}`"
            :value="lang"
          >
            {{ codeLanguageMap[lang] }}
          </option>
        </select>
      </div>
      <label>Coding Levels:</label>
      <div class="form-group">
        <select
          v-model="level"
          name="level"
          class="form-control"
        >
          <option
            v-for="l in levels"
            :key="`cl-${codeLanguage}-level-${l}`"
            :value="l"
          >
            {{ l }}
          </option>
        </select>
      </div>
      <label>Spoken Langauge:</label>
      <div class="form-group">
        <select
          v-model="language"
          name="language"
          class="form-control"
        >
          <option
            v-for="lang in languages"
            :key="`l-${lang}`"
            :value="lang"
          >
            {{ lang }}
          </option>
        </select>
      </div>
      <div class="buttons">
        <button
          class="btn btn-primary"
          :disabled="!codeLanguage || !level || !language"
          @click="emitInfo"
        >
          Show Available Times
        </button>
      </div>
    </div>
  </div>
</template>
<script>
import schema from '../../../schemas/models/online_teacher'
export default {
  name: 'ClassInfo',
  props: {
    codeLanguageMap: {
      type: Object,
      required: true
    },
    levels: {
      type: Array,
      required: true
    }
  },
  data () {
    return {
      codeLanguage: '',
      level: '',
      language: 'English',
    }
  },
  computed: {
    codeLanguages () {
      return ['python', 'javascript', 'lua']
    },
    languages () {
      return schema.properties.languages.items.enum
    }
  },
  methods: {
    emitInfo () {
      this.$emit('change-class-info', {
        codeLanguage: this.codeLanguage,
        level: this.levels.indexOf(this.level),
        language: this.language
      })
    }
  }
}
</script>

<style lang="scss" scoped>
@import "common";
.buttons {
  display: flex;
  justify-content: flex-end;
  margin-top: 2rem;
}
label {
  font-weight: 400;
}
</style>
