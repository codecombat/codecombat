<template>
  <div>
    <div class="form">
      <div class="form-group">
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
            {{ lang }}
          </option>
        </select>
      </div>
      <div class="form-group">
        <select
          v-model="level"
          name="level"
          class="form-control"
        >
          <option
            v-for="l in levels"
            :key="`cl-${lang}-level-${l}`"
            :value="l"
          >
            {{ l }}
          </option>
        </select>
      </div>
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
      <button
        class="btn btn-primary"
        @click="emitInfo"
      >
        Show Available Times
      </button>
    </div>
  </div>
</template>
<script>
import schema from '../../../schemas/models/online_teacher'
export default {
  name: 'ClassInfo',
  data () {
    return {
      codeLanguage: '',
      level: '',
      language: ''
    }
  },
  computed: {
    codeLanguages () {
      return schema.properties.codeLanguages.items.properties.language.enum
    },
    levels () {
      return ['Beginner', 'Intermediate', 'Advanced']
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