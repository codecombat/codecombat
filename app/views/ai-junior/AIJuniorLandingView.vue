<template>
  <div class="ai-junior-landing">
    <div class="hero">
      <h1>Turn paper crafts into AI magic</h1>
      <p class="tagline">
        Print a worksheet, draw and write on paper, then scan it to make
        artwork, stories, games, and more from your creation.
      </p>
    </div>

    <div class="toolbar">
      <input
        v-model="searchText"
        type="search"
        class="search-input"
        placeholder="Search activities…"
      >
      <select
        v-model="subjectFilter"
        class="subject-select"
      >
        <option value="">
          All subjects
        </option>
        <option
          v-for="subject in allSubjects"
          :key="subject"
          :value="subject"
        >
          {{ subjectLabel(subject) }}
        </option>
      </select>
      <a
        v-if="isAdmin"
        class="btn btn-primary admin-new"
        href="/editor/ai-junior-scenario"
      >
        Scenario Editor
      </a>
    </div>

    <div
      v-if="loading"
      class="loading"
    >
      <div class="spinner" />
      <p>Loading activities…</p>
    </div>

    <div
      v-else-if="filteredScenarios.length === 0"
      class="empty"
    >
      <p>No activities found.</p>
    </div>

    <div
      v-else
      class="scenario-grid"
    >
      <div
        v-for="scenario in filteredScenarios"
        :key="scenario._id"
        class="scenario-card"
      >
        <a
          :href="worksheetUrl(scenario)"
          class="card-cover"
        >
          <img
            v-if="scenario.coverImage"
            :src="`/file/${scenario.coverImage}`"
            :alt="scenario.name"
          >
          <div
            v-else
            class="cover-placeholder"
          >
            ✏️
          </div>
        </a>
        <div class="card-body">
          <h3>
            <a :href="worksheetUrl(scenario)">{{ scenario.name }}</a>
            <span
              v-if="scenario.releasePhase !== 'released'"
              class="phase-badge"
            >{{ scenario.releasePhase }}</span>
          </h3>
          <p class="description">
            {{ scenario.description }}
          </p>
          <div class="card-meta">
            <span
              v-if="gradeRange(scenario)"
              class="grades"
            >Grades {{ gradeRange(scenario) }}</span>
            <span
              v-for="subject in scenario.subjects || []"
              :key="subject"
              class="subject-chip"
            >{{ subjectLabel(subject) }}</span>
          </div>
          <div class="card-actions">
            <a
              class="btn btn-primary"
              :href="worksheetUrl(scenario)"
            >Start</a>
            <a
              class="btn btn-default"
              :href="scanUrl(scenario)"
            >📷 Scan</a>
            <a
              class="btn btn-default"
              :href="`${worksheetUrl(scenario)}/${meId}`"
            >My projects</a>
            <a
              v-if="isTeacher"
              class="btn btn-default"
              :href="`/ai-junior/print/${scenario.slug || scenario._id}`"
            >Print for class</a>
            <a
              v-if="isAdmin"
              class="btn btn-default"
              :href="`/editor/ai-junior-scenario/${scenario.slug || scenario._id}`"
            >Edit</a>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { getAIJuniorScenarios } from 'app/core/api/ai-junior-scenarios'

const SUBJECT_LABELS = {
  math: 'Math',
  ela: 'ELA',
  science: 'Science',
  'social-studies': 'Social Studies',
  art: 'Art',
  technology: 'Technology',
  sel: 'SEL',
  music: 'Music',
  'computer-science': 'Computer Science',
  misc: 'Miscellaneous',
}

