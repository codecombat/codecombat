<template>
  <div class="class-links">
    <div v-if="showEsportsCampInfoCoco || showEsportsCampInfoOz">
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
        <li v-if="showEsportsCampInfoCoco">
          <a
            v-tooltip.top="{
              content: 'Switch to the Ozaria sensei dashboard to see student progress through Chapters 1 & 2 (days 1-2).',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://www.ozaria.com/teachers/classes/"
            class="dusk-btn"
            target="_blank"
          >
            <div class="quick-link-icon icon-dashboard" />
            <span>Ozaria Dashboard</span>
          </a>
        </li>
        <li v-if="equinoxTournament.clan">
          <!-- TODO: specific tournament link -->
          <a
            v-tooltip.top="{
              content: 'View tournament leaderboards or play the Equinox arena (days 3-4).',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            :href="`https://codecombat.com/play/ladder/equinox/clan/${equinoxTournament.clan}?tournament=${equinoxTournament._id}`"
            class="dusk-btn"
            target="_blank"
          >
            <div class="quick-link-icon icon-arena" />
            <span>Equinox Arena</span>
          </a>
        </li>
        <li v-if="ttTournament.clan">
          <!-- TODO: specific tournament link -->
          <a
            v-tooltip.top="{
              content: 'View tournament leaderboards or play the final tournament arena (day 5).',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            :href="`https://codecombat.com/play/ladder/tundra-tower/clan/${ttTournament.clan}?tournament=${ttTournament._id}`"
            class="dusk-btn"
            target="_blank"
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
            target="_blank"
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
            target="_blank"
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
            href="https://drive.google.com/drive/folders/1eCzl7gi-PkuAQHLLVQhy2nhKDugm004W?usp=drive_link"
            class="dusk-btn"
            target="_blank"
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
            href="https://drive.google.com/drive/folders/1j70Iqtle-ZoTYLK6RVaY9Fb7f_c0EjMm?usp=sharing"
            class="dusk-btn"
            target="_blank"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>Day 4</span>
          </a>
        </li>
        <li>
          <a
            v-tooltip.top="{
              content: 'Lesson slides for Day 5: AI League Tournament.',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://drive.google.com/drive/folders/14BUC0BjPREeuvsI8a_bHgpUPqBfhbsGX?usp=sharing"
            class="dusk-btn"
            target="_blank"
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
            target="_blank"
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
            target="_blank"
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
            target="_blank"
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
            target="_blank"
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
            target="_blank"
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
            target="_blank"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>Day 5</span>
          </a>
        </li>
      </ul>
    </div>
    <div
      v-if="clubType === 'club-hackstack'"
      class="class-link"
    >
      <b>AI HackStack Quick Links</b>
      <ul class="list-inline">
        <li>
          <a
            v-tooltip.top="{
              content: 'Comprehensive Sensei guide',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://drive.google.com/drive/folders/15ohe32b4w9_d5aTgKB3WCAE2gXNK6llS"
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
              content: 'Day-by-day slides',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://drive.google.com/drive/folders/1v1rcEj_sDJQCQSrSCp3yd9vovtK3BQWE"
            target="_blank"
            class="dusk-btn"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>Club Curriculum</span>
          </a>
        </li>
        <li>
          <a
            v-tooltip.top="{
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://codecombat.com/ai/"
            class="dusk-btn"
            target="_blank"
          >
            <div class="quick-link-icon icon-external-link" />
            <span>AI HackStack</span>
          </a>
        </li>
      </ul>
      <b>Lessons</b>
      <ul class="list-inline">
        <li
          v-for="(lesson, index) in hackstackClubLessons"
          :key="`hs-${index}`"
        >
          <a
            v-tooltip.top="{
              content: `Lesson slides for ${lesson.title}`,
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            :href="lesson.link"
            class="dusk-btn"
            target="_blank"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>{{ lesson.title }}</span>
          </a>
        </li>
      </ul>
    </div>
    <div
      v-if="clubType === 'club-ozaria'"
      class="class-link"
    >
      <b>Ozaria Quick Links</b>
      <ul class="list-inline">
        <li>
          <a
            v-tooltip.top="{
              content: 'Comprehensive Sensei guide to running the Roblox: Intro to Coding and Game Design camp with CodeCombat Junior and CodeCombat Worlds.',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://drive.google.com/drive/folders/15ohe32b4w9_d5aTgKB3WCAE2gXNK6llS"
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
              content: 'Day-by-day slides',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://drive.google.com/drive/folders/1okwLkEkHre6y81Yx-CQXsZfz3JJABfuZ?usp=drive_link"
            target="_blank"
            class="dusk-btn"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>Club Curriculum</span>
          </a>
        </li>
      </ul>
      <b>Lessons</b>
      <ul class="list-inline">
        <li
          v-for="(lesson, index) in ozariaClubLessons"
          :key="`oz-${index}`"
        >
          <a
            v-tooltip.top="{
              content: `Lesson slides for ${lesson.title}`,
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            :href="lesson.link"
            class="dusk-btn"
            target="_blank"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>{{ lesson.title }}</span>
          </a>
        </li>
      </ul>
    </div>
    <div
      v-if="clubType === 'club-roblox'"
      class="class-link"
    >
      <b>CodeCombat Worlds(Roblox) Quick Links</b>
      <ul class="list-inline">
        <li>
          <a
            v-tooltip.top="{
              content: 'Comprehensive Sensei guide',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://drive.google.com/drive/folders/15ohe32b4w9_d5aTgKB3WCAE2gXNK6llS"
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
              content: 'Week-by-week slides',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://drive.google.com/drive/folders/15vF1jIq5yx7zQ8yZih_rNpuc21tfUsl-?usp=drive_link"
            target="_blank"
            class="dusk-btn"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>Club Curriculum</span>
          </a>
        </li>
        <li>
          <a
            v-tooltip.top="{
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://www.roblox.com/games/11704713454"
            class="dusk-btn"
            target="_blank"
          >
            <div class="quick-link-icon icon-external-link" />
            <span>Join Roblox Server</span>
          </a>
        </li>
      </ul>
      <b>Lessons</b>
      <ul class="list-inline">
        <li
          v-for="(lesson, index) in robloxClubLessons"
          :key="`rob-${index}`"
        >
          <a
            v-tooltip.top="{
              content: `Lesson slides for ${lesson.title}`,
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            :href="lesson.link"
            class="dusk-btn"
            target="_blank"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>{{ lesson.title }}</span>
          </a>
        </li>
      </ul>
    </div>
    <div
      v-if="clubType === 'club-esports'"
      class="class-link"
    >
      <b>AI League Quick Links</b>
      <ul class="list-inline">
        <li>
          <a
            v-tooltip.top="{
              content: 'Comprehensive Sensei guide',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://drive.google.com/drive/folders/15ohe32b4w9_d5aTgKB3WCAE2gXNK6llS"
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
              content: 'Week-by-week slides',
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://drive.google.com/drive/folders/1BeJeMjY4D7a4YBeUVGSGCFe009Wod6cn?usp=drive_link"
            target="_blank"
            class="dusk-btn"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>Club Curriculum</span>
          </a>
        </li>
        <li>
          <a
            v-tooltip.top="{
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://codecombat.com/play/ladder/equinox"
            class="dusk-btn"
            target="_blank"
          >
            <div class="quick-link-icon icon-external-link" />
            <span>Equinox Arena</span>
          </a>
        </li>
        <li>
          <a
            v-tooltip.top="{
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://codecombat.com/play/ladder/tundra-tower"
            class="dusk-btn"
            target="_blank"
          >
            <div class="quick-link-icon icon-external-link" />
            <span>Tundra Tower Arena</span>
          </a>
        </li>
        <li>
          <a
            v-tooltip.top="{
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://codecombat.com/play/ladder/sandstorm"
            class="dusk-btn"
            target="_blank"
          >
            <div class="quick-link-icon icon-external-link" />
            <span>Sandstorm Arena</span>
          </a>
        </li>
        <li>
          <a
            v-tooltip.top="{
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            href="https://codecombat.com/play/ladder/solar-skirmish"
            class="dusk-btn"
            target="_blank"
          >
            <div class="quick-link-icon icon-external-link" />
            <span>Solar Skirmish Arena</span>
          </a>
        </li>
      </ul>
      <b>Lessons</b>
      <ul class="list-inline">
        <li
          v-for="(lesson, index) in aiLeagueClubLessons"
          :key="`ai-league-${index}`"
        >
          <a
            v-tooltip.top="{
              content: `Lesson slides for ${lesson.title}`,
              classes: 'teacher-dashboard-tooltip lighter-p',
              autoHide: false
            }"
            :href="lesson.link"
            class="dusk-btn"
            target="_blank"
          >
            <div class="quick-link-icon icon-curriculum" />
            <span>{{ lesson.title }}</span>
          </a>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
