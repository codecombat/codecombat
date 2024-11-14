<template>
  <div class="end-page center-div">
    <div>
      Thank you for completing the exam!!
    </div>
    <div>
      <input
        type="button"
        value="Back To Home"
        @click="backToHome"
      >
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
</style>
