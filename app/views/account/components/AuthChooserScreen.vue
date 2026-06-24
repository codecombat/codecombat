<template>
  <section class="auth-chooser-screen">
    <div class="auth-card">
      <div class="wordmark-row">
        <mixed-color-label
          class="wordmark"
          text="Code**Combat"
          :inherit-default-color="true"
        />
      </div>

      <div class="copy-block">
        <h1>Create a free account</h1>
        <p>Please select the option that best describes you.</p>
      </div>

      <!-- Mobile: rows -->
      <div class="choice-list choice-list--rows">
        <button
          v-for="option in options"
          :key="option.key"
          class="choice-row"
          type="button"
          @click="$emit('select-path', option.key)"
        >
          <div
            class="row-icon"
            :style="{ background: option.iconBg }"
          >
            <img
              :src="option.image"
              :alt="option.title"
            >
          </div>
          <div class="row-copy">
            <span class="row-title">{{ option.title }}</span>
            <span class="row-desc">{{ option.description }}</span>
          </div>
          <span
            class="row-arrow"
            aria-hidden="true"
          >›</span>
        </button>
      </div>

      <!-- Desktop: cards grid -->
      <div class="choice-list choice-list--cards">
        <button
          v-for="option in options"
          :key="`card-${option.key}`"
          class="choice-card"
          type="button"
          @click="$emit('select-path', option.key)"
        >
          <div
            class="card-image-shell"
            :style="{ background: option.iconBg }"
          >
            <img
              :src="option.image"
              :alt="option.title"
            >
          </div>
          <div class="card-copy">
            <span class="card-title">{{ option.title }}</span>
            <span class="card-desc">{{ option.description }}</span>
            <span
              class="card-arrow"
              aria-hidden="true"
            >›</span>
          </div>
        </button>
      </div>

      <p class="footer-copy">
        Already have an account?
        <button
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
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'

const options = [
  {
    key: 'educator',
    title: "I'm an Educator",
    description: 'Introduce computer science and AI to your school or organization.',
    image: '/images/pages/account/create/educator.png',
    iconBg: 'rgba(122, 101, 252, 0.12)',
  },
  {
    key: 'parent',
    title: "I'm a Parent",
    description: "Invest in your child's future with live online coding classes.",
    image: '/images/pages/account/create/parent.png',
    iconBg: 'rgba(91, 164, 245, 0.15)',
  },
  {
    key: 'classroom',
    title: "I'm With a Class",
    description: "Learn with your classroom. You'll need a class code to join.",
    image: '/images/pages/account/create/student.png',
    iconBg: 'rgba(75, 188, 178, 0.15)',
  },
  {
    key: 'individual',
    title: "I'm a Solo Learner",
    description: 'Master coding from home and advance to web development.',
    image: '/images/pages/account/create/individual.png',
    iconBg: 'rgba(245, 168, 66, 0.18)',
  },
]

export default Vue.extend({
  name: 'AuthChooserScreen',
  components: { MixedColorLabel },
  data () {
    return { options }
  },
})
</script>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";

.auth-card {
  background: rgba(255, 255, 255, 0.98);
  border-radius: 28px;
  padding: 20px 16px 18px;
}

.wordmark-row {
  display: flex;
  justify-content: center;
}

.wordmark {
  font-size: 20px;
  font-weight: 800;
}

:deep(.wordmark .mixed-color-label__normal) { color: #17314d; }
:deep(.wordmark .mixed-color-label__highlight) { color: #7a65fc; }

.copy-block {
  margin-top: 14px;
  text-align: center;
}

h1 {
  margin: 0;
  color: #17314d;
  font-size: 26px;
  font-weight: 800;
  line-height: 1.1;
}

p {
  margin: 6px 0 0;
  color: #5b6b7c;
  font-size: 14px;
  line-height: 1.4;
}

/* ======= MOBILE ROWS ======= */
.choice-list--cards {
  display: none;
}

.choice-list--rows {
  display: grid;
  gap: 8px;
  margin-top: 14px;
}

.choice-row {
  display: grid;
  grid-template-columns: 48px 1fr 18px;
  gap: 12px;
  align-items: center;
  width: 100%;
  text-align: left;
  padding: 10px 12px;
  border-radius: 16px;
  border: 1px solid rgba(122, 101, 252, 0.16);
  background: #fff;
  cursor: pointer;
}

.choice-row:hover,
.choice-row:focus-visible {
  border-color: rgba(122, 101, 252, 0.5);
}

.row-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  overflow: hidden;
  flex-shrink: 0;
}

.row-icon img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.row-copy {
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.row-title {
  color: #17314d;
  font-size: 15px;
  font-weight: 700;
  line-height: 1.2;
}

.row-desc {
  color: #617283;
  font-size: 12px;
  line-height: 1.4;
}

.row-arrow {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: rgba(122, 101, 252, 0.09);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  color: #7a65fc;
  font-size: 18px;
  line-height: 1;
  transition: background 0.15s;
}

.choice-row:hover .row-arrow,
.choice-row:focus-visible .row-arrow {
  background: rgba(122, 101, 252, 0.18);
}

/* ======= DESKTOP CARDS ======= */
@media screen and (min-width: $screen-md-min) {
  .auth-card {
    padding: 24px 20px 20px;
  }

  h1 { font-size: 28px; }

  .choice-list--rows {
    display: none;
  }

  .choice-list--cards {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 12px;
    margin-top: 16px;
  }

  .choice-card {
    display: flex;
    flex-direction: column;
    text-align: left;
    border-radius: 18px;
    border: 1px solid rgba(122, 101, 252, 0.16);
    background: #fff;
    overflow: hidden;
    cursor: pointer;
    padding: 0;
  }

  .choice-card:hover,
  .choice-card:focus-visible {
    border-color: rgba(122, 101, 252, 0.5);
    transform: translateY(-2px);
    box-shadow: 0 6px 18px rgba(100, 80, 200, 0.10);
  }

  .choice-card {
    transition: transform 0.15s, box-shadow 0.15s, border-color 0.15s;
  }

  .card-image-shell {
    width: 100%;
    height: 100px;
    overflow: hidden;
  }

  .card-image-shell img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .card-copy {
    padding: 12px 14px 14px;
    display: flex;
    flex-direction: column;
    gap: 4px;
    position: relative;
  }

  .card-title {
    color: #17314d;
    font-size: 14px;
    font-weight: 700;
    line-height: 1.2;
  }

  .card-desc {
    color: #617283;
    font-size: 12px;
    line-height: 1.4;
  }

  .card-arrow {
    position: absolute;
    bottom: 0;
    right: 0;
    width: 24px;
    height: 24px;
    border-radius: 50%;
    background: rgba(122, 101, 252, 0.08);
    display: flex;
    align-items: center;
    justify-content: center;
    color: #9d8ffa;
    font-size: 16px;
    line-height: 1;
    transition: background 0.15s, color 0.15s;
  }

  .choice-card:hover .card-arrow,
  .choice-card:focus-visible .card-arrow {
    background: rgba(122, 101, 252, 0.18);
    color: #7a65fc;
  }
}

.footer-copy {
  margin-top: 14px;
  text-align: center;
  font-size: 13px;
  color: #516173;
}

.text-link {
  appearance: none;
  border: 0;
  background: none;
  color: #6d5df6;
  font-weight: 700;
  cursor: pointer;
  font-size: 13px;
}
</style>
