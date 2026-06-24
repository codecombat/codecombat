<template>
  <section class="auth-screen auth-chooser-screen">
    <div class="auth-shell-card">
      <div class="brand-row">
        <img
          class="logo-wordmark"
          src="/images/pages/base/logo.webp"
          alt="CodeCombat"
        >
      </div>

      <div class="copy-block">
        <button
          class="back-link"
          type="button"
          @click="$emit('back')"
        >
          Back
        </button>
        <h1>Create a free account</h1>
        <p>Please select the option that best describes you.</p>
      </div>

      <div class="choice-list">
        <button
          v-for="option in options"
          :key="option.key"
          class="choice-row"
          type="button"
          @click="$emit('select-path', option.key)"
        >
          <div class="choice-image-shell">
            <img
              class="choice-image"
              :src="option.image"
              :alt="option.title"
            >
          </div>
          <div class="choice-copy">
            <span class="choice-title">{{ option.title }}</span>
            <span class="choice-description">{{ option.description }}</span>
          </div>
          <span
            class="choice-chevron"
            aria-hidden="true"
          >›</span>
        </button>
      </div>

      <p class="footer-copy">
        Already have an account? <button
          type="button"
          class="text-link"
          @click="$emit('login')"
        >
          Sign in
        </button>
      </p>
    </div>
  </section>
</template>

<script>
const options = [
  {
    key: 'educator',
    title: "I'm an Educator",
    description: 'Introduce computer science and AI to your school or organization with your solutions and scaffolded curricula.',
    image: '/images/pages/account/create/educator.png',
  },
  {
    key: 'parent',
    title: "I'm a Parent",
    description: 'Invest in your child\'s future. Enroll them in live, online coding classes with an instructor.',
    image: '/images/pages/account/create/parent.png',
  },
  {
    key: 'classroom',
    title: "I'm With a Class",
    description: 'Learn computer science with your classroom. You\'ll need a class code to join.',
    image: '/images/pages/account/create/student.png',
  },
  {
    key: 'individual',
    title: "I'm a Solo Learner",
    description: 'Master core coding concepts from home and advance all the way to web development.',
    image: '/images/pages/account/create/individual.png',
  },
]

export default Vue.extend({
  name: 'AuthChooserScreen',
  data () {
    return { options }
  },
})
</script>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";

.auth-shell-card {
  background: rgba(255, 255, 255, 0.94);
  border: 1px solid rgba(122, 101, 252, 0.12);
  border-radius: 32px;
  box-shadow: 0 26px 60px rgba(65, 50, 140, 0.12);
  padding: 20px 20px 28px;
}

.brand-row {
  display: flex;
  justify-content: center;
}

.logo-wordmark {
  width: 154px;
  height: auto;
}

.copy-block {
  margin-top: 16px;
  text-align: center;
}

.back-link,
.text-link {
  appearance: none;
  border: 0;
  background: none;
}

.back-link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  color: #6d5df6;
  font-size: 14px;
  font-weight: 700;
  margin-bottom: 14px;
}

h1 {
  margin: 0;
  color: #17314d;
  font-size: 40px;
  line-height: 1.08;
  font-weight: 800;
}

p {
  margin: 12px 0 0;
  color: #5b6b7c;
  font-size: 18px;
  line-height: 1.5;
}

.choice-list {
  margin-top: 24px;
  display: grid;
  gap: 14px;
}

.choice-row {
  display: grid;
  grid-template-columns: 84px 1fr 20px;
  gap: 16px;
  align-items: center;
  width: 100%;
  text-align: left;
  padding: 16px;
  border-radius: 22px;
  border: 1px solid rgba(122, 101, 252, 0.18);
  background: #fff;
  box-shadow: 0 10px 24px rgba(57, 41, 130, 0.08);
}

.choice-row:hover {
  border-color: rgba(122, 101, 252, 0.48);
  transform: translateY(-1px);
}

.choice-image-shell {
  width: 84px;
  height: 84px;
  border-radius: 18px;
  overflow: hidden;
  background: linear-gradient(180deg, #f5f1ff 0%, #eef2ff 100%);
}

.choice-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.choice-copy {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.choice-title {
  color: #17314d;
  font-size: 28px;
  line-height: 1.15;
  font-weight: 800;
}

.choice-description {
  color: #617283;
  font-size: 19px;
  line-height: 1.45;
}

.choice-chevron {
  color: #9aa3b2;
  font-size: 34px;
  line-height: 1;
}

.footer-copy {
  text-align: center;
  font-size: 16px;
  margin-top: 20px;
}

.text-link {
  color: #6d5df6;
  font-weight: 700;
  cursor: pointer;
}

@media screen and (max-width: 640px) {
  .choice-row {
    grid-template-columns: 72px 1fr 16px;
    gap: 12px;
    padding: 14px;
  }

  .choice-image-shell {
    width: 72px;
    height: 72px;
  }

  h1 {
    font-size: 26px;
  }

  p {
    font-size: 16px;
  }

  .choice-title {
    font-size: 16px;
  }

  .choice-description {
    font-size: 15px;
  }
}

@media screen and (min-width: $screen-md-min) {
  .auth-shell-card {
    padding: 28px 28px 32px;
  }
}
</style>
