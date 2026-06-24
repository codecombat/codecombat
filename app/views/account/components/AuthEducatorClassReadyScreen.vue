<template>
  <section class="auth-educator-class-ready-screen">
    <div class="auth-card">
      <div class="check-circle">
        <span>✓</span>
      </div>

      <h1>Welcome, {{ displayName }}!</h1>
      <p class="subcopy">
        Your first class is ready. Students join in seconds — no email required.
      </p>

      <!-- Class card -->
      <div class="class-card">
        <div class="class-header">
          <span class="class-name">My First Class</span>
          <span class="class-meta">0 students · created just now</span>
        </div>
        <div class="class-code-block">
          <span class="class-code-label">CLASS CODE</span>
          <span class="class-code">{{ classCode }}</span>
        </div>
      </div>

      <!-- Share actions -->
      <div class="share-actions">
        <button
          class="share-btn"
          type="button"
          @click="copyLink"
        >
          {{ copyLabel }}
        </button>
        <button
          class="share-btn"
          type="button"
          @click="openGoogleClassroom"
        >
          Google Classroom
        </button>
        <button
          class="share-btn"
          type="button"
          @click="printInfo"
        >
          Print
        </button>
      </div>

      <button
        class="primary-action"
        type="button"
        @click="goToDashboard"
      >
        Go to my dashboard
      </button>
    </div>
  </section>
</template>

<script>
export default Vue.extend({
  name: 'AuthEducatorClassReadyScreen',
  props: {
    firstName: {
      type: String,
      default: '',
    },
    lastName: {
      type: String,
      default: '',
    },
    classCode: {
      type: String,
      default: 'FROG-1284',
    },
  },
  data () {
    return {
      copyLabel: 'Copy link',
    }
  },
  computed: {
    displayName () {
      if (this.lastName) {
        return `Ms. ${this.lastName}`
      }
      return this.firstName || 'Teacher'
    },
    joinLink () {
      return `${window.location.origin}/students?code=${this.classCode}`
    },
  },
  methods: {
    copyLink () {
      if (navigator.clipboard) {
        navigator.clipboard.writeText(this.joinLink).then(() => {
          this.copyLabel = 'Copied!'
          setTimeout(() => { this.copyLabel = 'Copy link' }, 2000)
        })
      } else {
        noty({ text: `Share this link: ${this.joinLink}`, layout: 'topCenter', type: 'info', timeout: 5000, killer: false, dismissQueue: true })
      }
    },
    openGoogleClassroom () {
      noty({ text: 'Google Classroom sharing will be wired in a later slice.', layout: 'topCenter', type: 'info', timeout: 3000, killer: false, dismissQueue: true })
    },
    printInfo () {
      noty({ text: 'Print will be wired in a later slice.', layout: 'topCenter', type: 'info', timeout: 3000, killer: false, dismissQueue: true })
    },
    goToDashboard () {
      window.location.href = '/teachers/classes'
    },
  },
})
</script>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";

.auth-card {
  background: rgba(255, 255, 255, 0.98);
  border-radius: 28px;
  padding: 24px 18px 20px;
  text-align: center;
}

.check-circle {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  background: rgba(122, 101, 252, 0.12);
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 14px;
  color: #7a65fc;
  font-size: 26px;
  font-weight: 900;
}

h1 {
  margin: 0;
  color: #17314d;
  font-size: 24px;
  font-weight: 800;
  line-height: 1.15;
}

.subcopy {
  margin: 8px auto 0;
  max-width: 280px;
  color: #5b6b7c;
  font-size: 13px;
  line-height: 1.5;
}

/* Class card */
.class-card {
  margin-top: 18px;
  border-radius: 16px;
  border: 1px solid #e3e6f8;
  overflow: hidden;
  text-align: left;
}

.class-header {
  padding: 12px 14px;
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.class-name {
  color: #17314d;
  font-size: 14px;
  font-weight: 700;
}

.class-meta {
  color: #8b95a7;
  font-size: 12px;
}

.class-code-block {
  background: rgba(122, 101, 252, 0.07);
  padding: 14px 14px 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}

.class-code-label {
  color: #7a65fc;
  font-size: 10px;
  font-weight: 800;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.class-code {
  color: #17314d;
  font-size: 28px;
  font-weight: 800;
  letter-spacing: 0.06em;
  font-family: "Courier New", Courier, monospace;
}

/* Share buttons */
.share-actions {
  margin-top: 14px;
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
}

.share-btn {
  padding: 8px 4px;
  border-radius: 10px;
  border: 1px solid #d9ddf6;
  background: rgba(122, 101, 252, 0.05);
  color: #6d5df6;
  font-size: 12px;
  font-weight: 700;
  cursor: pointer;
  line-height: 1.3;
}

.share-btn:hover,
.share-btn:focus-visible {
  background: rgba(122, 101, 252, 0.12);
  border-color: rgba(122, 101, 252, 0.4);
}

/* Dashboard CTA */
.primary-action {
  width: 100%;
  margin-top: 14px;
  border: 0;
  border-radius: 12px;
  padding: 12px 20px;
  background: #7a65fc;
  color: #fff;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
}

.primary-action:hover {
  background: #6d5df6;
}
</style>
