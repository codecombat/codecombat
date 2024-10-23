<script>
import { mapGetters, mapActions, mapMutations } from 'vuex'
import Leaderboard from 'app/views/landing-pages/league/components/Leaderboard'
import ClanSelector from './ClanSelectorTeachers.vue'
import RemainingTimeView from './RemainingTimeView.vue'
import { AILeagueSeasons } from 'core/utils'

import ContentBox from 'app/components/common/elements/ContentBox.vue'
import BaseCloudflareVideo from 'app/components/common/BaseCloudflareVideo.vue'
import AILeagueResources from './AILeagueResources'
import LadderView from 'app/views/ladder/MainLadderViewV2'
import { AI_LEAGUE_STEPS } from 'ozaria/site/components/teacher-dashboard/BaseTeacherDashboard/teacherDashboardTours'

import { findArena, currentRegularArena } from 'app/core/store/modules/seasonalLeague.js'

const VueShepherd = require('vue-shepherd')

export default {
  components: {
    Leaderboard,
    ClanSelector,
    ContentBox,
    BaseCloudflareVideo,
    RemainingTimeView,
    AILeagueResources,
    LadderView,
  },

  beforeRouteUpdate (to, from, next) {
    this.clanIdOrSlug = to.params.idOrSlug || null
    if (this.clanIdOrSlug) {
      this.anonymousPlayerName = features.enableAnonymization
    }
    next()
  },

  props: {
    idOrSlug: {
      type: String,
      default: null,
    },
  },

  data: () => ({
    clanIdOrSlug: '',
    anonymousPlayerName: false,
    toPage: 'custom',
    TYPES: {
      REGULAR: 'regular',
      CHAMPIONSHIP: 'championship',
    },
    regularOrChampionship: 'regular',
  }),

  computed: {
    ...mapGetters({
      getCurrentRegularArena: 'seasonalLeague/currentRegularArena',
      getCurrentChampionshipArena: 'seasonalLeague/currentChampionshipArena',
      globalRankings: 'seasonalLeague/globalRankings',
      globalChampionshipRankings: 'seasonalLeague/globalChampionshipRankings',
      globalLeaderboardPlayerCount: 'seasonalLeague/globalLeaderboardPlayerCount',
      globalChampionshipLeaderboardPlayerCount: 'seasonalLeague/globalChampionshipLeaderboardPlayerCount',
      clanRankings: 'seasonalLeague/clanRankings',
      clanChampionshipRankings: 'seasonalLeague/clanChampionshipRankings',
      clanLeaderboardPlayerCount: 'seasonalLeague/clanLeaderboardPlayerCount',
      clanChampionshipLeaderboardPlayerCount: 'seasonalLeague/clanChampionshipLeaderboardPlayerCount',
      codePointsRankings: 'seasonalLeague/codePointsRankings',
      myClans: 'clans/myClans',
      childClanDetails: 'clans/childClanDetails',
      clanByIdOrSlug: 'clans/clanByIdOrSlug',
      isLoading: 'clans/isLoading',
      codePointsPlayerCount: 'seasonalLeague/codePointsPlayerCount',
    }),

    championshipAvailable () {
      return !!this.getCurrentChampionshipArena
    },

    regularArenaSlug () {
      if (this.regularOrChampionship === this.TYPES.REGULAR) {
        return this.getCurrentRegularArena.slug
      }
      return this.getCurrentChampionshipArena?.slug
    },

    currentSelectedClan () {
      return this.clanByIdOrSlug(this.clanIdOrSlug) || null
    },

    hasEsportsProduct () {
      return me.getProductsByType('esports').length > 0
    },

    currentSelectedClanChildDetails () {
      const selectedId = this.clanIdSelected
      if (selectedId === '') {
        return []
      }
      const result = this.childClanDetails(selectedId)
      return result
    },

    clanIdSelected () {
      return (this.currentSelectedClan || {})._id || ''
    },

    selectedClanRankings () {
      if (this.regularOrChampionship === this.TYPES.REGULAR) {
        return this.clanRankings(this.clanIdSelected)
      }
      return this.clanChampionshipRankings(this.clanIdSelected)
    },

    selectedClanLeaderboardPlayerCount () {
      if (this.regularOrChampionship === this.TYPES.REGULAR) {
        return this.clanLeaderboardPlayerCount(this.clanIdSelected)
      }
      return this.clanChampionshipLeaderboardPlayerCount(this.clanIdSelected)
    },

    selectedGlobalRankings () {
      if (this.regularOrChampionship === this.TYPES.REGULAR) {
        return this.globalRankings
      }
      return this.globalChampionshipRankings
    },

    selectedGlobalLeaderboardPlayerCount () {
      if (this.regularOrChampionship === this.TYPES.REGULAR) {
        return this.globalLeaderboardPlayerCount
      }
      return this.globalChampionshipLeaderboardPlayerCount
    },

    selectedClanCodePointsRankings () {
      return this.codePointsRankings(this.clanIdSelected) || []
    },

    nextArenaAvailable () {
      const season = this.getCurrentRegularArena.season
      const nextArena = findArena(season + 1, this.getCurrentRegularArena.type)
      return !!nextArena
    },

    previousArenaAvailable () {
      const season = this.getCurrentRegularArena.season
      const previousArena = findArena(season - 1, this.getCurrentRegularArena.type)
      return !!previousArena
    },

    boardTitle () {
      if (currentRegularArena.slug === this.getCurrentRegularArena.slug) {
        return $.i18n.t('league.current_season')
      }
      const season = AILeagueSeasons.find(s => s.number === this.getCurrentRegularArena.season)
      const seasonTitle = $.i18n.t('league.season_label', { seasonNumber: season.number, seasonName: $.i18n.t(`league.season_${season.number}`), interpolation: { escapeValue: false } })
      return `${seasonTitle}, ${this.getCurrentRegularArena.start.getFullYear()}`
    },

  },

  watch: {
    idOrSlug (newIdOrSlug, oldIdOrSlug) {
      if (newIdOrSlug !== oldIdOrSlug) {
        this.clanIdOrSlug = newIdOrSlug
      }
    },
    clanIdOrSlug (newSelectedClan, lastSelectedClan) {
      if (newSelectedClan !== lastSelectedClan) {
        this.loadRequiredData()
      }
    },

    clanIdSelected (newSelectedClan, lastSelectedClan) {
      if (newSelectedClan !== lastSelectedClan && newSelectedClan && !this.inSelectedClan()) {
        this.joinClan()
      }
    },
  },

  beforeCreate () {
    Vue.use(VueShepherd)
  },

  created () {
    this.clanIdOrSlug = this.$route?.params?.idOrSlug || this.idOrSlug
  },

  mounted () {
    if (!me.getSeenPromotion('ai-league-tour')) {
      this.triggerTour()
    }
    if (this.championshipAvailable) {
      this.regularOrChampionship = this.TYPES.CHAMPIONSHIP
    }
  },

  methods: {
    ...mapActions({
      loadClanRequiredData: 'seasonalLeague/loadClanRequiredData',
      loadChampionshipClanRequiredData: 'seasonalLeague/loadChampionshipClanRequiredData',
      loadGlobalRequiredData: 'seasonalLeague/loadGlobalRequiredData',
      loadChampionshipGlobalRequiredData: 'seasonalLeague/loadChampionshipGlobalRequiredData',
      loadCodePointsRequiredData: 'seasonalLeague/loadCodePointsRequiredData',
      fetchClan: 'clans/fetchClan',
      fetchChildClanDetails: 'clans/fetchChildClanDetails',
    }),
    ...mapMutations({
      paginateArenas: 'seasonalLeague/paginateArenas',
    }),

    triggerTour () {
      const tour = this.$shepherd({
        useModalOverlay: true,
        scrollTo: true,
        defaultStepOptions: {
          classes: 'shepherd-dashboard-theme',
        },
      })

      tour.addSteps(AI_LEAGUE_STEPS)
      tour.start()
      tour.on('complete', () => {
        me.setSeenPromotion('ai-league-tour')
        me.save()
      })
    },
    goPreviousArena () {
      if (!this.previousArenaAvailable) {
        return
      }
      this.paginateArenas('previous')
      this.loadRequiredData()
    },

    goNextArena () {
      if (!this.nextArenaAvailable) {
        return
      }
      this.paginateArenas('next')
      this.loadRequiredData()
    },

    changeLeagueType (leagueType) {
      this.regularOrChampionship = leagueType
    },

    changeClanSelected (e) {
      let newSelectedClan = ''
      if (e.target.value === 'global') {
        newSelectedClan = ''
      } else {
        newSelectedClan = e.target.value
      }

      const leagueURL = newSelectedClan ? `/teachers/ai-league/${newSelectedClan}` : '/teachers/ai-league'

      application.router.navigate(leagueURL, { trigger: true })
    },
    toggleLeague (page) {
      this.toPage = page
    },

    async loadRequiredData () {
      if (this.clanIdOrSlug) {
        try {
          await this.fetchClan({ idOrSlug: this.clanIdOrSlug })
        } catch (e) {
          // Default to global page
          application.router.navigate('league', { trigger: true })
          return
        }

        if (['school-network', 'school-subnetwork', 'school-district'].includes(this.currentSelectedClan?.kind)) {
          this.fetchChildClanDetails({ id: this.currentSelectedClan._id })
            .catch(() => {
              console.error('Failed to retrieve child clans.')
            })
        }
        $.get('/esports/anonymous/' + this.currentSelectedClan._id).then((res) => {
          this.anonymousPlayerName = res.anonymous
        })

        this.loadClanRequiredData({ leagueId: this.clanIdSelected })
        this.loadChampionshipClanRequiredData({ leagueId: this.clanIdSelected })
        this.loadCodePointsRequiredData({ leagueId: this.clanIdSelected })
      } else {
        this.loadGlobalRequiredData()
        this.loadChampionshipGlobalRequiredData()
        this.loadCodePointsRequiredData({ leagueId: '' })
      }
    },

    inSelectedClan () {
      if (!this.currentSelectedClan) {
        return false
      }

      return (me.get('clans') || []).indexOf(this.currentSelectedClan._id) !== -1
    },

    isClanCreator () {
      return (this.currentSelectedClan || {}).ownerID === me.id
    },

    isTeacher () {
      return me.isTeacher()
    },
  },
}
</script>

