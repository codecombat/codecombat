<template>
  <div class="exam-page">
    <template v-if="loading">
      <div>Loading...</div>
    </template>
    <template v-else>
      <div class="header">
        {{ exam.title }}
      </div>
      <router-view />
    </template>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
export default {
  props: {
    examId: {
      type: String,
      required: true,
    },
    path: {
      type: String,
      default: 'start',
    },
    codeLang: {
      type: String,
      required: false,
      default: '',
    },
  },
  data () {
    return {
      loading: true,
    }
  },
  computed: {
    ...mapGetters('exams', [
      'getExamById',
      'userExam',
    ]),
    exam () {
      if (this.loading) return null
      return this.getExamById(this.examId)
    },
  },
  async mounted () {
    if (this.exam) {
      this.loading = false
      return
    }
    const includeArchived = this.$route.query.includeArchived === 'true'
    await this.fetchUserExam({ examId: this.examId, includeArchived })
    await this.fetchExamById(this.examId)
    this.loading = false
  },
  methods: {
    ...mapActions('exams', [
      'fetchExamById',
      'fetchUserExam',
    ]),
  },
}

</script>

<style scoped lang="scss">
.exam-page {
  min-height: 50vh;

  .header {
    font-size: 2em;
    font-weight: bold;
    padding: 10px;
    text-align: center;
    margin-bottom: 20px;
    margin-top: 50px;
  }
}
</style>
