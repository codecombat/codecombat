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
  },
  computed: {
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
  methods: {
    changed () {
      this.$emit('changed')
    },
    setActor (actor) {
      this.store.setActor(this.step.key, actor)
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