<template>
  <div>
    <header class="header container-fluid">
      <section class="row esports-header">
        <div class="header-left">
          <clan-selector
            v-if="!isLoading && Array.isArray(myClans)"
            :clans="myClans"
            :selected="clanIdSelected || clanIdOrSlug"
            :id-or-slug="idOrSlug"
            @change="e => changeClanSelected(e)"
          />
        </div>
        <div class="toggle-switch button-group league-switch">
          <button
            class="btn toggle-btn"
            :class="{ 'active': toPage === 'custom' }"
            @click="toggleLeague('custom')"
          >
            {{ $t('league.global') }}
          </button>
          <button
            id="custom-button"
            class="btn toggle-btn"
            :class="{ 'active': toPage === 'global' }"
            @click="toggleLeague('global')"
          >
            {{ $t('league.custom') }}
          </button>
        </div>
        <remaining-time-view />
      </section>
    </header>
    <main
      v-if="toPage === 'custom'"
      class="container"
    >
      <section class="row">
        <div class="col-lg-3 video-image-container">
          <base-cloudflare-video
            ref="video"
            class="base-coludflare-video"
            video-cloudflare-id="0bdb79d2ce155d589745f891b087f572"
            :sound-on="false"
            preload="none"
            :loop="false"
            :autoplay="false"
            :controls="true"
          />
        </div>
        <div class="col-lg-6">
          <h1 class="text-h1">
            {{ $t('league.codecombat_ai_league') }}
          </h1>
          <p class="text-p">
            {{ $t('league.codecombat_ai_league_description') }}
          </p>
        </div>
        <AILeagueResources class="col-lg-3" />
      </section>

      <div class="row text-center">
        <div class="col-lg-12">
          <content-box>
            <template #text>
              <div class="box-title">
                <span
                  class="image-prev"
                  :class="{ disabled: !previousArenaAvailable }"
                  @click="goPreviousArena"
                >&larr;</span>
                {{ boardTitle }}
                <span
                  class="image-next"
                  :class="{ disabled: !nextArenaAvailable }"
                  @click="goNextArena"
                >&rarr;</span>
              </div>
              <div class="box-content">
                <div class="league-type-buttons">
                  <div class="button-group">
                    <button
                      class="btn toggle-btn"
                      :class="{ 'active': regularOrChampionship === TYPES.REGULAR }"
                      @click="changeLeagueType(TYPES.REGULAR)"
                    >
                      {{ $t('league.regular') }}
                    </button>
                    <button
                      class="btn toggle-btn"
                      :class="{ 'active': regularOrChampionship === TYPES.CHAMPIONSHIP, 'disabled': !championshipAvailable }"
                      @click="changeLeagueType(TYPES.CHAMPIONSHIP)"
                    >
                      {{ $t('league.championship') }}
                    </button>
                  </div>
                </div>
              </div>
              <leaderboard
                v-if="currentSelectedClan"
                :key="`${clanIdSelected}-score`"
                :title="$t(`league.${regularArenaSlug.replace(/-/g, '_')}`)"
                :rankings="selectedClanRankings"
                :player-count="selectedClanLeaderboardPlayerCount"
                :clan-id="clanIdSelected"
                class="leaderboard-component"
                style="color: black;"
              />
              <leaderboard
                v-else
                :rankings="selectedGlobalRankings"
                :title="$t(`league.${regularArenaSlug.replace(/-/g, '_')}`)"
                :player-count="selectedGlobalLeaderboardPlayerCount"
                class="leaderboard-component"
              />
            </template>
          </content-box>
        </div>
      </div>
    </main>
    <main
      v-else
      class="container black-background"
    >
      <ladder-view
        :id-or-slug="clanIdOrSlug || 'global'"
        :inside-teacher-dashboard="true"
      />
    </main>
  </div>