import { mapActions, mapGetters } from 'vuex'
const AI_HACKSTACK_CLUB_LESSONS = [
  {
    title: 'Week 1',
    link: 'https://docs.google.com/presentation/d/1OvvW1HT22Q-vNnYcJTlRTbl1qSdU_2JmaaLcRaWoEFk/edit?usp=drive_link'
  },
  {
    title: 'Week 2',
    link: 'https://docs.google.com/presentation/d/127VRzq6ZMbD0elWEuJnkyJjM8yiOOXM4rc9eB1rFy8U/edit?usp=sharing'
  },
  {
    title: 'Week 3',
    link: 'https://docs.google.com/presentation/d/1zdkgokkq5GSjxiANXU5nApPVyPLOzkTVoAN79TgefXY/edit?usp=drive_link'
  },
  {
    title: 'Week 4',
    link: 'https://docs.google.com/presentation/d/1c_BEPNpRtepR_Gkl7Ue_NG-aRhDldFbq2r45UfxWtpM/edit?usp=drive_link'
  },
  {
    title: 'Week 5',
    link: 'https://docs.google.com/presentation/d/11i3upl9jw6PuhMiwlvxDVzr-gBA9buMahbObcpcD6pQ/edit?usp=drive_link'
  },
  {
    title: 'Week 6',
    link: 'https://docs.google.com/presentation/d/1Bcg2BSHcBUPGR3RBuqi5-zXdGVphLqaSmICoaymdX4o/edit?usp=drive_link'
  },
  {
    title: 'Week 7',
    link: 'https://docs.google.com/presentation/d/1NQrFXnDtVZME9sJT54k8x6GWC3Rl2ps8OTpXazd2oyY/edit?usp=sharing'
  },
  {
    title: 'Week 8',
    link: 'https://docs.google.com/presentation/d/1gt2ttx7PNkduLzj_6T5X9Fm49I5NiDdWl_S554KPTDg/edit?usp=drive_link'
  },
  {
    title: 'Week 9',
    link: 'https://docs.google.com/presentation/d/1dKWY1HAizdmh-7MHht42rm26mO0tn8qr_wMN_OpWoXk/edit?usp=drive_link'
  },
  {
    title: 'Week 10',
    link: 'https://docs.google.com/presentation/d/1MvU21ry5lc9eQ1zoRwnYw7ojjOkBSVo253e9OcGSNZk/edit?usp=sharing'
  },
  {
    title: 'Week 11',
    link: 'https://docs.google.com/presentation/d/1g88Fexb7FdrA-2OAvFwwjRtZ2rMvDsYg8VG0tl0msaI/edit?usp=drive_link'
  },
  {
    title: 'Week 12',
    link: 'https://docs.google.com/presentation/d/1NGrCMrGl8Ep4pBQZNN5DgRNBUbnsjxijVrQkNe__TAQ/edit?usp=sharing'
  }
]

