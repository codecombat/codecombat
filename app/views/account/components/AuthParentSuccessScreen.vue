<template>
  <section class="auth-parent-success-screen">
    <div class="auth-card">
      <div class="check-circle">
        <span>&#x2713;</span>
      </div>

      <h1>You're all set!</h1>
      <p class="subcopy">
        Your first quest is ready. Jump in and write your first line of code.
      </p>

      <button
        class="primary-action"
        type="button"
        @click="startPlaying"
      >
        Start playing
      </button>
    </div>
  </section>
</template>

<script>
export default Vue.extend({
  name: 'AuthParentSuccessScreen',
  methods: {
    startPlaying () {
      window.location.href = '/play'
    },
  },
})
</script>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";

.auth-card {
  background: rgba(255, 255, 255, 0.98);
  border-radius: 28px;
  padding: 40px 18px 28px;
  text-align: center;
}

.check-circle {
  width: 72px;
  height: 72px;
  border-radius: 50%;
  background: rgba(122, 101, 252, 0.15);
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 20px;
  color: #7a65fc;
  font-size: 32px;
  font-weight: 900;
}

h1 {
  margin: 0;
  color: #17314d;
  font-size: 26px;
  font-weight: 800;
  line-height: 1.15;
}

.subcopy {
  margin: 10px auto 0;
  max-width: 240px;
  color: #5b6b7c;
  font-size: 14px;
  line-height: 1.55;
}

.primary-action {
  width: 100%;
  margin-top: 40px;
  border: 0;
  border-radius: 12px;
  padding: 14px 20px;
  background: #7a65fc;
  color: #fff;
  font-size: 16px;
  font-weight: 700;
  cursor: pointer;
}

.primary-action:hover {
  background: #6d5df6;
}
</style>
