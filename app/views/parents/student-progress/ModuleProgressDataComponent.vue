<template>
  <div class="lprogress">
    <div class="lprogress__intro">
      <div class="lprogress__intro__title">
        Levels progress
      </div>
      <div class="lprogress__intro__options">
        <div class="lprogress__intro__option">
          <div class="lprogress__intro__dot not-started-dot"></div>
          <div class="lprogress__intro__text">Not Started</div>
        </div>
        <div class="lprogress__intro__option">
          <div class="lprogress__intro__dot in-progress-dot"></div>
          <div class="lprogress__intro__text">In progress</div>
        </div>
        <div class="lprogress__intro__option">
          <div class="lprogress__intro__dot complete-dot"></div>
          <div class="lprogress__intro__text">Complete</div>
        </div>
      </div>
    </div>
    <div class="lprogress__content">
      <div
        v-for="(level, index) in levels"
        class="lprogress__level"
        :key="level.original"
      >
        <module-row
          :display-name="level.name"
          :icon-type="getIconType(level)"
          :description="level.description"
          :show-code="index % 2 === 0"
          :show-progress-dot="true"
          :progress-status="getProgressStatus(level)"
        />
      </div>
    </div>
  </div>
</template>

<script>
import ModuleRow from '../../../../ozaria/site/components/teacher-dashboard/BaseCurriculumGuide/components/ModuleRow'
export default {
  name: 'ModuleProgressDataComponent',
  props: {
    levels: {
      type: Array,
      required: true
    },
    levelSessions: {
      type: Array
    }
  },
  components: {
    ModuleRow
  },
  methods: {
    getIconType (level) {
      if (level.kind === 'practice') return 'practicelvl'
      return (['hero', 'hero-ladder', 'game-dev'].includes(level.type) ? 'challengelvl' : (level.type || 'challengelvl'))
    },
    getProgressStatus (level) {
      let status = 'not-started'
      if (!this.levelSessions) return status
      const ls = this.levelSessions.filter(ls => ls.levelID === level.slug)
      if (ls.length) status = 'in-progress'
      ls.forEach(session => {
        if (session.state.complete) status = 'complete'
      })
      return status
    }
  },
  computed: {

  },
  created () {
    console.log('modProg', this.levels)
  }
}
</script>

<style scoped lang="scss">
.lprogress {
  padding: 2rem;
  &__intro {
    display: flex;
    align-items: center;

    &__title {
      font-weight: 500;
      font-size: 1.6rem;
      line-height: 2rem;
      text-transform: uppercase;

      margin-right: auto;
    }

    &__text {
      font-weight: 400;
      font-size: 1rem;
      line-height: 1.1rem;
    }

    &__options {
      display: flex;
    }

    &__option {
      display: flex;
      flex-direction: column;
      align-items: center;

      padding: 1rem;
    }

    &__dot {
      width: 1rem;
      height: 1rem;
      background: #FFFFFF;
      border-radius: 1rem;
      margin-bottom: .5rem;
    }
  }

  &__level {
    &:nth-child(odd) {
      background-color: #f2f2f2;
    }
  }
}

.not-started-dot {
  border: 1.5px solid #C8CDCC;
}

.in-progress-dot {
  background-color: #1ad0ff;
}

.complete-dot {
  background-color: #2dcd38;
}
</style>
