<template>
  <div class="scenario-script-panel">
    <div
      v-if="!state.loaded"
      class="loading"
    >
      {{ $t('common.loading') }}
    </div>
    <template v-else>
      <div
        v-if="backup"
        class="alert alert-warning restore-bar"
      >
        <span>{{ $t('editor.scenario_script_backup_found') }} ({{ backupTime }})</span>
        <button
          class="btn btn-sm btn-primary"
          @click="restore"
        >
          {{ $t('editor.scenario_script_restore') }}
        </button>
        <button
          class="btn btn-sm btn-default"
          @click="dropBackup"
        >
          {{ $t('editor.scenario_script_drop_backup') }}
        </button>
      </div>
      <div
        v-if="warnLive && !readOnly"
        class="alert alert-info live-warning"
      >
        {{ $t('editor.scenario_script_live_warning') }}
      </div>
      <div
        v-if="notes.length"
        :class="['alert', problems.length ? 'alert-danger' : 'alert-warning', 'lint-strip']"
      >
        <div class="lint-head">
          <strong v-if="problems.length">{{ $t('editor.scenario_script_problems') }} {{ problemText }}</strong>
          <strong v-else>{{ lint.length }} {{ $t('editor.scenario_lint_notes') }}</strong>
          <button
            class="btn btn-xs btn-default"
            @click="lintOpen = !lintOpen"
          >
            {{ lintOpen ? $t('editor.scenario_lint_hide') : $t('editor.scenario_lint_show') }}
          </button>
        </div>
        <ul
          v-if="lintOpen"
          class="lint-list"
        >
          <li
            v-for="(f, i) in notes"
            :key="i"
            :class="f.severity"
          >
            <a
              v-if="f.key"
              href="#"
              @click.prevent="selectKey(f.key)"
            >{{ $t('editor.scenario_lint_step') }} {{ f.index + 1 }}</a>
            <span>{{ f.message }}</span>
          </li>
        </ul>
      </div>
      <div
        v-else
        class="lint-clean"
      >
        {{ $t('editor.scenario_lint_clean') }}
      </div>

      <div class="layout">
        <div class="steps-column">
          <ol class="steps">
            <li
              v-for="(step, index) in state.steps"
              :key="step.key"
              :class="['step', step.kind, { selected: step.key === state.selectedKey, dirty: isDirty(step) }]"
              @click="onCardClick($event, step)"
            >
              <div class="index">
                {{ index + 1 }}
              </div>
              <template v-if="step.kind === 'dead'">
                <div class="body dead-body">
                  <code>{{ step.id }}</code>
                  <span>{{ $t('editor.scenario_script_dead') }}</span>
                </div>
                <div
                  v-if="!readOnly"
                  class="actions"
                >
                  <button
                    class="btn btn-xs btn-default"
                    @click="removeFromQueue(step)"
                  >
                    {{ $t('editor.scenario_script_remove') }}
                  </button>
                </div>
              </template>
              <template v-else>
                <div class="body">
                  <div class="meta">
                    <span :class="['badge-actor', step.actor]">{{ actorLabel(step.actor) }}</span>
                    <span class="chip">{{ actionLabel(step) }}</span>
                    <span
                      v-if="step.kind === 'new'"
                      class="chip pending"
                    >{{ $t('editor.scenario_script_new') }}</span>
                    <span
                      v-else-if="isDirty(step)"
                      class="chip pending"
                    >{{ $t('editor.scenario_script_edited') }}</span>
                    <span
                      v-if="attachmentCount(step)"
                      class="chip"
                    >{{ attachmentCount(step) }} {{ $t('editor.scenario_script_attachments') }}</span>
                    <span
                      v-for="f in lintFor(step)"
                      :key="f.code"
                      :class="['chip', 'lint', f.severity]"
                      :title="f.message"
                    >{{ f.code }}</span>
                    <span class="langs">{{ languages(step) }}</span>
                  </div>
                  <div class="text">
                    <!-- markdown through marked, then DOMPurify, in render() -->
                    <!-- eslint-disable-next-line vue/no-v-html -->
                    <div v-html="render(textWithoutApp(step))" />
                  </div>
                  <div
                    v-if="appOf(step) || linkAttachments(step).length"
                    class="extras"
                  >
                    <button
                      v-if="appOf(step)"
                      class="btn btn-xs btn-default output-button"
                      @click="openPreview(step)"
                    >
                      {{ $t('editor.scenario_preview_output') }} · {{ appOf(step).label }}
                    </button>
                    <a
                      v-for="link in linkAttachments(step)"
                      :key="link.url"
                      :href="link.url"
                      target="_blank"
                      rel="noopener"
                      class="chip link"
                    >{{ link.label }}</a>
                  </div>
                  <ul
                    v-if="isQuiz(step)"
                    class="choices"
                  >
                    <li
                      v-for="(choice, i) in step.actionData.choices"
                      :key="i"
                      :class="{ correct: i === step.actionData.answerIndex }"
                    >
                      <span class="mark">{{ i === step.actionData.answerIndex ? $t('editor.scenario_script_correct') : $t('editor.scenario_script_wrong') }}</span>
                      <span class="choice-text">{{ choice.text }}</span>
                      <span class="feedback">{{ choice.responseText }}</span>
                    </li>
                  </ul>
                </div>
                <div
                  v-if="!readOnly"
                  class="actions"
                >
                  <button
                    class="btn btn-xs btn-default"
                    :disabled="index === 0"
                    :title="$t('editor.scenario_script_move_up')"
                    @click="move(step, -1)"
                  >
                    &uarr;
                  </button>
                  <button
                    class="btn btn-xs btn-default"
                    :disabled="index === state.steps.length - 1"
                    :title="$t('editor.scenario_script_move_down')"
                    @click="move(step, 1)"
                  >
                    &darr;
                  </button>
                  <div class="btn-group">
                    <button
                      class="btn btn-xs btn-default dropdown-toggle"
                      data-toggle="dropdown"
                    >
                      {{ $t('editor.scenario_script_insert_after') }} <span class="caret" />
                    </button>
                    <ul class="dropdown-menu">
                      <li
                        v-for="kind in kinds"
                        :key="kind"
                      >
                        <a
                          href="#"
                          @click.prevent="insertAfter(step, kind)"
                        >{{ kindLabel(kind) }}</a>
                      </li>
                      <li class="divider" />
                      <li>
                        <a
                          href="#"
                          @click.prevent="insertCopy(step)"
                        >{{ $t('editor.scenario_script_insert_copy') }}</a>
                      </li>
                    </ul>
                  </div>
                  <div class="btn-group">
                    <button
                      class="btn btn-xs btn-default dropdown-toggle"
                      data-toggle="dropdown"
                      :title="$t('editor.scenario_script_more')"
                    >
                      &hellip;
                    </button>
                    <ul class="dropdown-menu dropdown-menu-right">
                      <li>
                        <a
                          href="#"
                          @click.prevent="duplicate(step)"
                        >{{ $t('editor.scenario_script_duplicate') }}</a>
                      </li>
                      <li v-if="step.id">
                        <a
                          :href="'/editor/ai-chat-message/' + step.id"
                          target="_blank"
                        >{{ $t('editor.scenario_script_open_message') }}</a>
                      </li>
                      <li>
                        <a
                          href="#"
                          @click.prevent="removeFromQueue(step)"
                        >{{ $t('editor.scenario_script_remove') }}</a>
                      </li>
                      <li v-if="step.kind === 'live'">
                        <a
                          href="#"
                          class="danger"
                          @click.prevent="deleteMessage(step)"
                        >{{ $t('editor.scenario_script_delete') }}</a>
                      </li>
                    </ul>
                  </div>
                </div>
              </template>
            </li>
          </ol>

          <div
            v-if="!readOnly"
            class="add-row"
          >
            <button
              v-for="kind in kinds"
              :key="kind"
              class="btn btn-default"
              @click="append(kind)"
            >
              {{ $t('editor.scenario_script_add') }} {{ kindLabel(kind) }}
            </button>
          </div>
        </div>
        <div
          v-if="selectedStep"
          class="panel-column"
        >
          <scenario-step-panel
            :key="selectedStep.key"
            :store="store"
            :step="selectedStep"
            :index="selectedIndex"
            :read-only="readOnly"
            @changed="bump"
            @close="deselect"
          />
        </div>
      </div>
    </template>

    <div
      v-if="preview"
      class="preview-overlay"
      @click.self="closePreview"
    >
      <div class="preview-window">
        <div class="preview-head">
          <strong>{{ $t('editor.scenario_preview_title') }} {{ preview.index + 1 }} · {{ preview.label }}</strong>
          <span class="muted">{{ $t('editor.scenario_preview_sandbox') }}</span>
          <button
            class="btn btn-xs btn-default"
            @click="closePreview"
          >
            {{ $t('modal.close') }}
          </button>
        </div>
        <iframe
          class="preview-frame"
          sandbox="allow-scripts"
          :srcdoc="preview.html"
          :title="preview.label"
        />
      </div>
    </div>
  </div>
