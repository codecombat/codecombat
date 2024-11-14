<template>
  <div class="end-page center-div">
    <div
      class="exam-complete-text"
    >
      Thank you for completing the exam!!
    </div>
  </div>
</template>

<script>
export default {
  methods: {
    backToHome () {
      application.router.navigate('/', { trigger: true })
    },
  },
}

</script>

<style scoped lang="scss">
.center-div {
  display: flex;
  flex-direction: column;
  align-items: center;
}
.exam-complete-text {
  font-size: 2.5rem;
  font-weight: bold;
}
</style>
