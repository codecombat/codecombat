<template>
  <div class="ai-junior-class-print">
    <div class="print-toolbar no-print">
      <h2 v-if="scenario && classroom">
        Print "{{ scenario.name }}" for {{ classroom.name }}
      </h2>
      <p
        v-if="members.length"
        class="member-count"
      >
        {{ members.length }} student worksheet{{ members.length === 1 ? '' : 's' }}, each with its own QR code.
        Use landscape US Letter paper.
      </p>
      <div class="toolbar-actions">
        <button
          class="btn btn-primary btn-lg"
          :disabled="loading || !members.length"
          @click="printAll"
        >
          🖨 Print All
        </button>
        <a
          v-if="classroom"
          class="btn btn-default"
          :href="`/ai-junior/print/${scenarioHandle}`"
        >Choose a different class</a>
      </div>
    </div>

    <div
      v-if="loading"
      class="loading no-print"
    >
      <div class="spinner" />
      <p>Loading…</p>
    </div>

    <div
      v-else-if="!classroomId"
      class="classroom-picker no-print"
    >
      <h3>Which class is this for?</h3>
      <p v-if="!classrooms.length">
        You don't have any classes yet.
      </p>
      <ul>
        <li
          v-for="c in classrooms"
          :key="c._id"
        >
          <a
            class="btn btn-default"
            :href="`/ai-junior/print/${scenarioHandle}/${c._id}`"
          >
            {{ c.name }} ({{ (c.members || []).length }} students)
          </a>
        </li>
      </ul>
    </div>

    <div
      v-else
      class="sheets"
    >
      <div
        v-for="member in members"
        :key="member._id"
        class="sheet-wrapper"
      >
        <AIJuniorWorksheet
          :scenario="scenario"
          :print-user="member"
        />
      </div>
    </div>
  </div>
</template>

<script>
import AIJuniorWorksheet from 'app/components/common/elements/AIJuniorWorksheet.vue'
import { getAIJuniorScenario } from 'app/core/api/ai-junior-scenarios'
const classroomsApi = require('app/core/api/classrooms')

export default {
  name: 'AIJuniorClassPrintView',
  components: {
    AIJuniorWorksheet,
  },
  data: () => ({
    loading: true,
    scenario: null,
    classroom: null,
    classrooms: [],
    members: [],
  }),
  computed: {
    scenarioHandle () {
      return this.$route.params.scenarioHandle
    },
    classroomId () {
      return this.$route.params.classroomId
    },
  },
  async created () {
    try {
      this.scenario = await getAIJuniorScenario({ scenarioHandle: this.scenarioHandle })
      if (this.classroomId) {
        this.classroom = await classroomsApi.get({ classroomID: this.classroomId })
        const members = await classroomsApi.getMembers({ classroom: this.classroom }, { removeDeleted: true })
        this.members = _.sortBy(members, (m) => (m.name || m.firstName || '').toLowerCase())
      } else {
        this.classrooms = await fetch(`/db/classroom?ownerID=${me.id}`, { credentials: 'same-origin' }).then((res) => res.json())
      }
    } catch (err) {
      console.error('Failed to load class print data:', err)
      noty({ text: 'Failed to load class data', type: 'error', timeout: 5000 })
    } finally {
      this.loading = false
    }
  },
  methods: {
    printAll () {
      window.print()
    },
  },
}
</script>

<style lang="scss" scoped>
.ai-junior-class-print {
  max-width: 1150px;
  margin: 0 auto;
}

.print-toolbar {
  text-align: center;
  margin-bottom: 2rem;

  .member-count {
    color: #555;
  }

  .toolbar-actions {
    display: flex;
    gap: 1rem;
    justify-content: center;
    margin-top: 1rem;
  }
}

.loading {
  text-align: center;
  padding: 4rem 0;
  color: #666;
}

.spinner {
  border: 4px solid #f3f3f3;
  border-top: 4px solid #3498db;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  margin: 0 auto 1rem;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.classroom-picker {
  text-align: center;

  ul {
    list-style: none;
    padding: 0;
    display: flex;
    flex-direction: column;
    gap: 0.8rem;
    align-items: center;
  }
}

.sheet-wrapper {
  margin-bottom: 3rem;
}

@media print {
  .sheet-wrapper {
    margin-bottom: 0;
    page-break-after: always;
  }

  .sheet-wrapper:last-child {
    page-break-after: auto;
  }
}
</style>
