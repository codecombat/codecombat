<template>
  <div class="arena">
    <a
      class="arena__info"
      :href="url"
      target="_blank"
    >
      <img
        :src="arena.image"
        :alt="arena.name"
        class="arena__image"
      >
    </a>
    <div
      class="arena__helpers"
    >
      <span
        v-if="arena.difficulty"
        class="arena__difficulty"
        :class="`difficulty__color__${difficulty} ${tournament ? 'tournament__difficulty' : ''}`"
      >
        {{ difficultyI18n }}
      </span>

      <div class="arena__helpers__description">
        {{ readableDescription({ description: arena.description, imgPath: arena.image }) }}
      </div>
      <div class="arena__helpers__bottom">
        <div
          v-if="tournament"
          class="arena__helpers__bottom__tournament_status"
        >
          <div class="clan">
            {{ $t('tournament.team_name', { name: (clan.displayName || clan.name), interpolation: { escapeValue: false } }) }}
          </div>
          <div class="status">
            {{ $t('tournament.status', { state: tournament.state }) }}
          </div>
          <div class="time">
            {{ tournamentTime }}
          </div>
        </div>
        <div class="arena__helpers__bottom__permission">
          <span class="arena__helpers-element">
            <button
              v-if="arenaCurriculum"
              class="btn btn-secondary dusk-btn"
              :disabled="disabled"
              @click="openCurriculum"
            >
              {{ $t('nav.curriculum') }}
            </button>
            <button
              v-if="!canEdit"
              class="btn btn-secondary btn-moon"
              :disabled="disabled"
              @click="$emit('create-tournament')"
            >
              {{ $t('tournament.create_tournament') }}
            </button>
            <template
              v-if="canEdit"
            >
              <button
                class="btn btn-secondary btn-moon"
                :disabled="disabled"
                @click="$emit('edit-tournament')"
              >
                {{ $t('tournament.edit_tournament') }}
              </button>
              <button
                class="btn btn-secondary dusk-btn"
                @click="goTournament"
              >
                {{ $t('tournament.view_tournament') }}
              </button>
            </template>
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import moment from 'moment'
import { mapGetters } from 'vuex'
import { ARENA_CURRICULUM } from 'app/core/constants'
export default {
  name: 'LadderPanel',
  props: {
    championship: {
      type: Boolean,
      default: false,
    },
    arena: {
      type: Object,
      default () {
        return {}
      },
    },
    tournament: {
      type: Object,
      default () {
        return undefined
      },
    },
    canCreate: {
      type: Boolean,
    },
    canEdit: {
      type: Boolean,
    },
    clanId: {
      type: String,
      default: '',
    },
    disabled: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    ...mapGetters({
      clanByIdOrSlug: 'clans/clanByIdOrSlug',
    }),
    tournamentTime () {
      if (this.tournament) {
        switch (this.tournament.state) {
        case 'initializing': return $.i18n.t('tournament.from_start', { time: this.duration })
        case 'ended':
        case 'starting': return $.i18n.t('tournament.from_end', { time: this.duration })
        }
      }
      return ''
    },
    clan () {
      if (this.tournament) {
        return this.clanByIdOrSlug(this.tournament.clan) || {}
      }
      return {}
    },
    duration () {
      if (this.tournament) {
        switch (this.tournament.state) {
        case 'initializing': return moment(this.tournament.startDate).fromNow()
        case 'ended':
        case 'starting': return moment(this.tournament.endDate).fromNow()
        }
      }
      return undefined
    },
    url () {
      const baseUrl = `/play/ladder/${this.arena.slug}`
      if (this.tournament) {
        if (this.tournament.clan) {
          return baseUrl + `/clan/${this.tournament.clan}?tournament=${this.tournament._id}`
        } else {
          return baseUrl + `?tournament=${this.tournament._id}` // for global AI league
        }
      }
      if (this.clanId) {
        return baseUrl + `/clan/${this.clanId}`
      }
      return baseUrl
    },
    arenaCurriculum () {
      return ARENA_CURRICULUM?.[this.arena.slug] || this.arena.arenaCurriculumUrl
    },
    difficulty () {
      const difficulties = ['beginner', 'intermediate', 'advanced']
      const index = this.championship ? this.arena.difficulty - 3 : this.arena.difficulty - 1
      return difficulties[index]
    },
    difficultyI18n () {
      return $.i18n.t(`ladder.difficulty_${this.difficulty}`)
    },
  },
  methods: {
    difficultyStars (difficulty) {
      return Array(difficulty).fill().map(i => '★').join('')
    },
    readableDescription ({ description, imgPath }) {
      if (!imgPath) return description
      const imgExtension = imgPath.slice(imgPath.indexOf('.'))
      const imgExtensionIndex = description.indexOf(imgExtension)
      if (imgExtensionIndex === -1) return description
      const startPosition = imgExtensionIndex + imgExtension.length + 1
      return description.slice(startPosition) || null
    },
    goTournament () {
      window.open(this.url, '_blank')
    },
    openCurriculum () {
      if (this.arenaCurriculum) {
        window.open(this.arenaCurriculum, '_blank')
      }
    },
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/common/button";
@import "ozaria/site/styles/common/variables.scss";
@import "ozaria/site/components/teacher-dashboard/common/dusk-button";

.btn-moon, .dusk-btn {
  font-size: 14px;
  padding: 0.5rem 1rem;
  min-width: 120px;
}

.dusk-btn {
  display: unset !important;
  text-transform: uppercase;
  font-weight: bold;
}

.arena {
  &__info {
    display: block;
    position: relative;

    text-decoration: none;
    color: inherit;

    &:hover {
      filter: brightness(1.2);
      -webkit-filter: brightness(1.2);
      box-shadow: 0 0 5px #000;
    }
  }

  &__name {
    font-size: 1.5rem;
  }

  &__image {
    width: 100%;

    color: #ffffff;
    font-size: 3.5rem;
  }

  &__difficulty {
    position: absolute;
    bottom: 0;
    left: 0;

    font-size: 2rem;
    font-weight: 500;

    background-color: rgba(#808080, 1);

    padding: .5rem;
    border-radius: 2px;

    &.tournament__difficulty {
      bottom: 100%;
    }

    &.difficulty__color {
      &__beginner {
        background-color: #d4edbc;
        color: #4f8a10;
      }
      &__intermediate {
        background-color: #ffe5a0;
        color: #9f6000;
      }
      &__advanced {
        background-color: #ffcfc9;
        color: #9f6000;
      }
    }
  }

  &__helpers {
    position: relative;
    background-color: #d3d3d3;

    &__bottom {
      display: flex;
      justify-content: space-between;
      align-items: flex-end;

      &__tournament_status {
        margin-left: 1rem;
        color: black;
        font-weight: bold;
        line-height: 2rem;
      }

      &__permission {
        flex-grow: 1;
        text-align: right;
        padding: .5rem;
      }
    }

    &__description {
      font-weight: bold;
      color: black;

      padding: .5rem;
      line-height: 2rem;

      &:empty {
        padding: 0;
      }
    }

    &-element {
      &:not(:last-child) {
        padding-right: 1rem;
      }
    }
  }
}
</style>