</template>

<style lang="scss" scoped>
.header {
  padding: 20px 0;
  background: #F2F2F2;
  box-shadow: 0px 4px 10px 0px rgba(0, 0, 0, 0.25);
}

.container {
  display: flex;
  gap: 50px;
  flex-direction: column;
  width: 100%;
  padding: 0 40px;
}

.video-image-container {
  display: flex;
  justify-content: center;
  align-items: center;

  min-height: 200px;

  .base-coludflare-video {
    border-radius: 10px;
    overflow: hidden;
  }

  iframe,
  div {
    min-width: 100%;
    min-height: 100%;
    object-fit: cover;
  }

  iframe {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
  }
}

.text-h1 {
  color: #131B25;
  font-feature-settings: 'clig' off, 'liga' off;
  font-family: "Work Sans";
  font-size: 28px;
  font-style: normal;
  font-weight: 600;
  line-height: 38px;
  letter-spacing: 0.56px;
  padding-bottom: 20px;
}

.text-p {
  color: #131B25;
  font-family: "Work Sans";
  font-size: 18px;
  font-style: normal;
  font-weight: 400;
  line-height: 22px;
}

.box-title {
  color: #000;
  display: flex;
  justify-content: space-between;
  align-items: center;
  text-align: center;
  font-family: "Work Sans";
  font-size: 24px;
  border-bottom: 1px solid #D8D8D8;
  padding-bottom: 10px;
  height: 40px;
  width: 100%;
  margin-bottom: 10px;
  span {
    cursor: pointer;
    box-shadow: 0px 4px 10px 0px rgba(0, 0, 0, 0.25);
    color: #F7D047;
    background-color: #476FB1;
    width: 30px;
    height: 30px;
    border-radius: 30px;
    display: flex;
    justify-content: center;
    align-items: center;
    text-align: center;
    &:hover:not(.disabled) {
      box-shadow: 0px 4px 10px 0px rgba(0, 0, 0, 0.5);
    }
    &.disabled {
      cursor: default;
      background-color: #ADADAD;
      color: #fff;
    }
  }
}

