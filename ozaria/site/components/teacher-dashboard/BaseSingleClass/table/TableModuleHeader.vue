<script>
/**
 * Creates the module heading for the all students table.
 */

  import ContentIcon from '../../common/icons/ContentIcon'
  import ProgressDot from '../../common/progress/progressDot'
  import LockButton from '../../common/buttons/LockButton'

  import { mapGetters, mapMutations } from 'vuex'

  export default {
    components: {
      ContentIcon,
      ProgressDot,
      LockButton
    },
    props: {
      moduleHeading: {
        type: String,
        required: true
      },

      listOfContent: {
        type: Array,
        required: true
      },

      classSummaryProgress: {
        type: Array,
        required: true
      },

      displayOnly: {
        type: Boolean,
        default: false
      }
    },

    computed: {
      ...mapGetters({
        showingTooltipOfThisOriginal: 'baseSingleClass/getShowingTooltipOfThisOriginal'
      }),

      cssVariables () {
        return {
          '--cols': this.listOfContent.length
        }
      },

      lockIconUrl () {
        if (this.displayOnly) {
          return '/images/ozaria/teachers/dashboard/svg_icons/IconLock_Gray.svg'
        } else {
          return '/images/ozaria/teachers/dashboard/svg_icons/IconLock.svg'
        }
      }
    },

    methods: {
      ...mapMutations({
        setShowingTooltipOfThisOriginal: 'baseSingleClass/setShowingTooltipOfThisOriginal'
      }),

      lockModule () {
        this.$emit('lock')
      },

      unlockModule () {
        this.$emit('unlock')
      },

      classContentTooltip (type) {
        return {
          'intro-tooltip': type === 'cinematic' || type === 'interactive'
        }
      },

      classForContentIconHover (normalizedOriginal) {
        return {
          'hover-trigger-area': true,
          hoverState: this.showingTooltipOfThisOriginal === normalizedOriginal
        }
      }
    }
  }
</script>

<template>
  <div
    class="moduleHeading"
    :style="cssVariables"
  >
    <div class="title">
      <h3>{{ moduleHeading }}</h3>
      <v-popover
        v-if="!displayOnly"
        placement="top"
        trigger="hover"
        popover-class="teacher-dashboard-tooltip lighter-p lock-tooltip"
      >
        <!-- Triggers the tooltip -->
        <img :src="lockIconUrl">

        <!-- The tooltip -->
        <template slot="popover">
          <div class="module-popover-locking">
            <lock-button @click="lockModule">{{ $t('teacher_dashboard.lock') }}</lock-button>
            <lock-button @click="unlockModule">{{ $t('teacher_dashboard.unlock') }}</lock-button>
          </div>
        </template>
      </v-popover>
      <img
        v-else
        :src="lockIconUrl"
      >
    </div>
    <div
      v-for="({ type, tooltipName, description, submitLock, removeLock, normalizedOriginal }, idx) of listOfContent"
      :key="`${idx}-${type}`"

      class="content-icons"
    >
      <v-popover
        popover-class="teacher-dashboard-tooltip lighter-p lock-tooltip"
        trigger="hover"
        placement="top"

        @show="setShowingTooltipOfThisOriginal(normalizedOriginal)"
        @hide="setShowingTooltipOfThisOriginal(undefined)"
      >
        <!-- Triggers the tooltip -->
        <div
          :class="classForContentIconHover(normalizedOriginal)"
        >
          <ContentIcon
            class="content-icon"
            :icon="type"
          />
        </div>
        <!-- The tooltip -->
        <template slot="popover">
          <div class="level-popover-locking">
            <h3
              v-if="type !== 'cutscene'"
              style="margin-bottom: 15px;"
              :class="classContentTooltip(type)"
            >
              {{ tooltipName }}
            </h3>
            <p
              style="margin-bottom: 15px;"
              v-html="description"
            />
            <div
              v-if="!displayOnly"
              class="lock-btn-row"
            >
              <lock-button @click="submitLock">
                {{ $t('teacher_dashboard.lock') }}
              </lock-button>
              <lock-button @click="removeLock">
                {{ $t('teacher_dashboard.unlock') }}
              </lock-button>
            </div>
          </div>
        </template>
      </v-popover>
    </div>
    <div class="golden-backer" v-for="({ status, border }, idx) of classSummaryProgress" :key="idx">
      <ProgressDot :status="status" :border="border" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.moduleHeading {
  display: grid;
  grid-template-columns: repeat(var(--cols), 28px);
  grid-template-rows: repeat(3, 38px);
  align-items: center;
  justify-items: center;

  background-color: #ddd;
  border: 1px solid white;
}

.title {
  /* Makes title span entire grid row */
  grid-column: 1 / -1;
  justify-self: normal;

  height: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;

  background-color: #413c55;
  border-bottom: 1px solid white;

  padding: 0 0 0 12px;

  h3 {
    overflow: hidden;
    text-overflow: ellipsis;
  }
}

.golden-backer {
  background-color: #fff9e3;
  border-top: 0.5px solid #d4b235;
  border-bottom: 0.5px solid #d4b235;

  /* TODO: This isn't working. Why? */
  &:first-child {
    border-left: 0.5px solid #d4b235;
  }

  &:last-child {
    border-right: 0.5px solid #d4b235;
  }

  width: 100%;
  height: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
}

.content-icons {
  height: 100%;
  width: 100%;

  display: flex;
  align-items: center;
  justify-content: center;

  background-color: #d8d8d8;
  border-top: 1px solid white;
  border-bottom: 1px solid white;
}

.content-icon {
  max-width: 20px;
}

h3 {
  @include font-p-4-paragraph-smallest-gray;
  color: white;
  font-weight: 600;
}

.module-popover-locking {
  display: flex;
  flex-direction: column;
  width: 100px;
}

.level-popover-locking {
  padding: 16px 16px 0;
}

.lock-btn-row {
  display: flex;
  flex-direction: row;

  margin: 22px -16px 0;

  &::v-deep button {
    width: 100%;
  }
}

.hover-trigger-area {
  padding: 4px;
  border-radius: 4px;

  &.hoverState {
    background-color: #ADADAD;
  }
}

.tooltip.teacher-dashboard-tooltip .tooltip-inner h3.intro-tooltip {
  margin: -17px -17px 0;
  padding: 10px 15px;
  background-color: #413C55;
  border-radius: 5px 5px 0 0;
  color: white;
  font-size: 18px;

  /* Selects element directly after this h3 to fix spacing */
  & + * {
    margin-top: -5px;
  }
}

</style>
