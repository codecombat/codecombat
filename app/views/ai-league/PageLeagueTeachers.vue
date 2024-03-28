<script>
import { mapGetters, mapActions } from 'vuex'
import Leaderboard from 'app/views/landing-pages/league/components/Leaderboard'
import ClanSelector from './ClanSelectorTeachers.vue'
import { activeArenas } from 'core/utils'

import ContentBox from 'app/components/common/elements/ContentBox.vue'
import BaseCloudflareVideo from 'app/components/common/BaseCloudflareVideo.vue'
const _ = require('lodash')

const currentRegularArena = _.last(_.filter(activeArenas(), a => a.type === 'regular' && a.end > new Date()))

export default {
  components: {
    Leaderboard,
    ClanSelector,
    ContentBox,
    BaseCloudflareVideo,
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
      default: null
    }
  },

  data: () => ({
    clanIdOrSlug: '',
    regularArenaSlug: currentRegularArena ? currentRegularArena.slug : null,
    anonymousPlayerName: false,
  }),

  computed: {
    ...mapGetters({
      globalRankings: 'seasonalLeague/globalRankings',
      globalLeaderboardPlayerCount: 'seasonalLeague/globalLeaderboardPlayerCount',
      clanRankings: 'seasonalLeague/clanRankings',
      clanLeaderboardPlayerCount: 'seasonalLeague/clanLeaderboardPlayerCount',
      codePointsRankings: 'seasonalLeague/codePointsRankings',
      myClans: 'clans/myClans',
      childClanDetails: 'clans/childClanDetails',
      clanByIdOrSlug: 'clans/clanByIdOrSlug',
      isLoading: 'clans/isLoading',
      codePointsPlayerCount: 'seasonalLeague/codePointsPlayerCount'
    }),

    currentSelectedClan () {
      return this.clanByIdOrSlug(this.clanIdOrSlug) || null
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
      return this.clanRankings(this.clanIdSelected)
    },

    selectedClanLeaderboardPlayerCount () {
      return this.clanLeaderboardPlayerCount(this.clanIdSelected)
    },

    selectedClanCodePointsRankings () {
      return this.codePointsRankings(this.clanIdSelected) || []
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
    }
  },

  created () {
    this.clanIdOrSlug = this.$route?.params?.idOrSlug || this.idOrSlug
  },

  methods: {
    ...mapActions({
      loadClanRequiredData: 'seasonalLeague/loadClanRequiredData',
      loadChampionshipClanRequiredData: 'seasonalLeague/loadChampionshipClanRequiredData',
      loadGlobalRequiredData: 'seasonalLeague/loadGlobalRequiredData',
      loadChampionshipGlobalRequiredData: 'seasonalLeague/loadChampionshipGlobalRequiredData',
      loadCodePointsRequiredData: 'seasonalLeague/loadCodePointsRequiredData',
      fetchClan: 'clans/fetchClan',
      fetchChildClanDetails: 'clans/fetchChildClanDetails'
    }),

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
  <main class="container">
    <section class="row esports-header section-space">
      <div class="col-sm-4">
        <clan-selector
          v-if="!isLoading && Array.isArray(myClans) && myClans.length > 0"
          :clans="myClans"
          :selected="clanIdSelected || clanIdOrSlug"
          style="margin-bottom: 40px;"
          @change="e => changeClanSelected(e)"
        />
      </div>
    </section>

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
      <div class="col-lg-3 resources">
        <a
          class="resources__item screen"
          href="https://docs.google.com/presentation/d/1ouDOu2k-pOxkWswUKuik7CbrUCkYXF7N_jNjGO0II6o/edit#slide=id.gb06b5c7fa4_0_10"
          target="_blank"
        >
          {{ $t('league.teacher_getting_started_guide') }}
        </a>
        <a
          class="resources__item view-exemplar"
          href="https://codecombat.com/play/ladder/storm-siege"
          target="_blank"
        >
          {{ $t('league.try_ai_league_as_a_teacher') }}
        </a>
        <a
          class="resources__item view-exemplar"
          href="https://codecombat.zendesk.com/hc/en-us/categories/1500000915842-AI-League"
          target="_blank"
        >
          {{ $t('nav.faqs') }}
        </a>
      </div>
    </section>

    <div class="row text-center">
      <div class="col-lg-6 section-space">
        <content-box>
          <template #text>
            <div class="box-title">
              {{ $t('league.current_season') }}
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
              :rankings="globalRankings"
              :title="$t(`league.${regularArenaSlug.replace(/-/g, '_')}`)"
              :player-count="globalLeaderboardPlayerCount"
              class="leaderboard-component"
            />
          </template>
        </content-box>
      </div>
      <div class="col-lg-6 section-space">
        <content-box>
          <template #text>
            <div class="box-title">
              {{ $t('league.all_time') }}
            </div>
            <leaderboard
              :key="`${clanIdSelected}-codepoints`"
              :title="$t('league.codepoints')"
              :rankings="selectedClanCodePointsRankings"
              :clan-id="clanIdSelected"
              score-type="codePoints"
              class="leaderboard-component"
              :player-count="codePointsPlayerCount"
            />
          </template>
        </content-box>
      </div>
    </div>
  </main>
</template>

<style lang="scss" scoped>
.resources {
  display: flex;
  flex-direction: column;
  gap: 20px;

  &__item {
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

    &:after {
      position: absolute;
      content: '';
      display: block;
      width: 30px;
      height: 30px;
      background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_ViewExemplar.svg);
      background-color: #F7D047;
      background-repeat: no-repeat;
      background-position: 4px 2px;
      top: -15px;
      right: -15px;
      border-radius: 5px;
    }

    &.screen:after {
      background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_Screen.svg);
      background-color: #157A6C;
    }
  }
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
  .base-coludflare-video{
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
  justify-content: center;
  align-items: center;
  text-align: center;
  font-feature-settings: 'clig' off, 'liga' off;
  font-family: "Work Sans";
  font-size: 24px;
  font-style: normal;
  font-weight: 600;
  line-height: normal;
  letter-spacing: 0.56px;
  border-bottom: 1px solid #D8D8D8;
  height: 40px;
  width: 100%;
  margin-bottom: 40px;
}

::v-deep {
  .table-responsive {
    width: 100%;
  }
}
</style>