::v-deep {
  .table-responsive {
    width: 100%;
  }
}

.esports-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 20px;
}

.header-left {
  display: flex;
  justify-content: flex-start;
  align-items: center;
  gap: 10px;
}

.toggle-league {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  border-radius: 8px;
  border: 1px solid #476FB1;
  background: white;
  padding: 0 20px;
  height: 50px;

  color: #000;

  font-feature-settings: 'clig' off, 'liga' off;
  font-family: "Work Sans";
  font-size: 16px;
  font-style: normal;
  font-weight: 600;
  line-height: 17px;
  position: relative;
}
.black-background {
  background-color: #0c1016;
}
.box-content {
  width: 100%;
}

.button-group {
  display: inline-flex;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.toggle-btn {
  padding: 10px 20px;
  border: none;
  background-color: #f0f0f0;
  color: #333;
  cursor: pointer;
  transition: background-color 0.3s, color 0.3s;
  margin: 0;

  &:first-child {
    border-radius: 8px 0 0 8px;
  }

  &:last-child {
    border-radius: 0 8px 8px 0;
    margin-left: -1px;
  }

  &.active {
    background-color: #476FB1;
    color: white;
    position: relative;
    z-index: 1;
  }

  &.disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  &:not(.disabled):hover {
    background-color: #e0e0e0;
  }

  &.active:hover {
    background-color: #3a5d94;
  }
}

.toggle-switch {
  margin-left: 10px;
}

.league-type-buttons {
  width: 100%;
  display: flex;
  justify-content: center;
  margin-bottom: 20px;
}

.box-content {
  width: 100%;
}

.league-switch {
  .toggle-btn {
    &:not(.active) {
      background-color: #fff;

      &:hover {
        background-color: #e0e0e0;
      }
    }
  }
}
</style>
