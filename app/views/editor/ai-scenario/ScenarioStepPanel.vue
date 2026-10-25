<template>
  <div class="scenario-step-panel">
    <div class="head">
      <h4>{{ $t('editor.scenario_step_title') }} {{ index + 1 }} · {{ actionLabel }}</h4>
      <div class="ids">
        <code v-if="step.id">{{ step.id }}</code>
        <span v-else>{{ $t('editor.scenario_script_new') }}</span>
        <a
          v-if="step.id"
          :href="'/editor/ai-chat-message/' + step.id"
          target="_blank"
        >{{ $t('editor.scenario_step_raw') }}</a>
      </div>
      <button
        class="close"
        :title="$t('modal.close')"
        @click="$emit('close')"
      >
        &times;
      </button>
    </div>

    <div class="row-2">
      <label>
        <span>{{ $t('editor.scenario_step_actor') }}</span>
        <select
          class="form-control"
          :value="step.actor"
          :disabled="readOnly"
          @change="setActor($event.target.value)"
        >
          <option
            v-for="actor in store.ACTORS"
            :key="actor"
            :value="actor"
          >
            {{ $t('editor.scenario_script_actor_' + actor) }}
          </option>
        </select>
      </label>
      <label>
        <span>{{ $t('editor.scenario_step_action') }}</span>
        <select
          class="form-control"
          :value="actionType"
          :disabled="readOnly"
          @change="setActionType($event.target.value)"
        >
          <option
            v-for="type in store.ACTION_TYPES"
            :key="type"
            :value="type"
          >
            {{ $t('editor.scenario_script_action_' + type.replace(/-/g, '_')) }}
          </option>
        </select>
      </label>
    </div>

    <label class="text-field">
      <span>{{ $t('editor.scenario_step_text') }}</span>
      <span
        v-if="isQuiz"
        class="hint"
      >{{ $t('editor.scenario_step_text_quiz_hint') }}</span>
      <textarea
        class="form-control"
        rows="5"
        :value="step.text"
        :disabled="readOnly || isQuiz"
        @input="setText($event.target.value)"
      />
    </label>

    <fieldset
      v-if="isQuiz"
      class="choices"
    >
      <legend>{{ $t('editor.scenario_step_choices') }}</legend>
      <div
        v-for="(choice, i) in step.actionData.choices"
        :key="i"
        :class="['choice', { correct: i === step.actionData.answerIndex }]"
      >
        <div class="choice-head">
          <label class="radio-label">
            <input
              type="radio"
              :name="'correct-' + step.key"
              :checked="i === step.actionData.answerIndex"
              :disabled="readOnly"
              @change="setAnswerIndex(i)"
            >
            <span>{{ i === step.actionData.answerIndex ? $t('editor.scenario_step_correct_choice') : $t('editor.scenario_step_choice') + ' ' + (i + 1) }}</span>
          </label>
          <button
            v-if="!readOnly && step.actionData.choices.length > 1"
            class="btn btn-link btn-xs"
            @click="removeChoice(i)"
          >
            {{ $t('editor.scenario_step_remove_choice') }}
          </button>
        </div>
        <input
          class="form-control"
          type="text"
          :value="choice.text"
          :disabled="readOnly"
          :placeholder="$t('editor.scenario_step_choice_text')"
          @input="setChoice(i, { text: $event.target.value })"
        >
        <input
          class="form-control"
          type="text"
          :value="choice.responseText"
          :disabled="readOnly"
          :placeholder="$t('editor.scenario_step_feedback')"
          @input="setChoice(i, { responseText: $event.target.value })"
        >
      </div>
      <button
        v-if="!readOnly"
        class="btn btn-default btn-sm"
        @click="addChoice"
      >
        {{ $t('editor.scenario_step_add_choice') }}
      </button>
    </fieldset>

    <div class="section story">
      <button
        type="button"
        class="section-title toggle"
        @click="storyOpen = !storyOpen"
      >
        <span :class="['caret', { open: storyOpen }]" />
        {{ $t('editor.scenario_step_story') }}
      </button>
      <div
        v-if="storyOpen"
        class="story-fields"
      >
        <label v-if="speakerByRole">
          <span>{{ $t('editor.scenario_step_speaker') }}</span>
          <span class="static">{{ $t('editor.scenario_step_speaker_by_role') }} {{ roleLabel }}</span>
        </label>
        <label v-else>
          <span>{{ $t('editor.scenario_step_speaker') }}</span>
          <select
            class="form-control speaker"
            :value="step.character || ''"
            :disabled="readOnly"
            @change="setStoryField('character', $event.target.value)"
          >
            <option value="">
              {{ speakerDefaultLabel }}
            </option>
            <option
              v-if="unknownCharacter"
              :value="step.character"
            >
              ⚠ {{ $t('editor.scenario_step_unknown') }} {{ step.character }}
            </option>
            <optgroup
              v-for="group in speakerGroups"
              :key="group.source"
              :label="group.source"
            >
              <option
                v-for="c in group.entries"
                :key="c.id"
                :value="c.id"
              >
                {{ c.name }} · {{ c.id }}
              </option>
            </optgroup>
          </select>
        </label>
        <label>
          <span>{{ $t('editor.scenario_step_objective') }}</span>
          <select
            class="form-control objective"
            :value="step.objective || ''"
            :disabled="readOnly"
            @change="setStoryField('objective', $event.target.value)"
          >
            <option value="">
              {{ $t('editor.scenario_step_objective_none') }}
            </option>
            <option
              v-if="unknownObjective"
              :value="step.objective"
            >
              ⚠ {{ $t('editor.scenario_step_unknown') }} {{ step.objective }}
            </option>
            <option
              v-for="o in story.objectives"
              :key="o.id"
              :value="o.id"
            >
              {{ o.id }} — {{ truncate(o.text) }}
            </option>
          </select>
        </label>
        <label>
          <span>{{ $t('editor.scenario_step_background') }}</span>
          <select
            class="form-control background"
            :value="step.background || ''"
            :disabled="readOnly"
            @change="setStoryField('background', $event.target.value)"
          >
            <option value="">
              {{ $t('editor.scenario_step_background_none') }}
            </option>
            <option
              v-if="unknownBackground"
              :value="step.background"
            >
              ⚠ {{ $t('editor.scenario_step_unknown') }} {{ step.background }}
            </option>
            <optgroup
              v-for="group in backgroundGroups"
              :key="group.source"
              :label="group.source"
            >
              <option
                v-for="b in group.entries"
                :key="b.id"
                :value="b.id"
              >
                {{ b.id }}
              </option>
            </optgroup>
          </select>
        </label>
        <fieldset
          v-if="actionType === 'continue'"
          class="pacing"
        >
          <legend>{{ $t('editor.scenario_step_pacing') }}</legend>
          <label class="radio-label">
            <input
              type="radio"
              :name="'pacing-' + step.key"
              value="derived"
              :checked="pacing === 'derived'"
              :disabled="readOnly"
              @change="setPacing('derived')"
            >
            <span>{{ $t('editor.scenario_step_pacing_derived') }}</span>
          </label>
          <label class="radio-label">
            <input
              type="radio"
              :name="'pacing-' + step.key"
              value="wait"
              :checked="pacing === 'wait'"
              :disabled="readOnly"
              @change="setPacing('wait')"
            >
            <span>{{ $t('editor.scenario_step_pacing_wait') }}</span>
          </label>
          <label class="radio-label auto">
            <input
              type="radio"
              :name="'pacing-' + step.key"
              value="auto"
              :checked="pacing === 'auto'"
              :disabled="readOnly"
              @change="setPacing('auto')"
            >
            <span>{{ $t('editor.scenario_step_pacing_auto_after') }}</span>
            <input
              class="form-control ms"
              type="number"
              min="100"
              step="100"
              :value="autoAdvanceMs"
              :disabled="readOnly || pacing !== 'auto'"
              @change="setAutoAdvanceMs($event.target.value)"
            >
            <span>ms</span>
          </label>
        </fieldset>
        <p class="hint">
          {{ $t('editor.scenario_step_story_hint_speaker') }}
        </p>
        <p
          v-if="actionType === 'continue'"
          class="hint"
        >
          {{ $t('editor.scenario_step_story_hint_pacing') }}
        </p>
      </div>
    </div>

    <div class="section">
      <div class="section-title">
        {{ $t('editor.scenario_step_attachments') }}
      </div>
      <ul
        v-if="attachments.length"
        class="attachments"
      >
        <li
          v-for="doc in attachments"
          :key="doc.id"
        >
          <span class="chip">{{ doc.kind }}</span>
          <span>{{ doc.label }}</span>
        </li>
      </ul>
      <div
        v-else
        class="muted"
      >
        {{ $t('editor.scenario_step_no_attachments') }}
      </div>
      <a
        v-if="step.id"
        :href="'/editor/ai-chat-message/' + step.id"
        target="_blank"
      >{{ $t('editor.scenario_step_edit_attachments') }}</a>
    </div>

    <div class="section">
      <div class="section-title">
        {{ $t('editor.scenario_step_translations') }}
      </div>
      <div
        v-if="languages.length"
        class="langs"
      >
        <span
          v-for="lang in languages"
          :key="lang"
          class="chip"
        >{{ lang }}</span>
      </div>
      <div
        v-else
        class="muted"
      >
        {{ $t('editor.scenario_script_no_translations') }}
      </div>
    </div>
  </div>
