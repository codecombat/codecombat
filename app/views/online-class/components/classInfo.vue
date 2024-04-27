<template>
  <div>
    <div class="form">
      <div class="form-group">
        <select name="codeLanguage" class="form-control" v-model="codeLanguage">
          <option v-for="lang in codeLanguages" :value="lang">
            {{ lang }}
          </option>
        </select>
      </div>
      <div class="form-group">
        <select name="level" class="form-control" v-model="level">
          <option v-for="l in levels" :value="l">
            {{ l }}
          </option>
        </select>
      </div>
      <div class="form-group">
        <select name="language" class="form-control" v-model="language">
          <option v-for="lang in languages" :value="lang">
            {{ lang }}
        </select>
      </div>
      <button class="btn btn-primary" @click="emitInfo">
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
        level: this.level,
        language: this.language
      })
    }
  }
}
</script>