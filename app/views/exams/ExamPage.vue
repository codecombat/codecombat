<template>
  <div class="exam-page">
    <div class="header">
      {{ exam.title }}
    </div>
    <router-view />
  </div>
</template>

<script>
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
  },
  data () {
    return {
      exam: { // todo: fetch from server by examId
        title: 'MTO Qualification Exam',
      },
    }
  },
  mounted () {
  },
  methods: {
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

::v-deep .center-div{
  display: flex;
  flex-direction: column;
  align-items: center;
}
</style>