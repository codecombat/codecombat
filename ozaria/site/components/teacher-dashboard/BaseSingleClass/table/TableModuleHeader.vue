<script>
/**
 * Creates the module heading for the all students table.
 */

import ContentIcon from '../../common/icons/ContentIcon'
import ProgressDot from '../../common/progress/progressDot'
import LockOrSkip from './LockOrSkip'
import { getGameContentDisplayType } from 'ozaria/site/common/ozariaUtils.js'
import { courseArenaLadder } from 'core/urls'
import { getLevelUrl } from 'ozaria/site/components/teacher-dashboard/BaseCurriculumGuide/curriculum-guide-helper'
import CourseSchema from 'app/schemas/models/course.schema'
import CodeRenderer from 'app/components/common/labels/CodeRenderer'
import AccessLevelIndicator from 'app/components/common/elements/AccessLevelIndicator'
import DynamicLink from 'app/components/common/elements/DynamicLink.vue'

import utils from 'core/utils'

import { mapGetters, mapMutations, mapActions } from 'vuex'

// The levels in the groups defined here are can not be selected individually.
// They are either all selected or all not selected.
const selectableGroups = [
  [
    // Chapter 1
    '5efc08940bda4700242d6e3c', // Intro: Trapping Darkness
    '5efc09910bda4700242d6e47', // Intro: Builder Things
    '5efc10a40bda4700242d6e9b', // Intro: Finishing Touches
    '5eddd6a76f7d690028cf4c50', // Capstone Level: Gauntlet
    '5f0cd339e494e50029521c5e', // Cutscene: Trapping the Dark
  ],
  [
    // Chapter 4
    '60073a27f849d20027ae6c5e', // Intro: Stage 1
    '5fdc91598a71e9002485b1f0', // Capstone Level: Curiosity Sandbox
    '60073a6b23a19d0022f0da62', // Intro: Stage 2
  ],
]

const getSelectableGroup = (original) => {
  if (!original) {
    return []
  }
  for (const group of selectableGroups) {
    if (group.includes(original)) {
      return group
    }
  }
  return [original]
}