export default {
  name: 'AIJuniorLandingView',
  data () {
    return {
      scenarios: [],
      loading: true,
      searchText: '',
      subjectFilter: '',
    }
  },
  computed: {
    isAdmin () {
      return me.isAdmin()
    },
    isTeacher () {
      return me.isAdmin() || me.isTeacher()
    },
    meId () {
      return me.id
    },
    visibleScenarios () {
      // Everyone sees released scenarios; admins also see drafts/betas so
      // they can test before release.
      if (this.isAdmin) return this.scenarios
      return this.scenarios.filter((s) => s.releasePhase === 'released')
    },
    allSubjects () {
      const subjects = new Set()
      for (const scenario of this.visibleScenarios) {
        for (const subject of scenario.subjects || []) subjects.add(subject)
      }
      return [...subjects].sort()
    },
    filteredScenarios () {
      const search = this.searchText.trim().toLowerCase()
      return this.visibleScenarios.filter((scenario) => {
        if (this.subjectFilter && !(scenario.subjects || []).includes(this.subjectFilter)) return false
        if (search) {
          const haystack = `${scenario.name} ${scenario.description || ''}`.toLowerCase()
          if (!haystack.includes(search)) return false
        }
        return true
      })
    },
  },
  async created () {
    try {
      this.scenarios = await getAIJuniorScenarios()
    } catch (err) {
      console.error('Failed to load AI Junior scenarios:', err)
    } finally {
      this.loading = false
    }
  },
  methods: {
    worksheetUrl (scenario) {
      return `/ai-junior/project/${scenario.slug || scenario._id}`
    },
    scanUrl (scenario) {
      return `/ai-junior/scan/${scenario.slug || scenario._id}`
    },
    gradeRange (scenario) {
      const levels = scenario.gradeLevels
      if (!levels || (!levels.start && !levels.end)) return null
      if (levels.start === levels.end) return levels.start
      return `${levels.start}–${levels.end}`
    },
    subjectLabel (subject) {
      return SUBJECT_LABELS[subject] || subject
    },
  },
}
</script>

<style lang="scss" scoped>
.ai-junior-landing {
  max-width: 1100px;
  margin: 0 auto;
}

.hero {
  text-align: center;
  margin-bottom: 2.5rem;

  h1 {
    font-size: 3.2rem;
    margin-bottom: 0.5rem;
  }

  .tagline {
    font-size: 1.8rem;
    color: #555;
    max-width: 600px;
    margin: 0 auto;
  }
}

.toolbar {
  display: flex;
  gap: 1rem;
  align-items: center;
  margin-bottom: 2rem;

  .search-input {
    flex: 1;
    max-width: 320px;
    padding: 0.6rem 1rem;
    border: 1px solid #ccc;
    border-radius: 8px;
    font-size: 1.5rem;
  }

  .subject-select {
    padding: 0.6rem 1rem;
    border: 1px solid #ccc;
    border-radius: 8px;
    font-size: 1.5rem;
  }

  .admin-new {
    margin-left: auto;
  }
}

.loading,
.empty {
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

.scenario-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 2rem;
}

.scenario-card {
  border: 1px solid #e0e0e0;
  border-radius: 12px;
  overflow: hidden;
  background: #fff;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.06);
  display: flex;
  flex-direction: column;
  transition: box-shadow 0.15s ease, transform 0.15s ease;

  &:hover {
    box-shadow: 0 6px 16px rgba(0, 0, 0, 0.12);
    transform: translateY(-2px);
  }
}

.card-cover {
  display: block;
  aspect-ratio: 16 / 10;
  background: #f5f2ec;

  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .cover-placeholder {
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 4rem;
  }
}

.card-body {
  padding: 1.4rem;
  display: flex;
  flex-direction: column;
  flex: 1;

  h3 {
    margin: 0 0 0.6rem;
    font-size: 1.9rem;

    a {
      color: #222;
      text-decoration: none;
    }
  }

  .phase-badge {
    display: inline-block;
    margin-left: 0.6rem;
    padding: 0.1rem 0.7rem;
    font-size: 1.1rem;
    text-transform: uppercase;
    background: #fff3cd;
    color: #856404;
    border-radius: 10px;
    vertical-align: middle;
  }

  .description {
    color: #555;
    font-size: 1.4rem;
    flex: 1;
  }
}

.card-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  align-items: center;
  margin: 0.8rem 0;

  .grades {
    font-size: 1.2rem;
    color: #333;
    background: #e8f4fd;
    padding: 0.2rem 0.8rem;
    border-radius: 10px;
  }

  .subject-chip {
    font-size: 1.2rem;
    color: #2c662d;
    background: #e6f4e6;
    padding: 0.2rem 0.8rem;
    border-radius: 10px;
  }
}

.card-actions {
  display: flex;
  gap: 0.8rem;
}
</style>