</template>

<script>
// The Script tab of the scenario editor: the queue as cards, queue edits, and
// the unsaved-changes footer. All state lives in lib/scenario-script; this
// component only calls it and re-renders.
const marked = require('marked')
const DOMPurify = require('dompurify')
const ScenarioStepPanel = require('./ScenarioStepPanel.vue').default
const { lintScript, findingsByKey } = require('lib/scenario-lint')

const KINDS = ['teacher', 'quiz', 'model', 'end']
// The first fenced block of a message; an html document in it is what the player's Output button runs.
const FENCE = /```(\w*)[ \t]*\n([\s\S]*?)```/
const HTML_DOC = /^\s*(<!doctype\s+html|<html)/i

export default Vue.extend({
  name: 'ScenarioScriptPanel',
  components: { ScenarioStepPanel },
  props: {
    store: { type: Object, required: true },
    readOnly: { type: Boolean, default: false },
    releasePhase: { type: String, default: 'draft' },
    mode: { type: String, default: '' },
    // From lib/story-world-chain buildStoryContext: the cast, objectives and scenes a step can reference.
    storyContext: { type: Object, default: null },
  },
  data () {
    return {
      state: this.store.state,
      tick: 0,
      backup: this.store.readBackup(),
      lintOpen: false,
      preview: null,
    }
  },
  computed: {
    kinds () { return KINDS },
    lint () {
      this.tick // eslint-disable-line no-unused-expressions
      return lintScript(this.state.steps, { mode: this.mode })
    },
    lintByKey () {
      return findingsByKey(this.lint)
    },
    warnLive () { return ['beta', 'released'].includes(this.releasePhase) },
    changes () {
      this.tick // eslint-disable-line no-unused-expressions
      return this.store.changes()
    },
    summary () {
      const c = this.changes
      const parts = []
      if (c.newSteps.length) { parts.push(`${c.newSteps.length} ${this.$t('editor.scenario_script_summary_new')}`) }
      if (c.editedSteps.length) { parts.push(`${c.editedSteps.length} ${this.$t('editor.scenario_script_summary_edited')}`) }
      if (c.deletedIds.length) { parts.push(`${c.deletedIds.length} ${this.$t('editor.scenario_script_summary_deleted')}`) }
      if (c.queueChanged) { parts.push(this.$t('editor.scenario_script_summary_queue')) }
      return parts.join(' · ')
    },
    backupTime () {
      return this.backup && this.backup.at ? new Date(this.backup.at).toLocaleString() : ''
    },
    problems () {
      this.tick // eslint-disable-line no-unused-expressions
      return this.store.validate()
    },
    problemText () {
      return this.problems.map(p => `${this.$t('editor.scenario_step_title')} ${p.index + 1}: ${p.message}`).join('; ')
    },
    // Save blockers first, then the lint findings, in one strip.
    notes () {
      const blockers = this.problems.map(p => ({ key: p.key, index: p.index, severity: 'blocker', message: p.message }))
      return blockers.concat(this.lint)
    },
    selectedIndex () {
      this.tick // eslint-disable-line no-unused-expressions
      return this.state.steps.findIndex(step => step.key === this.state.selectedKey)
    },
    selectedStep () {
      const step = this.selectedIndex >= 0 ? this.state.steps[this.selectedIndex] : null
      return step && step.kind !== 'dead' ? step : null
    },
  },
  methods: {
    // Store mutations on nested fields are not always seen by Vue; redraw after each
    // and tell the editor view, which keeps the navbar Save button's count.
    bump () {
      this.tick += 1
      this.$forceUpdate()
      this.$emit('changed', this.store.changes(), this.store.validate())
    },
    isDirty (step) {
      this.tick // eslint-disable-line no-unused-expressions
      return this.store.isDirty(step)
    },
    isQuiz (step) {
      return step.actionData && step.actionData.type === 'prompt-quiz' && Array.isArray(step.actionData.choices)
    },
    render (text) {
      return DOMPurify.sanitize(marked(text || ''))
    },
    // { html, label } when the step embeds a whole HTML document in a code fence, like the Vibe Coding games.
    appOf (step) {
      const match = FENCE.exec(step.text || '')
      if (!match) { return null }
      const [, lang, code] = match
      if (!(lang.toLowerCase() === 'html' || HTML_DOC.test(code))) { return null }
      const title = /<title>([^<]*)<\/title>/i.exec(code)
      const label = title && title[1].trim() ? title[1].trim() : `${Math.round(code.length / 1024)} KB html`
      return { html: code, label }
    },
    // The card shows the text the way the player bubble does: the app behind an Output button, not as a wall of code.
    textWithoutApp (step) {
      return this.appOf(step) ? (step.text || '').replace(FENCE, '').trim() : step.text
    },
    linkAttachments (step) {
      // Only web links become chips: a javascript: or data: url in a document must not be clickable here.
      return (step.documents || []).filter(doc => doc && doc.source && /^https?:\/\//i.test(doc.source.url || '')).map(doc => ({
        url: doc.source.url,
        label: doc.source.linkText || doc.source.url,
      }))
    },
    openPreview (step) {
      const app = this.appOf(step)
      if (!app) { return }
      this.preview = { html: app.html, label: app.label, index: this.state.steps.indexOf(step) }
    },
    closePreview () {
      this.preview = null
    },
    actorLabel (actor) {
      return this.$t(`editor.scenario_script_actor_${actor}`)
    },
    actionLabel (step) {
      const type = (step.actionData && step.actionData.type) || 'continue'
      return this.$t(`editor.scenario_script_action_${type.replace(/-/g, '_')}`)
    },
    kindLabel (kind) {
      return this.$t(`editor.scenario_script_kind_${kind}`)
    },
    attachmentCount (step) {
      return (step.documents || []).length
    },
    languages (step) {
      const langs = Object.keys(step.i18n || {}).filter(lang => lang !== '-')
      return langs.length ? langs.join(' · ') : this.$t('editor.scenario_script_no_translations')
    },
    lintFor (step) {
      return this.lintByKey[step.key] || []
    },
    // A click on the card selects it; clicks on its controls, menus and links do their own thing.
    onCardClick (event, step) {
      if (event.target.closest('.actions, .extras, .dropdown-menu, a, button, input, select, textarea')) { return }
      this.select(step)
    },
    select (step) {
      this.store.select(step.key)
      this.bump()
    },
    selectKey (key) {
      this.store.select(key)
      this.bump()
    },
    deselect () {
      this.store.select(null)
      this.bump()
    },
    move (step, delta) {
      this.store.move(step.key, delta)
      this.bump()
    },
    insertAfter (step, kind) {
      this.store.insertAfter(step.key, kind)
      this.bump()
    },
    append (kind) {
      this.store.append(kind)
      this.bump()
    },
    duplicate (step) {
      this.store.duplicate(step.key)
      this.bump()
    },
    insertCopy (step) {
      const id = window.prompt(this.$t('editor.scenario_script_copy_prompt'))
      if (!id || !id.trim()) { return }
      this.store.insertCopyById(step.key, id.trim()).then(() => this.bump(), err => {
        noty({ type: 'error', text: `${this.$t('editor.scenario_script_copy_failed')} ${err.message || err}`, timeout: 5000 })
      })
    },
    removeFromQueue (step) {
      this.store.removeFromQueue(step.key)
      this.bump()
    },
    deleteMessage (step) {
      if (!window.confirm(this.$t('editor.scenario_script_delete_confirm'))) { return }
      this.store.deleteMessage(step.key)
      this.bump()
    },
    // Called from the editor's actions dropdown.
    discard () {
      if (!this.store.changes().any) { return }
      if (!window.confirm(this.$t('editor.scenario_script_discard_confirm'))) { return }
      this.store.discard().then(() => {
        this.backup = null
        this.bump()
      }, err => {
        noty({ type: 'error', text: err.message || String(err), timeout: 5000 })
      })
    },
    restore () {
      this.store.restoreFromBackup()
      this.backup = null
      this.bump()
    },
    dropBackup () {
      this.store.clearBackup()
      this.backup = null
    },
  },
})
</script>

