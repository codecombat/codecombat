<template>
  <fieldset class="scenario-step-exits">
    <legend>{{ $t('editor.scenario_step_exits') }}</legend>
    <p class="hint">
      {{ exits.length ? $t('editor.scenario_step_exits_hint') : $t('editor.scenario_step_exits_none') }}
    </p>
    <div
      v-for="(exit, i) in exits"
      :key="i"
      class="exit"
    >
      <select
        class="form-control kind"
        :value="exit.kind"
        :disabled="readOnly"
        @change="setExit(i, { kind: $event.target.value })"
      >
        <option
          v-for="kind in store.EXIT_KINDS"
          :key="kind"
          :value="kind"
        >
          {{ kindLabel(kind) }}
        </option>
      </select>
      <input
        class="form-control exit-label"
        type="text"
        :value="exit.label || ''"
        :disabled="readOnly"
        :placeholder="kindLabel(exit.kind)"
        @input="setExit(i, { label: $event.target.value })"
      >
      <template v-if="!readOnly">
        <button
          class="btn btn-link btn-xs"
          :disabled="i === 0"
          :title="$t('editor.scenario_script_move_up')"
          @click="moveExit(i, -1)"
        >
          &uarr;
        </button>
        <button
          class="btn btn-link btn-xs"
          :disabled="i === exits.length - 1"
          :title="$t('editor.scenario_script_move_down')"
          @click="moveExit(i, 1)"
        >
          &darr;
        </button>
        <button
          class="btn btn-link btn-xs"
          @click="removeExit(i)"
        >
          {{ $t('editor.scenario_step_remove_exit') }}
        </button>
      </template>
    </div>
    <div
      v-if="!readOnly"
      class="add-exit"
    >
      <button
        v-for="kind in store.EXIT_KINDS"
        :key="kind"
        class="btn btn-default btn-sm"
        @click="addExit(kind)"
      >
        + {{ kindLabel(kind) }}
      </button>
    </div>

    <div class="next-level">
      <span class="field-title">{{ $t('editor.scenario_step_next_level') }}</span>
      <div class="current">
        <span v-if="!nextLevel">{{ $t('editor.scenario_step_next_level_from_map') }}</span>
        <template v-else>
          <strong>{{ nextLevelName || nextLevel }}</strong>
          <code>{{ nextLevel }}</code>
          <button
            v-if="!readOnly"
            class="btn btn-link btn-xs"
            @click="setNextLevel(null)"
          >
            {{ $t('editor.scenario_step_next_level_from_map') }}
          </button>
        </template>
      </div>
      <input
        v-if="!readOnly"
        class="form-control"
        type="search"
        :value="term"
        :placeholder="$t('editor.scenario_step_next_level_search')"
        @input="search($event.target.value)"
      >
      <ul
        v-if="results.length"
        class="results"
      >
        <li
          v-for="scenario in results"
          :key="scenario.original"
        >
          <a
            href="#"
            @click.prevent="pick(scenario)"
          >{{ scenario.name }} <code>{{ scenario.original }}</code></a>
        </li>
      </ul>
    </div>
  </fieldset>
</template>

<script>
const defaultFetchJson = require('core/api/fetch-json')

const SEARCH_DELAY_MS = 250

// The buttons an end step offers after its closing line, and the scenario its Next level button goes to. Writes go
// through the store; the step panel redraws on `changed`. The search is the one the scenario Treema node runs
// (AIScenarioNode), and it stores the scenario's original.
export default Vue.extend({
  name: 'ScenarioStepExits',
  props: {
    store: { type: Object, required: true },
    step: { type: Object, required: true },
    readOnly: { type: Boolean, default: false },
    fetchJson: { type: Function, default: defaultFetchJson },
  },
  data () {
    return { term: '', results: [], names: {} }
  },
  computed: {
    exits () {
      return this.step.actionData.exits || []
    },
    nextLevel () {
      return this.step.actionData.nextLevel || null
    },
    nextLevelName () {
      return this.names[this.nextLevel] || null
    },
  },
  watch: {
    nextLevel: {
      immediate: true,
      handler (original) {
        if (original && !this.names[original]) { this.loadName(original) }
      },
    },
  },
  beforeDestroy () {
    clearTimeout(this.searchTimer)
  },
  methods: {
    changed () {
      this.$emit('changed')
    },
    kindLabel (kind) {
      return this.$t(`editor.scenario_step_exit_${kind.replace(/-/g, '_')}`)
    },
    addExit (kind) {
      this.store.addExit(this.step.key, kind)
      this.changed()
    },
    setExit (i, fields) {
      this.store.setExit(this.step.key, i, fields)
      this.changed()
    },
    moveExit (i, delta) {
      if (this.store.moveExit(this.step.key, i, delta)) { this.changed() }
    },
    removeExit (i) {
      this.store.removeExit(this.step.key, i)
      this.changed()
    },
    setNextLevel (original) {
      this.store.setNextLevel(this.step.key, original)
      this.changed()
    },
    search (term) {
      this.term = term
      clearTimeout(this.searchTimer)
      if (term.trim().length < 2) {
        this.searchRequest = (this.searchRequest || 0) + 1 // answers still on their way no longer apply
        this.results = []
        return
      }
      this.searchTimer = setTimeout(() => this.runSearch(term.trim()), SEARCH_DELAY_MS)
    },
    // Only the latest request may touch the results, whether it succeeds or fails; a counter also tells two requests
    // for the same term apart.
    runSearch (term) {
      const request = this.searchRequest = (this.searchRequest || 0) + 1
      this.fetchJson(`/db/ai_scenario?term=${encodeURIComponent(term)}&project=_id,original,name&limit=10`).then(found => {
        if (request !== this.searchRequest) { return }
        this.results = (found || []).filter(scenario => scenario.original)
      }, () => {
        if (request !== this.searchRequest) { return }
        this.results = []
      })
    },
    pick (scenario) {
      this.names = Object.assign({}, this.names, { [scenario.original]: scenario.name })
      this.setNextLevel(scenario.original)
      this.term = ''
      this.results = []
    },
    loadName (original) {
      this.fetchJson(`/db/ai_scenario/${original}/version?project=name`).then(scenario => {
        if (scenario && scenario.name) { this.names = Object.assign({}, this.names, { [original]: scenario.name }) }
      }, () => {})
    },
  },
})
</script>

<style lang="scss" scoped>
.scenario-step-exits {
  display: flex;
  flex-direction: column;
  gap: 8px;

  .hint {
    margin: 0;
    color: #5f594f;
    font-size: 12px;
  }

  .exit {
    display: flex;
    align-items: center;
    gap: 6px;

    .kind {
      flex: 0 0 150px;
    }

    .exit-label {
      flex: 1 1 auto;
    }
  }

  .add-exit {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
  }

  .next-level {
    display: flex;
    flex-direction: column;
    gap: 6px;
    margin-top: 6px;

    .field-title {
      font-weight: 600;
    }

    .current {
      display: flex;
      flex-wrap: wrap;
      align-items: baseline;
      gap: 6px;
    }

    .results {
      margin: 0;
      padding: 0;
      list-style: none;
      border: 1px solid #d8d2c4;
      border-radius: 4px;

      li a {
        display: block;
        padding: 4px 8px;
      }
    }
  }
}
</style>