export default {
  components: {
    ContentIcon,
    ProgressDot,
    LockOrSkip,
    CodeRenderer,
    AccessLevelIndicator,
    DynamicLink,
  },
  props: {
    moduleHeading: {
      type: String,
      required: true,
    },

    moduleHeadingImage: {
      type: String,
      default: null,
    },

    listOfContent: {
      type: Array,
      required: true,
    },

    classSummaryProgress: {
      type: Array,
      required: true,
    },

    displayOnly: {
      type: Boolean,
      default: false,
    },

    access: {
      type: String,
      validator: value => {
        return CourseSchema.properties.modules.additionalProperties.properties.access.enum.includes(value)
      },
      default: undefined,
    },
    moduleNumber: {
      type: [String, Number],
      default: null,
    },
    collapsible: {
      type: Boolean,
      default: false,
    },
  },

  data () {
    return {
      lockOrSkipShown: false,
      hoveredOriginals: [],
      userSelectedOriginals: [],
    }
  },

  computed: {
    ...mapGetters({
      showingTooltipOfThisOriginal: 'baseSingleClass/getShowingTooltipOfThisOriginal',
      selectedOriginals: 'baseSingleClass/selectedOriginals',
      selectedCourseId: 'teacherDashboard/getSelectedCourseIdCurrentClassroom',
      getCourseInstancesOfClass: 'courseInstances/getCourseInstancesOfClass',
      classroom: 'teacherDashboard/getCurrentClassroom',
      isContentAccessible: 'me/isContentAccessible',
      collapsedModules: 'teacherDashboard/getCollapsedModulesForCurrentCourse',
    }),

    collapsed () {
      return this.collapsedModules.includes(this.moduleNumber)
    },

    isCodeCombat () {
      return utils.isCodeCombat
    },

    listOfOriginals () {
      return [...new Set(Object.values(this.listOfContent).map(item => item.normalizedOriginal))] // array of unique original ids
    },

    cssVariables () {
      return {
        '--cols': this.listOfContent.length,
        '--columnWidth': this.listOfContent.length > 2 ? '28px' : (this.listOfContent.length > 1 ? '42px' : '84px'),
      }
    },

    lockIconUrl () {
      if (this.displayOnly) {
        return '/images/ozaria/teachers/dashboard/svg_icons/IconLock_Gray.svg'
      } else {
        return '/images/ozaria/teachers/dashboard/svg_icons/IconLock.svg'
      }
    },
  },

  mounted () {
    this.fetchModuleCollapseState(this.moduleNumber)
  },

  methods: {
    ...mapMutations({
      setShowingTooltipOfThisOriginal: 'baseSingleClass/setShowingTooltipOfThisOriginal',
      replaceSelectedOriginals: 'baseSingleClass/replaceSelectedOriginals',
      updateSelectedOriginals: 'baseSingleClass/updateSelectedOriginals',
    }),
    ...mapActions({
      toggleModuleCollapse: 'teacherDashboard/toggleModuleCollapse',
      fetchModuleCollapseState: 'teacherDashboard/fetchModuleCollapseState',
    }),

    getLevelUrl (object) {
      return getLevelUrl(object)
    },

    arenaLadderUrl (slug) {
      const courseInstances = this.getCourseInstancesOfClass(this.classroom._id) || []
      const courseInstance = courseInstances.find(({ courseID }) => courseID === this.selectedCourseId)
      return courseArenaLadder({ level: { slug }, courseInstance })
    },

    getGameContentDisplayType (type) {
      return getGameContentDisplayType(type, true, true)
    },

    toggleDatepicker () {
      this.showDatepicker = !this.showDatepicker
    },

    setHoveredOriginal (original) {
      this.hoveredOriginals = getSelectableGroup(original)
      this.$emit('updateHoveredLevels', getSelectableGroup(original))
    },

    updateList (event, original) {
      const group = getSelectableGroup(original)
      for (const item of group) {
        this.updateSelectedOriginals({ shiftKey: event.shiftKey, original: item, listOfOriginals: this.listOfOriginals })
      }
    },

    classContentTooltip (type) {
      return {
        'intro-tooltip': type === 'cinematic' || type === 'interactive',
      }
    },

    classForContentIconHover (normalizedOriginal) {
      return {
        'hover-trigger-area': true,
        hoverState: this.hoveredOriginals.includes(normalizedOriginal),
        'is-selected': this.selectedOriginals.includes(normalizedOriginal),
      }
    },

    selectAll () {
      this.userSelectedOriginals = [...this.selectedOriginals]
      this.replaceSelectedOriginals(this.listOfOriginals)
    },
    deselectAll () {
      this.replaceSelectedOriginals(this.userSelectedOriginals)
    },

    renderedModuleHeading () {
      return this.$refs.renderedModuleHeading && this.$refs.renderedModuleHeading.content
    },
  },
}
</script>

