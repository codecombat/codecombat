<template>
  <section class="auth-class-code-screen">
    <div class="auth-card">
      <div class="wordmark-row">
        <mixed-color-label
          class="wordmark"
          text="Code**Combat"
          :inherit-default-color="true"
        />
      </div>

      <div class="copy-block">
        <span class="path-pill">With a Class</span>
        <h1>Enter your class code</h1>
        <p>Ask your teacher for the 6-character code.</p>
      </div>

      <!-- 6-box code input -->
      <div class="code-row">
        <input
          v-for="n in 6"
          :key="n - 1"
          :ref="`box${n - 1}`"
          class="code-box"
          type="text"
          maxlength="1"
          autocomplete="off"
          spellcheck="false"
          :value="boxes[n - 1]"
          @input="onInput(n - 1, $event)"
          @keydown="onKeydown(n - 1, $event)"
          @paste.prevent="onPaste($event)"
          @focus="$event.target.select()"
        >
      </div>

      <p
        v-if="errorMessage"
        class="error-copy"
      >
        {{ errorMessage }}
      </p>

      <button
        class="primary-action"
        type="button"
        :disabled="classCode.length < 6"
        @click="submit"
      >
        Join class
      </button>
    </div>
  </section>
</template>

<script>
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'

export default Vue.extend({
  name: 'AuthClassCodeScreen',
  components: { MixedColorLabel },
  props: {
    errorMessage: {
      type: String,
      default: '',
    },
  },
  data () {
    return {
      boxes: ['', '', '', '', '', ''],
    }
  },
  computed: {
    classCode () {
      return this.boxes.join('').toUpperCase()
    },
  },
  methods: {
    boxRef (i) {
      return this.$refs[`box${i}`]
    },
    onInput (i, e) {
      const val = e.target.value.replace(/[^a-zA-Z0-9]/g, '').toUpperCase().slice(0, 1)
      this.$set(this.boxes, i, val)
      e.target.value = val
      if (val && i < 5) {
        this.$nextTick(() => {
          const next = this.boxRef(i + 1)
          if (next) next.focus()
        })
      }
    },
    onKeydown (i, e) {
      if (e.key === 'Backspace') {
        if (this.boxes[i]) {
          this.$set(this.boxes, i, '')
        } else if (i > 0) {
          this.$set(this.boxes, i - 1, '')
          this.$nextTick(() => {
            const prev = this.boxRef(i - 1)
            if (prev) prev.focus()
          })
        }
        e.preventDefault()
      } else if (e.key === 'ArrowLeft' && i > 0) {
        this.boxRef(i - 1)?.focus()
      } else if (e.key === 'ArrowRight' && i < 5) {
        this.boxRef(i + 1)?.focus()
      }
    },
    onPaste (e) {
      const text = (e.clipboardData || window.clipboardData)
        .getData('text')
        .replace(/[^a-zA-Z0-9]/g, '')
        .toUpperCase()
        .slice(0, 6)
      text.split('').forEach((ch, i) => this.$set(this.boxes, i, ch))
      this.$nextTick(() => {
        const last = Math.min(text.length, 5)
        this.boxRef(last)?.focus()
      })
    },
    submit () {
      this.$emit('submit', this.classCode)
    },
  },
})
</script>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";

.auth-card {
  background: rgba(255, 255, 255, 0.98);
  border-radius: 28px;
  padding: 22px 18px 20px;
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
  margin-top: 12px;
  text-align: center;
}

/* With a Class pill - teal */
.path-pill {
  display: inline-flex;
  align-items: center;
  margin-bottom: 10px;
  padding: 6px 14px;
  border-radius: 999px;
  background: rgba(61, 184, 178, 0.14);
  color: #1a9e98;
  font-size: 12px;
  font-weight: 800;
}

h1 {
  margin: 0;
  color: #17314d;
  font-size: 24px;
  font-weight: 800;
  line-height: 1.1;
}

p {
  margin: 5px 0 0;
  color: #5b6b7c;
  font-size: 13px;
  line-height: 1.4;
}

/* 6-box code input */
.code-row {
  margin-top: 22px;
  display: flex;
  gap: 8px;
  justify-content: center;
}

.code-box {
  width: 46px;
  height: 54px;
  border-radius: 12px;
  border: 2px solid #d9ddf6;
  background: #fbfbff;
  text-align: center;
  font-size: 22px;
  font-weight: 800;
  color: #17314d;
  line-height: 1;
  caret-color: #3db8b2;
  transition: border-color 0.12s;
}

.code-box:focus {
  outline: none;
  border-color: #3db8b2;
  background: rgba(61, 184, 178, 0.04);
}

.error-copy {
  color: #cc3846;
  font-size: 12px;
  margin-top: 10px;
  text-align: center;
}

.primary-action {
  width: 100%;
  margin-top: 22px;
  border: 0;
  border-radius: 12px;
  padding: 13px 20px;
  background: #3db8b2;
  color: #fff;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
  transition: background 0.15s;
}

.primary-action:hover {
  background: #2fa8a2;
}

.primary-action:disabled {
  opacity: 0.45;
}

@media screen and (max-width: 380px) {
  .code-box {
    width: 40px;
    height: 48px;
    font-size: 20px;
  }

  .code-row {
    gap: 6px;
  }
}
</style>
