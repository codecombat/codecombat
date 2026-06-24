<template>
  <section class="auth-screen auth-welcome-screen">
    <div class="auth-shell-card">
      <div class="hero-card">
        <div class="hero-chip hero-chip-left" />
        <div class="hero-chip hero-chip-right" />
        <div class="hero-code-card">
          <div class="hero-code-line">
            <span class="hero-code-muted">hero.</span><span class="hero-code-strong">moveRight()</span>
          </div>
          <div class="hero-code-line">
            <span class="hero-code-muted">hero.</span><span class="hero-code-strong">attack</span><span class="hero-code-string">('ogre')</span>
          </div>
        </div>
      </div>

      <div class="copy-block">
        <img
          class="logo-wordmark"
          src="/images/pages/base/logo.webp"
          alt="CodeCombat"
        >
        <h1>Learn to code by playing.</h1>
        <p>Write real Python &amp; JavaScript to beat each level. Loved by 20,000+ teachers.</p>
      </div>

      <div
        class="benefit-chips"
        aria-label="signup benefits"
      >
        <span class="benefit-chip">Free to start</span>
        <span class="benefit-chip">No credit card</span>
      </div>

      <div class="action-stack">
        <button
          class="primary-action"
          type="button"
          @click="$emit('create-account')"
        >
          Create free account
        </button>
        <button
          class="secondary-action"
          type="button"
          @click="$emit('class-code')"
        >
          I have a class code
        </button>
      </div>

      <p class="footer-copy">
        Already have an account? <button
          type="button"
          class="text-link"
          @click="$emit('login')"
        >
          Log in
        </button>
      </p>
    </div>
  </section>
</template>

<script>
export default Vue.extend({
  name: 'AuthWelcomeScreen',
})
</script>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";

.auth-shell-card {
  background: rgba(255, 255, 255, 0.92);
  border: 1px solid rgba(122, 101, 252, 0.14);
  border-radius: 32px;
  box-shadow: 0 26px 60px rgba(65, 50, 140, 0.12);
  padding: 24px 20px 28px;
}

.hero-card {
  position: relative;
  border-radius: 28px;
  padding: 28px 18px 18px;
  background: linear-gradient(135deg, #7a65fc 0%, #9a8eff 100%);
  min-height: 180px;
  overflow: hidden;
}

.hero-chip {
  position: absolute;
  width: 26px;
  height: 26px;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.14);
  transform: rotate(16deg);
}

.hero-chip-left {
  top: 30px;
  left: 28px;
}

.hero-chip-right {
  top: 36px;
  right: 34px;
}

.hero-code-card {
  margin-top: 70px;
  border-radius: 18px;
  background: rgba(47, 33, 114, 0.58);
  padding: 18px 16px;
}

.hero-code-line {
  font-family: Monaco, Menlo, Consolas, monospace;
  font-size: 22px;
  line-height: 1.45;
}

.hero-code-muted {
  color: rgba(239, 234, 255, 0.85);
}

.hero-code-strong {
  color: #ffffff;
  font-weight: 700;
}

.hero-code-string {
  color: #ffd57f;
  font-weight: 700;
}

.copy-block {
  padding-top: 22px;
  text-align: center;
}

.logo-wordmark {
  width: 154px;
  height: auto;
}

h1 {
  margin: 18px 0 10px;
  color: #17314d;
  font-size: 38px;
  line-height: 1.05;
  font-weight: 800;
}

p {
  margin: 0;
  color: #516173;
  font-size: 18px;
  line-height: 1.55;
}

.benefit-chips {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 10px;
  margin-top: 20px;
}

.benefit-chip {
  padding: 10px 14px;
  border-radius: 999px;
  background: #f1edff;
  color: #5f54c7;
  font-size: 14px;
  font-weight: 700;
}

.action-stack {
  display: grid;
  gap: 12px;
  margin-top: 24px;
}

.primary-action,
.secondary-action,
.text-link {
  appearance: none;
  border: 0;
  background: none;
}

.primary-action,
.secondary-action {
  width: 100%;
  border-radius: 18px;
  padding: 16px 20px;
  font-size: 18px;
  line-height: 1.3;
  font-weight: 700;
}

.primary-action {
  background: linear-gradient(135deg, #7a65fc 0%, #6b59f7 100%);
  color: #fff;
  box-shadow: 0 16px 32px rgba(122, 101, 252, 0.26);
}

.secondary-action {
  background: #eef2ff;
  color: #17314d;
  border: 1px solid rgba(122, 101, 252, 0.18);
}

.footer-copy {
  margin-top: 18px;
  text-align: center;
  font-size: 16px;
}

.text-link {
  color: #6d5df6;
  font-weight: 700;
  cursor: pointer;
}

@media screen and (min-width: $screen-md-min) {
  .auth-shell-card {
    padding: 40px 40px 36px;
  }

  .hero-card {
    min-height: 210px;
    padding: 34px 28px 26px;
  }

  .hero-code-card {
    margin-top: 86px;
    padding: 22px 22px;
  }

  h1 {
    font-size: 54px;
  }

  p {
    font-size: 20px;
  }
}
</style>