<style lang="scss" scoped>
.scenario-script-panel {
  margin-bottom: 24px;

  .loading {
    padding: 16px;
    color: #5f594f;
  }

  .restore-bar, .live-warning {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 10px;
  }

  .lint-strip {
    display: flex;
    flex-direction: column;
    gap: 8px;

    .lint-head {
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .lint-list {
      margin: 0;
      padding-left: 18px;
      font-size: 13px;

      li { margin: 2px 0; }
      li.info { color: #5f594f; }
      li.blocker { font-weight: 600; }
      a { margin-right: 6px; }
    }
  }

  .lint-clean {
    margin-bottom: 10px;
    font-size: 12px;
    color: #5f594f;
  }

  .layout {
    display: flex;
    flex-wrap: wrap;
    gap: 20px;
    align-items: flex-start;
  }

  // Script and step panel split the width evenly; the panel wraps under the list on narrow screens.
  .steps-column {
    flex: 1 1 480px;
    min-width: 0;
  }

  .panel-column {
    flex: 1 1 480px;
    min-width: 0;
    position: sticky;
    top: 12px;
  }

  .steps {
    list-style: none;
    margin: 0;
    padding: 0;
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .step {
    display: flex;
    gap: 12px;
    padding: 12px 14px;
    background: #fff;
    border: 1px solid #d8d2c4;
    border-radius: 6px;
    cursor: pointer;

    &.selected {
      border-color: #1f5fa8;
      box-shadow: 0 0 0 1px #1f5fa8;
    }

    &.dead {
      background: #f8f5ee;
      border-style: dashed;
      color: #5f594f;
      cursor: default;
    }

    .index {
      flex: 0 0 26px;
      font-size: 13px;
      color: #5f594f;
      padding-top: 2px;
    }

    .body {
      flex: 1 1 auto;
      min-width: 0;
      display: flex;
      flex-direction: column;
      gap: 6px;
    }

    .dead-body {
      flex-direction: row;
      align-items: baseline;
      gap: 10px;
    }

    .meta {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 6px;
      font-size: 12px;
    }

    .badge-actor, .chip {
      padding: 1px 8px;
      border-radius: 999px;
      background: #efece4;
      color: #4a4439;
    }

    .badge-actor {
      font-weight: 700;

      &.teacher { background: #e2efd9; color: #1f5a1f; }
      &.user { background: #dde8f7; color: #173f7a; }
      &.model { background: #ece3f7; color: #4b2a7a; }
      &.celebrate { background: #fdebd0; color: #7a3e00; }
      &.alert { background: #fde8e1; color: #8a2d0c; }
    }

    .chip.pending {
      background: #fde8e1;
      color: #8a2d0c;
      font-weight: 600;
    }

    .chip.lint.warning {
      background: #fdebd0;
      color: #7a3e00;
    }

    .chip.lint.info {
      background: #efece4;
      color: #5f594f;
    }

    .langs {
      margin-left: auto;
      color: #5f594f;
    }

    .text {
      font-size: 15px;
      line-height: 1.45;
      overflow-wrap: anywhere;

      ::v-deep p { margin: 0 0 6px; }
      ::v-deep p:last-child { margin-bottom: 0; }
      ::v-deep pre { max-height: 140px; overflow: auto; font-size: 12px; }
      ::v-deep img { max-width: 100%; }
    }

    .extras {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 8px;
      font-size: 12px;

      .chip.link {
        text-decoration: none;
        color: #1f5fa8;
        background: #faf8f3;
        border: 1px solid #d8d2c4;
      }
    }

    .choices {
      list-style: none;
      margin: 0;
      padding: 0;
      display: flex;
      flex-direction: column;
      gap: 4px;
      font-size: 13px;

      li {
        display: flex;
        gap: 8px;
        align-items: baseline;
      }

      .mark {
        flex: 0 0 56px;
        padding: 0 6px;
        border-radius: 4px;
        background: #efece4;
        color: #4a4439;
        font-size: 11px;
        text-align: center;
      }

      .correct .mark {
        background: #e2efd9;
        color: #1f5a1f;
        font-weight: 700;
      }

      .feedback {
        color: #5f594f;
      }
    }

    .actions {
      display: flex;
      gap: 4px;
      align-self: flex-start;
      flex-wrap: wrap;
      justify-content: flex-end;
      max-width: 230px;

      .danger { color: #8a2d0c; }
    }
  }

  .add-row {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-top: 10px;
  }

  .preview-overlay {
    position: fixed;
    inset: 0;
    z-index: 1050;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 24px;
    background: rgba(31, 28, 23, 0.6);
  }

  .preview-window {
    display: flex;
    flex-direction: column;
    width: min(1100px, 100%);
    height: min(820px, 100%);
    background: #fff;
    border-radius: 8px;
    overflow: hidden;
  }

  .preview-head {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 10px 14px;
    border-bottom: 1px solid #d8d2c4;
    font-size: 13px;

    .muted { color: #5f594f; }
    .btn { margin-left: auto; }
  }

  .preview-frame {
    flex: 1 1 auto;
    width: 100%;
    border: 0;
    background: #fff;
  }
}
</style>
