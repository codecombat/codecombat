<script>
import ClassSummaryRow from './components/ClassSummaryRow'
import ClassChapterSummaries from './components/ClassChapterSummaries'
import { mapActions, mapGetters } from 'vuex'
import utils from 'core/utils'

export default {
  components: {
    ClassSummaryRow,
    ClassChapterSummaries,
  },
  props: {
    classroomStats: {
      type: Object,
      required: true
    },
    chapterStats: {
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
      tournamentsByClan: 'clans/tournamentsByClan',
      tournaments: 'clans/tournaments',
      allTournamentsLoaded: 'clans/allTournamentsLoaded'
    }),

    showEsportsCampInfoCoCo () {
      return utils.isCodeCombat && me.isCodeNinja() && !this.chapterStats.length
    },

    me () {
      return me
    },

    showEsportsCampInfoOz () {
      return utils.isOzaria && me.isCodeNinja() && this.chapterStats.length === 2
    },

    showJuniorCampInfo () {
      return utils.isCodeCombat && me.isCodeNinja() && this.chapterStats.length === 1
    },

    currentTournaments () {
      return _.flatten(Object.values(this.tournaments))
    },

    equinoxTournament () {
      const eq = this.currentTournaments.filter(tournament => tournament.slug === 'equinox')
      if (eq.length === 0) {
        return {}
      } else if (eq.length === 1) {
        return eq[0]
      } else {
        eq.sort((a, b) => new Date(a.endDate) - new Date(b.endDate))
        // find the first tournament that has not ended
        return eq.find(tournament => new Date(tournament.endDate) >= new Date()) || eq[eq.length - 1]
      }
    },

    ttTournament () {
      const tt = this.currentTournaments.filter(tournament => tournament.slug === 'tundra-tower')
      if (tt.length === 0) {
        return {}
      } else if (tt.length === 1) {
        return tt[0]
      } else {
        tt.sort((a, b) => new Date(a.endDate) - new Date(b.endDate))
        // find the first tournament that has not ended
        return tt.find(tournament => new Date(tournament.endDate) >= new Date()) || tt[tt.length - 1]
      }
    }
  },
  mounted () {
    if (me.isCodeNinja() && !this.allTournamentsLoaded) {
      this.fetchAllTournaments({ userId: me.get('_id') })
    }
  },
  methods: {
    ...mapActions({
      fetchAllTournaments: 'clans/fetchAllTournaments'
    }),
  }
}
</script>