</template>

<script>
const EMPTY_STORY = { isStory: false, characters: [], objectives: [], backgrounds: [], defaultAlly: null, missingWorld: null }
const SPEAKER_ROLES = ['ally', 'npc']
const DEFAULT_AUTO_ADVANCE_MS = 1000

// Entries grouped by their source (scenario first, then each world), in the order given.
function groupBySource (entries) {
  const groups = []
  for (const entry of entries) {
    let group = groups.find(g => g.source === entry.source)
    if (!group) { groups.push(group = { source: entry.source, entries: [] }) }
    group.entries.push(entry)
  }
  return groups
}

// The selected step, in full: every field the Script tab can change, plus
// read-only attachments and translations. Writes go through the store; the
// parent redraws on `changed`.
export default Vue.extend({
  name: 'ScenarioStepPanel',
  props: {
    store: { type: Object, required: true },
    step: { type: Object, required: true },
    index: { type: Number, required: true },
    readOnly: { type: Boolean, default: false },
    // From lib/story-world-chain buildStoryContext; null while the editor has none.
    storyContext: { type: Object, default: null },
  },
  data () {
    const story = this.storyContext || EMPTY_STORY
    // Open where the fields matter: story scenarios, and steps that already have a story field or pacing.
    return { storyOpen: Boolean(story.isStory) || this.hasStoryData() }
  },
  computed: {
    story () {
      return this.storyContext || EMPTY_STORY
    },
    speakerByRole () {
      return this.store.BY_ROLE_ACTORS.includes(this.step.actor)
    },
    roleLabel () {
      return this.$t(this.step.actor === 'user' ? 'editor.scenario_step_speaker_role_player' : 'editor.scenario_step_speaker_role_hackstack')
    },
    speakers () {
      return this.story.characters.filter(c => SPEAKER_ROLES.includes(c.role))
    },
    speakerGroups () {
      return groupBySource(this.speakers)
    },
    speakerDefaultLabel () {
      const ally = this.story.defaultAlly && this.story.characters.find(c => c.id === this.story.defaultAlly)
      if (!ally) { return `(${this.$t('editor.scenario_step_speaker_default')} ${this.$t('editor.scenario_step_speaker_no_ally')})` }
      return `(${this.$t('editor.scenario_step_speaker_default')} ${ally.name} — ${this.$t('editor.scenario_step_speaker_nearest_ally')})`
    },
    unknownCharacter () {
      return Boolean(this.step.character) && !this.speakers.some(c => c.id === this.step.character)
    },
    unknownObjective () {
      return Boolean(this.step.objective) && !this.story.objectives.some(o => o.id === this.step.objective)
    },
    backgroundGroups () {
      return groupBySource(this.story.backgrounds)
    },
    unknownBackground () {
      return Boolean(this.step.background) && !this.story.backgrounds.some(b => b.id === this.step.background)
    },
    // null/absent = derived from the queue by the story page, 0 = wait for Continue, > 0 = auto after that many ms.
    pacing () {
      const value = this.step.actionData && this.step.actionData.autoAdvance
      if (value === 0) { return 'wait' }
      if (typeof value === 'number' && value > 0) { return 'auto' }
      return 'derived'
    },
    autoAdvanceMs () {
      return this.pacing === 'auto' ? this.step.actionData.autoAdvance : DEFAULT_AUTO_ADVANCE_MS
    },
    actionType () {
      return (this.step.actionData && this.step.actionData.type) || 'continue'
    },
    actionLabel () {
      return this.$t(`editor.scenario_script_action_${this.actionType.replace(/-/g, '_')}`)
    },
    isQuiz () {
      return this.actionType === 'prompt-quiz' && Array.isArray(this.step.actionData.choices)
    },
    attachments () {
      return (this.step.documents || []).map((doc, i) => {
        if (typeof doc === 'string') { return { id: doc, kind: 'document', label: doc } }
        const source = doc.source || {}
        const label = source.linkText || source.fileName || source.url || source.filePath || doc._id || `#${i + 1}`
        return { id: doc._id || `${i}`, kind: source.type || 'document', label }
      })
    },
    languages () {
      return Object.keys(this.step.i18n || {}).filter(lang => lang !== '-')
    },
  },
  watch: {
    'storyContext.isStory' (isStory) {
      if (isStory) { this.storyOpen = true }
    },
  },
  methods: {
    changed () {
      this.$emit('changed')
    },
    hasStoryData () {
      const step = this.step
      return this.store.STORY_FIELDS.some(field => Boolean(step[field])) || (step.actionData && step.actionData.autoAdvance !== undefined)
    },
    truncate (text) {
      const line = (text || '').replace(/\s+/g, ' ').trim()
      return line.length > 60 ? `${line.slice(0, 60)}…` : line
    },
    setActor (actor) {
      this.store.setActor(this.step.key, actor)
      this.changed()
    },
    setStoryField (field, value) {
      this.store.setStoryField(this.step.key, field, value)
      this.changed()
    },
    setPacing (mode) {
      const value = mode === 'wait' ? 0 : mode === 'auto' ? this.autoAdvanceMs : null
      this.store.setAutoAdvance(this.step.key, value)
      this.changed()
    },
    setAutoAdvanceMs (raw) {
      const ms = parseInt(raw, 10)
      if (!Number.isInteger(ms)) { return }
      this.store.setAutoAdvance(this.step.key, Math.max(100, ms))
      this.changed()
    },
    setActionType (type) {
      this.store.setActionType(this.step.key, type)
      this.changed()
    },
    setText (text) {
      this.store.setText(this.step.key, text)
      this.changed()
    },
    setChoice (i, fields) {
      this.store.setChoice(this.step.key, i, fields)
      this.changed()
    },
    setAnswerIndex (i) {
      this.store.setAnswerIndex(this.step.key, i)
      this.changed()
    },
    addChoice () {
      this.store.addChoice(this.step.key)
      this.changed()
    },
    removeChoice (i) {
      this.store.removeChoice(this.step.key, i)
      this.changed()
    },
  },
})
</script>