const OZARIA_CLUB_LESSONS = [
  {
    title: 'Week 1',
    link: 'https://docs.google.com/presentation/d/10vGNse-9_LeQdn2nnWIb6-AbDBo_OyBMYu_qHKztqtw/edit?usp=drive_link'
  },
  {
    title: 'Week 2',
    link: 'https://docs.google.com/presentation/d/10yrlsu9Lji-U_Qd63zt0kpEp9BSa3UXPNYtwps6poSA/edit?usp=drive_link'
  },
  {
    title: 'Week 3',
    link: 'https://docs.google.com/presentation/d/10yrlsu9Lji-U_Qd63zt0kpEp9BSa3UXPNYtwps6poSA/edit?usp=drive_link'
  },
  {
    title: 'Week 4',
    link: 'https://docs.google.com/presentation/d/1MuMQc61MeR1z8-jZY0LQBreA9nUgDQxnkVG504YXUX8/edit?usp=drive_link'
  },
  {
    title: 'Week 5',
    link: 'https://docs.google.com/presentation/d/1_yFfxCurga8UZGI2ZQ7VF-NXLWUy3gBqiWSwHm-N66U/edit?usp=drive_link'
  },
  {
    title: 'Week 6',
    link: 'https://docs.google.com/presentation/d/1a-p2EDfbBGEwndhaeqeCzB8LZwh-xoYKQ0fWZmcJma8/edit?usp=drive_link'
  },
  {
    title: 'Week 7',
    link: 'https://docs.google.com/presentation/d/15XpAqPquOXmzZmRQWNMpRo6boB1DFTFm_4r-IfOlokc/edit?usp=drive_link'
  },
  {
    title: 'Week 8',
    link: 'https://docs.google.com/presentation/d/1aQ_wCR5VRzC5aZHFOSk07Rkubcyxql-BssIybiGgedo/edit?usp=drive_link'
  },
  {
    title: 'Week 9',
    link: 'https://docs.google.com/presentation/d/16q4O3t_YWjvB9Pdx6vU1pbXlZJh9YCKBxRcTgNoLF0k/edit?usp=drive_link'
  },
  {
    title: 'Week 10',
    link: 'https://docs.google.com/presentation/d/16q4O3t_YWjvB9Pdx6vU1pbXlZJh9YCKBxRcTgNoLF0k/edit?usp=drive_link'
  },
  {
    title: 'Week 11',
    link: 'https://docs.google.com/presentation/d/1dEB25aMiNuYqPGt-4F-BdN1--djWUvPXd701vXIEqp0/edit?usp=drive_link'
  },
  {
    title: 'Week 12',
    link: 'https://docs.google.com/presentation/d/1tMa8rC_e6_7Kxq94ASsD8xndYrE_rT-TYM9cep-GfX4/edit?usp=drive_link'
  },
  {
    title: 'Week 13',
    link: 'https://docs.google.com/presentation/d/1I3S2KieaEpMi4T90c-t39PerXjV-4Nco6lVbV17Tkpw/edit?usp=drive_link'
  },
  {
    title: 'Week 14',
    link: 'https://docs.google.com/presentation/d/1oz6GFzMWPgBB6y6QwxH0BxSttytRIeWtN0l-xPHE1l8/edit?usp=drive_link'
  },
  {
    title: 'Week 15',
    link: 'https://docs.google.com/presentation/d/1WdR6vpJtMvvrNrv5xF2sIOK_Th5oEWxMQwNq9cp8krw/edit?usp=drive_link'
  },
  {
    title: 'Week 16',
    link: 'https://docs.google.com/presentation/d/1-AofjTqEfEMQVdONB0OT_hrDDLoYNT_qua8aN3gTzKc/edit?usp=drive_link'
  },
  {
    title: 'Week 17',
    link: 'https://docs.google.com/presentation/d/18yx2n-cYk8urX0i2C08mtMXqtvcC236mGW0aNQpfiZ8/edit?usp=drive_link'
  },
  {
    title: 'Week 18',
    link: 'https://docs.google.com/presentation/d/1KSomKBFQ8L9E8EOZpaqZZ30fGKgJSATUIKzTtMAmaUQ/edit?usp=drive_link'
  },
  {
    title: 'Week 19',
    link: 'https://docs.google.com/presentation/d/1Q6Yq2YqSOOcM9W3JHre_agBGbBeTjDr0so7Z6PNofzg/edit?usp=drive_link'
  },
  {
    title: 'Week 20',
    link: 'https://docs.google.com/presentation/d/1DLc45uDhSeIihXlfELWFG5ucQzextHrGdCocVA5HJiA/edit?usp=drive_link'
  },
  {
    title: 'Week 21',
    link: 'https://docs.google.com/presentation/d/1ayruYmO1E3oBfzhmxHEtUHnvl4Ff8h7MwlZLcOOki9A/edit?usp=drive_link'
  },
  {
    title: 'Week 22',
    link: 'https://docs.google.com/presentation/d/1DYpxhpCuHMv87i4h6YRidltVRsTNdOU1vueI39Pr21Q/edit?usp=drive_link'
  },
  {
    title: 'Week 23',
    link: 'https://docs.google.com/presentation/d/1DYpxhpCuHMv87i4h6YRidltVRsTNdOU1vueI39Pr21Q/edit?usp=drive_link'
  },
  {
    title: 'Week 24',
    link: 'https://docs.google.com/presentation/d/1IpZa16G5B7li7vtdZwEkYjzmWv6P9x3bVeaVum20hyw/edit?usp=drive_link'
  }
]