<template>
  <div class="class-component">
    <class-summary-row
      :class-id="classroomStats.id"
      :classroom-name="classroomStats.name"
      :language="classroomStats.language"
      :num-students="classroomStats.numberOfStudents"
      :date-created="classroomStats.classroomCreated"
      :date-start="classroomStats.classDateStart"
      :date-end="classroomStats.classDateEnd"
      :code-camel="classroomStats.codeCamel"
      :archived="classroomStats.archived"
      :display-only="displayOnly"
      :share-permission="classroomStats.sharePermission"
      :class-type="classroomStats.type"
      @clickTeacherArchiveModalButton="$emit('clickTeacherArchiveModalButton')"
      @clickAddStudentsModalButton="$emit('clickAddStudentsModalButton')"
      @clickShareClassWithTeacherModalButton="$emit('clickShareClassWithTeacherModalButton')"
    />
    <!--
      can be enabled for shared once in addition to fetchCourseInstancesForTeacher, we do it for all shared class whose owner is not this logged in teacher
    -->
    <class-chapter-summaries
      v-if="!classroomStats.sharePermission"
      :chapter-progress="chapterStats"
    />
    <div v-if="showEsportsCampInfoCoCo || showEsportsCampInfoOz">
      <b>Esports Camp Quick Links</b>
      <ul class="list-inline">
        <li>
          <a
            v-tooltip.top="{
              content: 'Comprehensive Sensei guide to running the Competitive Coding: Esports and Game Design camp with Ozaria and the CodeCombat AI League. (Sensei guide coming soon.)',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://drive.google.com/file/d/1Zdh9-jh1UP81nasfan3H98mcYrRwvszn/view?usp=drive_link"
            class="dusk-btn disabled"
            target="_blank"
            disabled
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>Sensei Guide</span>
          </a>
        </li>
        <li>
          <a
            v-tooltip.top="{
              content: 'Day-by-day slides and Sensei resources for the Esports + Game Design camp.',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://drive.google.com/drive/folders/1Ut8R4xeTxJdlb7_Uy4_vWyWc-kT_-3RE?usp=drive_link"
            class="dusk-btn"
            target="_blank"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>Camp Curriculum</span>
          </a>
        </li>
        <li v-if="showEsportsCampInfoCoCo">
          <a
            v-tooltip.top="{
              content: 'Switch to the Ozaria sensei dashboard to see student progress through Chapters 1 & 2 (days 1-2).',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://www.ozaria.com/teachers/classes/"
            class="dusk-btn"
          >
            <div class="quick-link-icon icon-dashboard" />
            <span>Ozaria Dashboard</span>
          </a>
        </li>
        <li v-if="me.isCodeNinja() && equinoxTournament.clan">
          <!-- TODO: specific tournament link -->
          <a
            v-tooltip.top="{
              content: 'View tournament leaderboards or play the Equinox arena (days 3-4).',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            :href="`https://codecombat.com/play/ladder/equinox/clan/${equinoxTournament.clan}?tournament=${equinoxTournament._id}`"
            class="dusk-btn"
          >
            <div class="quick-link-icon icon-arena" />
            <span>Equinox Arena</span>
          </a>
        </li>
        <li v-if="me.isCodeNinja() && ttTournament.clan">
          <!-- TODO: specific tournament link -->
          <a
            v-tooltip.top="{
              content: 'View tournament leaderboards or play the final tournament arena (day 5).',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            :href="`https://codecombat.com/play/ladder/tundra-tower/clan/${ttTournament.clan}?tournament=${ttTournament._id}`"
            class="dusk-btn"
          >
            <div class="quick-link-icon icon-arena" />
            <span>Tournament Arena</span>
          </a>
        </li>
      </ul>
      <b>Lessons</b>
      <ul class="list-inline">
        <li>
          <a
            v-tooltip.top="{
              content: 'Lesson slides for Day 1: Algorithms & Problem Solving (Ozaria Chapter 1, Module 1, Lessons 1-3).',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://docs.google.com/presentation/d/1s551TjfXHcKZ9VxAcJDppEVSee7jQffQiCBPlQSjafs/edit#slide=id.g26c495a3c7b_0_735"
            class="dusk-btn"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>Day 1</span>
          </a>
        </li>
        <li>
          <a
            v-tooltip.top="{
              content: 'Lesson slides for Day 2: Capstone Competition (Ozaria Chapter 1 Capstone).',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://docs.google.com/presentation/d/1s551TjfXHcKZ9VxAcJDppEVSee7jQffQiCBPlQSjafs/edit#slide=id.g26c495a3c7b_0_1070"
            class="dusk-btn"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>Day 2</span>
          </a>
        </li>
        <li>
          <a
            v-tooltip.top="{
              content: 'Lesson slides for Day 3: Intro to AI League (Equinox arena, introduction).',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://docs.google.com/presentation/d/1s551TjfXHcKZ9VxAcJDppEVSee7jQffQiCBPlQSjafs/edit#slide=id.g26c5c0ddf08_0_233"
            class="dusk-btn"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>Day 3</span>
          </a>
        </li>
        <li>
          <a
            v-tooltip.top="{
              content: 'Lesson slides for Day 4: Esports Practice (Equinox arena, more strategies).',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://docs.google.com/presentation/d/1s551TjfXHcKZ9VxAcJDppEVSee7jQffQiCBPlQSjafs/edit#slide=id.g26c5c0ddf08_0_346"
            class="dusk-btn"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>Day 4</span>
          </a>
        </li>
        <li>
          <a
            v-tooltip.top="{
              content: 'Lesson slidse for Day 5: AI League Tournament.',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://docs.google.com/presentation/d/1s551TjfXHcKZ9VxAcJDppEVSee7jQffQiCBPlQSjafs/edit#slide=id.g26c5c0ddf08_0_459"
            class="dusk-btn"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>Day 5</span>
          </a>
        </li>
      </ul>
    </div>
    <div v-if="showJuniorCampInfo">
      <b>Roblox Camp Quick Links</b>
      <ul class="list-inline">
        <li>
          <a
            v-tooltip.top="{
              content: 'Comprehensive Sensei guide to running the Roblox: Intro to Coding and Game Design camp with CodeCombat Junior and CodeCombat Worlds.',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://drive.google.com/file/d/1QEnftP3frLXV_nQC39jJNYs4mT_Dwr9r/view?usp=drive_link"
            class="dusk-btn disabled"
            disabled
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>Sensei Guide</span>
          </a>
        </li>
        <li>
          <a
            v-tooltip.top="{
              content: 'Day-by-day slides and Sensei resources for the Roblox: Intro to Coding and Game Design camp.',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://drive.google.com/drive/folders/1EDDk0Scl1v2y2FYMprFw06YznlV0guML?usp=drive_link"
            target="_blank"
            class="dusk-btn"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>Camp Curriculum</span>
          </a>
        </li>
        <li>
          <!-- TODO: class-specific Roblox private server link -->
          <a
            v-tooltip.top="{
              content: 'Join the private server for your class to play CodeCombat Worlds on Roblox. (Private server link functionality coming soon.)',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://www.roblox.com/games/11704713454"
            class="dusk-btn"
          >
            <div class="quick-link-icon icon-external-link" />
            <span>Join Roblox Server</span>
          </a>
        </li>
      </ul>
      <b>Lessons</b>
      <ul class="list-inline">
        <li>
          <a
            v-tooltip.top="{
              content: 'Lesson slides for Day 1: Sequences & Arguments.',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://docs.google.com/presentation/d/1Z5LxiBPtMUCTxBqDdRafPnZ8j6OHo1V5Tc05wxTadvI/edit#slide=id.g2c5478d5359_1_197"
            class="dusk-btn"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>Day 1</span>
          </a>
        </li>
        <li>
          <a
            v-tooltip.top="{
              content: 'Lesson slides for Day 2: Rift Village Quests.',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://docs.google.com/presentation/d/1Z5LxiBPtMUCTxBqDdRafPnZ8j6OHo1V5Tc05wxTadvI/edit#slide=id.g26c4a941b7b_0_4"
            class="dusk-btn"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>Day 2</span>
          </a>
        </li>
        <li>
          <a
            v-tooltip.top="{
              content: 'Lesson slides for Day 3: Design Thinking Part 1.',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://docs.google.com/presentation/d/1Z5LxiBPtMUCTxBqDdRafPnZ8j6OHo1V5Tc05wxTadvI/edit#slide=id.g26ce47520c2_0_503"
            class="dusk-btn"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>Day 3</span>
          </a>
        </li>
        <li>
          <a
            v-tooltip.top="{
              content: 'Lesson slides for Day 4: Design Thinking Part 2.',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://docs.google.com/presentation/d/1Z5LxiBPtMUCTxBqDdRafPnZ8j6OHo1V5Tc05wxTadvI/edit#slide=id.g2c544e9b6d0_0_0"
            class="dusk-btn"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>Day 4</span>
          </a>
        </li>
        <li>
          <a
            v-tooltip.top="{
              content: 'Lesson slides for Day 5: Showcase Project.',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://docs.google.com/presentation/d/1Z5LxiBPtMUCTxBqDdRafPnZ8j6OHo1V5Tc05wxTadvI/edit#slide=id.g2c544e9b6d0_0_61"
            class="dusk-btn"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>Day 5</span>
          </a>
        </li>
      </ul>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";
@import "ozaria/site/components/teacher-dashboard/common/_dusk-button";

.quick-link-icon {
  height: 20px;
  width: 20px;
  display: inline-block;
  background-repeat: no-repeat;
  background-position: center;
  background-size: 100% 100%;
  margin-right: 5px;
}

.quick-link-icon.icon-curriculum {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconCurriculumGuide.svg);
}

.quick-link-icon.icon-dashboard {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_Progress_Black.svg);
}

.quick-link-icon.icon-external-link {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconExemplarProject.svg);
}

.quick-link-icon.icon-arena {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_Capstone_Black.svg);
}
</style>