<style lang="scss" scoped>
.scenario-step-panel {
  display: flex;
  flex-direction: column;
  gap: 14px;
  padding: 16px;
  background: #fff;
  border: 1px solid #d8d2c4;
  border-radius: 6px;

  .head {
    display: flex;
    flex-wrap: wrap;
    align-items: baseline;
    gap: 8px;

    h4 {
      margin: 0;
      font-size: 16px;
      font-weight: 700;
    }

    .ids {
      display: flex;
      gap: 8px;
      font-size: 12px;
      color: #5f594f;
    }

    .close {
      margin-left: auto;
    }
  }

  label {
    display: flex;
    flex-direction: column;
    gap: 4px;
    font-weight: 600;
    font-size: 12px;
    color: #4a4439;
    margin: 0;
  }

  .row-2 {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 12px;
  }

  .text-field textarea {
    font-weight: 400;
    font-size: 14px;
    line-height: 1.45;
    resize: vertical;
  }

  .hint {
    font-weight: 400;
    color: #5f594f;
  }

  .story {
    .toggle {
      display: flex;
      align-items: center;
      gap: 6px;
      padding: 0;
      border: 0;
      background: none;
      font: inherit;
      font-size: 12px;
      font-weight: 600;
      color: #4a4439;
      cursor: pointer;

      .caret {
        display: inline-block;
        width: 0;
        height: 0;
        border-left: 5px solid #4a4439;
        border-top: 4px solid transparent;
        border-bottom: 4px solid transparent;
        transition: transform 0.15s;

        &.open { transform: rotate(90deg); }
      }
    }

    .story-fields {
      display: flex;
      flex-direction: column;
      gap: 10px;
      margin-top: 8px;
    }

    .static {
      font-weight: 400;
      font-size: 13px;
      color: #4a4439;
      padding: 6px 0;
    }

    .pacing {
      display: flex;
      flex-wrap: wrap;
      gap: 8px 16px;
      padding: 10px 12px;
      border: 1px solid #d8d2c4;
      border-radius: 6px;

      legend {
        font-size: 12px;
        font-weight: 600;
        color: #4a4439;
        width: auto;
        padding: 0 4px;
        margin: 0;
        border: 0;
      }

      .radio-label {
        flex-direction: row;
        align-items: center;
        gap: 6px;
        font-weight: 400;
        font-size: 13px;
        margin: 0;

        input[type="radio"] { margin: 0; }
      }

      .ms {
        width: 90px;
        height: 28px;
        padding: 2px 6px;
        font-size: 13px;
      }
    }

    p.hint {
      margin: 0;
      font-size: 12px;
    }
  }

  .choices {
    display: flex;
    flex-direction: column;
    gap: 10px;
    padding: 12px;
    border: 1px solid #d8d2c4;
    border-radius: 6px;

    legend {
      font-size: 12px;
      font-weight: 600;
      color: #4a4439;
      width: auto;
      padding: 0 4px;
      margin: 0;
      border: 0;
    }

    .choice {
      display: flex;
      flex-direction: column;
      gap: 6px;
      padding: 10px;
      border-radius: 6px;
      background: #faf8f3;

      &.correct {
        background: #f1f7ec;
      }
    }

    .choice-head {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .radio-label {
      flex-direction: row;
      align-items: center;
      gap: 8px;
      font-size: 12px;

      input {
        margin: 0;
      }
    }

    .btn-link {
      margin-left: auto;
      padding: 0 4px;
    }

    .form-control {
      font-weight: 400;
    }
  }

  .section {
    display: flex;
    flex-direction: column;
    gap: 6px;
    font-size: 13px;

    .section-title {
      font-size: 12px;
      font-weight: 600;
      color: #4a4439;
    }
  }

  .attachments {
    list-style: none;
    margin: 0;
    padding: 0;
    display: flex;
    flex-direction: column;
    gap: 4px;

    li {
      display: flex;
      gap: 8px;
      align-items: baseline;
      overflow-wrap: anywhere;
    }
  }

  .langs {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
  }

  .chip {
    padding: 1px 8px;
    border-radius: 999px;
    background: #efece4;
    color: #4a4439;
    font-size: 12px;
  }

  .muted {
    color: #5f594f;
  }
}
</style>