const ROBLOX_CLUB_LESSONS = [
  {
    title: 'Week 1',
    link: 'https://docs.google.com/presentation/d/1orH2X8ujRXZBAq73vV-FCVS5hl88oMdaCnRfsi7uzfY/edit?usp=drive_link'
  },
  {
    title: 'Week 2',
    link: 'https://docs.google.com/presentation/d/1uJSsCLxRAJycaR9UqC4auzxBS3u8IH8r8kVQryBfB5w/edit?usp=drive_link'
  },
  {
    title: 'Week 3',
    link: 'https://docs.google.com/presentation/d/1uJSsCLxRAJycaR9UqC4auzxBS3u8IH8r8kVQryBfB5w/edit?usp=drive_link'
  },
  {
    title: 'Week 4',
    link: 'https://docs.google.com/presentation/d/1l8vn4kTdQTuFr4PyoYXU6nQajHwngDdAW-mqo2tLFc8/edit?usp=drive_link'
  },
  {
    title: 'Week 5',
    link: 'https://docs.google.com/presentation/d/1Dd7S9Jvo8iPCCQhYAjsUtjf2qcpUsRl9epa0hRLKQUE/edit?usp=drive_link'
  },
  {
    title: 'Week 6',
    link: 'https://docs.google.com/presentation/d/1MZ6jv0L4jQwr4yKCg9c4WVyC-w2g7_CSRE1yEp_9CUM/edit?usp=drive_link'
  },
  {
    title: 'Week 7',
    link: 'https://docs.google.com/presentation/d/1RSbnkwfAQNSVhJWJfzS81xp8--ssaSMyg22XhyZgQJk/edit?usp=drive_link'
  },
  {
    title: 'Week 8',
    link: 'https://docs.google.com/presentation/d/1EoH2qSwvZIuaiwbKP0JvJRaEnueZn_sxyhVANATfdRA/edit?usp=drive_link'
  },
  {
    title: 'Week 9',
    link: 'https://docs.google.com/presentation/d/10YeHE1whJJ4Xzblegn4titWGkaT2FHRUfEVNSR4De1s/edit?usp=drive_link'
  },
  {
    title: 'Week 10',
    link: 'https://docs.google.com/presentation/d/10YeHE1whJJ4Xzblegn4titWGkaT2FHRUfEVNSR4De1s/edit?usp=drive_link'
  },
  {
    title: 'Week 11',
    link: 'https://docs.google.com/presentation/d/1RxgXWJx1L9c_cRLoUrIT990stvVz0-7J06_yOLeNMnM/edit?usp=drive_link'
  },
  {
    title: 'Week 12',
    link: 'https://docs.google.com/presentation/d/1ul0Vsrp1eMbT0CNNO-qBXabe6y3ZBlNQb_GSpDkPvVU/edit?usp=drive_link'
  },
  {
    title: 'Week 13- Harvest',
    link: 'https://docs.google.com/presentation/d/1X_CZXphWV62TnrMmEfvyX5X0O1WB1EXwzTAXeX4VeP8/edit?usp=drive_link'
  },
  {
    title: 'Week 13 - Combat',
    link: 'https://docs.google.com/presentation/d/1fnWYojZSPEG9l-cbSJIBZsHwh_dgMcm94M_8uKYV-WE/edit?usp=drive_link'
  },
  {
    title: 'Week 14',
    link: 'https://docs.google.com/presentation/d/1ZUTKyrMsRsmj8hXUCTPGbknL6ZK_wdoAEJBm_rRBxsc/edit?usp=drive_link'
  },
  {
    title: 'Week 15',
    link: 'https://docs.google.com/presentation/d/1DKX5NXDElzGlK8vJoCwJyYuz4R947dY87nbrdCxv9Fo/edit?usp=drive_link'
  },
  {
    title: 'Week 16',
    link: 'https://docs.google.com/presentation/d/1AGYkTnVzI-PWGSUuzJsMLP_C7H0NJPRwRe-3voL7rQk/edit?usp=drive_link'
  }
]