<template>
  <div
    class="moduleHeading"
    :class="{ 'collapsed': collapsed }"
    :style="cssVariables"
  >
    <div class="title">
      <div
        v-if="collapsible"
        v-tooltip="{
          content: collapsed ? renderedModuleHeading() : $t('teacher_dashboard.collapse'),
          classes: 'layoutChromeTooltip',
        }"
        class="collapse-toggle"
        @click="toggleModuleCollapse(moduleNumber)"
      >
        <i class="icon-chevron-right  icon-white" />
        <i class="icon-chevron-left  icon-white" />
      </div>

      <img
        v-if="moduleHeadingImage"
        v-tooltip="{
          content: moduleHeading.replace(/`(.*?)`/g, '<code>$1</code>'),
          placement: 'bottom',
          classes: 'layoutChromeTooltip',
        }"
        class="module-logo"
        :src="moduleHeadingImage"
      >
      <h3 v-else>
        <code-renderer
          ref="renderedModuleHeading"
          :content="moduleHeading"
        />
        <access-level-indicator
          :level="access"
          :display-text="false"
        />
      </h3>
      <!-- eslint-enable vue/no-v-html -->
      <v-popover
        v-if="!displayOnly"
        placement="top"
        popover-class="teacher-dashboard-tooltip lighter-p lock-tooltip"
        trigger="click"
        @show="lockOrSkipShown = true"
        @hide="lockOrSkipShown = false"
      >
        <!-- Triggers the tooltip -->
        <div v-if="!displayOnly">
          <span class="btn btn-sm btn-default lock-button"><img :src="lockIconUrl"></span>
        </div>
        <!-- The tooltip -->
        <template slot="popover">
          <lock-or-skip
            :all-originals="listOfOriginals"
            :shown="lockOrSkipShown"
          />
        </template>
      </v-popover>
    </div>
    <div
      v-for="({ type, slug, introContent, ozariaType, introLevelSlug, isPractice, practiceLevels, tooltipName, description, normalizedOriginal, normalizedType, contentLevelSlug }, idx) of listOfContent"
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
          @click="updateList($event, normalizedOriginal)"
          @mouseenter="setHoveredOriginal(normalizedOriginal)"
          @mouseleave="setHoveredOriginal(null)"
        >
          <ContentIcon
            class="content-icon"
            :icon="isCodeCombat ? normalizedType : type"
          />
        </div>
        <!-- The tooltip -->
        <template slot="popover">
          <div class="level-popover-locking">
            <span v-if="isCodeCombat">{{ getGameContentDisplayType(normalizedType) }}</span>
            <span v-if="!isCodeCombat && isPractice">{{ $t('play_level.level_type_practice') }}</span>
            <h3
              v-if="type !== 'cutscene'"
              style="margin-bottom: 15px;"
              :class="classContentTooltip(type)"
            >
              <dynamic-link
                target="_blank"
                :href="isContentAccessible(access) ? getLevelUrl({ ozariaType, introLevelSlug, courseId: selectedCourseId, codeLanguage: classroom.aceConfig.language, slug, introContent }) : null"
              >
                {{ tooltipName }}
              </dynamic-link>
            </h3>
            <p
              style="margin-bottom: 15px;"
              v-html="description"
            />
            <p v-if="practiceLevels?.length">
              {{ $t('teacher_dashboard.practice_levels') }}: {{ practiceLevels.length }}
            </p>
            <a
              v-if="type === 'course-ladder'"
              :href="arenaLadderUrl(contentLevelSlug)"
              target="_blank"
              class="arena-ladder-link"
            >
              {{ $t('teacher.view_arena_ladder') }}
            </a>
          </div>
        </template>
      </v-popover>
    </div>
    <div
      v-for="({ status, border }, idx) of classSummaryProgress"
      :key="idx"
      class="golden-backer"
    >
      <ProgressDot
        :status="status"
        :border="border"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.moduleHeading {
  display: grid;
  grid-template-columns: repeat(var(--cols), var(--columnWidth));
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
  position: relative;

  background-color: #413c55;
  border-bottom: 1px solid white;

  padding: 0 0 0 5px;

  overflow: hidden;
  text-overflow: ellipsis;

  img.module-logo {
    height: calc(100% - 4px);
    width: auto;
    background: white;
    border-radius: 8px;
    margin: 2px 0;
  }

  .v-popover {
    display: none;
    position: absolute;
    right: 2px;
    top: 2px;
  }

  &:hover .v-popover {
    display: block;

  }

  h3 {
    max-height: 2em;
    overflow-y: visible;
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

  .level-checkbox {
    display: none;
    position: absolute;
  }

  &:hover .level-checkbox {
    display: block;
  }
}

.content-icon {
  max-width: 20px;
}

h3 {
  @include font-p-4-paragraph-smallest-gray;
  color: white;
  font-weight: 600;
  flex: 1;
  padding-left: 5px;
}

.module-popover-locking {
  display: flex;
  flex-direction: column;
  width: 100px;
}

.level-popover-locking {
  padding: 16px 16px 0;

  ::v-deep {
    a {
      color: inherit;
      text-decoration: underline;
    }
  }
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
  margin-right: 1px;

  &.hoverState {
    background-color: #ADADAD;
  }

  &.is-selected {
    background: #5DB9AC;
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
  &+* {
    margin-top: -5px;
  }
}

.popover .btn {
  width: auto;
}

.lock-button {
  padding: 2px 2px;
}

.arena-ladder-link {
  display: block;
  margin-bottom: 15px;
}

.collapsed {
  >*:not(.title) {
    display: none;
  }

  >.title {
    padding-left: 1px;
    >*:not(.collapse-toggle) {
    display: none
  }
  }

  width: 20px;
  min-width: 20px;
  overflow: hidden;
}

.collapse-toggle {
  cursor: pointer;
  display: inline-flex;
  justify-content: center;
  align-items: center;
  background: #413c55;
  border: 1px solid white;
  border-radius: 5px;
  i {
    padding: 0;
    margin: 0;
  }
}

.moduleHeading {
  &:not(.collapsed) {
    .collapse-toggle .icon-chevron-right {
      display: none;
    }
  }
  &.collapsed .collapse-toggle .icon-chevron-left {
    display: none;
  }
}
</style>
