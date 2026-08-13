<template>
  <div class="ai-junior-share-box">
    <h4>Share this creation</h4>
    <p class="share-hint">
      Anyone with the link can see it — no account needed.
    </p>

    <div class="share-modes">
      <label
        v-for="mode in MODES"
        :key="mode.value"
        class="share-mode"
        :class="{ active: shared === mode.value }"
      >
        <input
          type="radio"
          name="ai-junior-share-mode"
          :value="mode.value"
          :checked="shared === mode.value"
          :disabled="saving"
          @change="setMode(mode.value)"
        >
        <span class="share-mode-label">{{ mode.label }}</span>
        <span class="share-mode-hint">{{ mode.hint }}</span>
      </label>
    </div>

    <div
      v-if="isShared"
      class="share-link-row"
    >
      <input
        ref="linkInput"
        class="share-link"
        type="text"
        readonly
        :value="shareUrl"
        @focus="$event.target.select()"
      >
      <button
        class="btn btn-primary"
        @click="copyLink"
      >
        {{ copied ? '✓ Copied' : 'Copy' }}
      </button>
    </div>

    <p
      v-if="error"
      class="share-error"
    >
      {{ error }}
    </p>
  </div>
</template>

<script>
import { shareAIJuniorProject } from 'core/api/ai-junior-projects'

const MODES = [
  { value: 'none', label: 'Private', hint: 'Only you' },
  { value: 'result', label: 'Just the creation', hint: 'The finished result' },
  { value: 'full', label: 'Creation + worksheet', hint: 'Also shows what they drew and wrote' },
]

export default {
  name: 'AIJuniorShareBox',
  props: {
    project: {
      type: Object,
      required: true,
    },
  },
  data () {
    return {
      MODES,
      shared: this.project.shared || 'none',
      saving: false,
      copied: false,
      error: null,
    }
  },
  computed: {
    isShared () {
      return this.shared === 'result' || this.shared === 'full'
    },
    shareUrl () {
      return `${window.location.origin}/ai-junior/creation/${this.project._id}`
    },
  },
  methods: {
    async setMode (mode) {
      const previous = this.shared
      this.shared = mode
      this.saving = true
      this.error = null
      this.copied = false
      try {
        await shareAIJuniorProject({ projectHandle: this.project._id, shared: mode })
        this.$emit('shared', mode)
      } catch (err) {
        console.error('Error sharing project:', err)
        this.shared = previous
        this.error = 'Could not update sharing. Please try again.'
      } finally {
        this.saving = false
      }
    },
    async copyLink () {
      try {
        await navigator.clipboard.writeText(this.shareUrl)
      } catch (err) {
        // Clipboard API needs a secure context; fall back to selecting the text.
        this.$refs.linkInput?.select()
        document.execCommand?.('copy')
      }
      this.copied = true
      setTimeout(() => { this.copied = false }, 2000)
    },
  },
}
</script>

<style scoped>
.ai-junior-share-box {
  max-width: 560px;
  margin: 1.2rem auto 0;
  padding: 1.2rem 1.4rem 1.4rem;
  border: 1px solid #e0e0e0;
  border-radius: 12px;
  background: #fafafa;
}

.ai-junior-share-box h4 {
  margin: 0 0 0.2rem;
}

.share-hint {
  color: #777;
  font-size: 1.3rem;
  margin-bottom: 1rem;
}

.share-modes {
  display: flex;
  flex-wrap: wrap;
  gap: 0.6rem;
  margin-bottom: 1rem;
}

.share-mode {
  flex: 1 1 150px;
  display: block;
  margin: 0;
  padding: 0.7rem 0.8rem;
  border: 2px solid #ddd;
  border-radius: 10px;
  background: #fff;
  cursor: pointer;
  font-weight: normal;
}

.share-mode.active {
  border-color: #337ab7;
  background: #f0f7fd;
}

.share-mode input {
  display: none;
}

.share-mode-label {
  display: block;
  font-size: 1.5rem;
  font-weight: bold;
}

.share-mode-hint {
  display: block;
  font-size: 1.2rem;
  color: #888;
}

.share-link-row {
  display: flex;
  gap: 0.6rem;
}

.share-link {
  flex: 1;
  min-width: 0;
  padding: 0.5rem 0.7rem;
  font-size: 1.4rem;
  border: 1px solid #ccc;
  border-radius: 8px;
  background: #fff;
}

.share-error {
  color: #b3261e;
  font-size: 1.3rem;
  margin: 0.8rem 0 0;
}
</style>