const AI_LEAGUE_CLUB_LESSONS = [
  {
    title: 'Equinox',
    link: 'https://drive.google.com/drive/folders/16lYF5Bt_WupEUv9rNfTN_byL8DSJK3iX?usp=drive_link'
  },
  {
    title: 'Tundra Tower',
    link: 'https://drive.google.com/drive/folders/1xhl8oMNLU5gwuEChg1wCair2VKK-A3ln?usp=drive_link'
  },
  {
    title: 'Sandstorm',
    link: 'https://drive.google.com/drive/folders/1gXBG1tpuAhYkJKX5GvvHZHX48duPnZ7O?usp=drive_link'
  }
]

export default {
  name: 'ClassLinksComponent',
  props: {
    showEsportsCampInfoCoco: {
      type: Boolean,
      default: false
    },
    showEsportsCampInfoOz: {
      type: Boolean,
      default: false
    },
    showJuniorCampInfo: {
      type: Boolean,
      default: false
    },
    clubType: {
      type: String,
      default: ''
    }
  },
  data () {
    return {
      hackstackClubLessons: AI_HACKSTACK_CLUB_LESSONS,
      ozariaClubLessons: OZARIA_CLUB_LESSONS,
      robloxClubLessons: ROBLOX_CLUB_LESSONS,
      aiLeagueClubLessons: AI_LEAGUE_CLUB_LESSONS
    }
  },
  computed: {
    ...mapGetters({
      tournaments: 'clans/tournaments',
      allTournamentsLoaded: 'clans/allTournamentsLoaded'
    }),
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
    })
  }
}
</script>

<style lang="scss">
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
