<template>
  <div
    class="ladder-view-v2 container"
  >
    <div class="ladder-head row">
      <h3 class="ladder-head__title">{{ $t('ladder.title') }}</h3>
      <h5 class="ladder-head__subtitle">{{ $t('play.campaign_multiplayer_description') }}</h5>
    </div>
    <div class="ladder-subhead row">
      <a
        href="https://form.typeform.com/to/qXqgbubC?typeform-source=codecombat.com"
        target="_blank"
        class="btn btn-moon"
      >
        {{ $t('general.contact_us') }}
      </a>
      <div
        v-if="hasActiveAiLeagueProduct()"
        class="ladder-subhead__text"
      >
        {{ $t('league.contact_sales_custom') }}
      </div>
      <div
        v-else
        class="ladder-subhead__text"
      >
        {{ $t('league.without_license_blurb') }}
        <a
          href="https://docs.google.com/presentation/d/1fXzV0gh9U0QqhSDcYYlIOIuM3uivFbdC9UfT1OBydEE/edit#slide=id.gea9e183bfa_0_54"
          target="_blank"
          class="ladder-link"
        >
          {{ $t('league.custom_pricing') }}
        </a>
        {{ $t('league.more_details') }}
      </div>
    </div>
    <div class="ladder-view container" v-if="usableArenas">
      <div
        v-for="arena in usableArenas"
        :key="arena.slug"
        class="arena row"
      >
        <a class="arena__info" :href="`/play/ladder/${arena.slug}`">
          <img :src="arena.image" :alt="arena.name" class="arena__image">
          <span class="arena__difficulty" v-if="arena.difficulty">
            {{ $t('play.level_difficulty') }} <span class="arena__stars">{{ difficultyStars(arena.difficulty) }}</span>
          </span>
        </a>
        <div
          class="arena__helpers"
        >
          <div class="arena__helpers__description">{{ readableDescription({ description: arena.description, imgPath: arena.image }) }}</div>
          <div
            v-if="canUseArenaHelpers"
            class="arena__helpers__permission"
          >
            <span class="arena__helpers-element">
              <button
                class="btn btn-secondary btn-moon"
                @click="handleCreateTournament"
              >
                {{ $t('tournament.create_tournament') }}
              </button>
            </span>

            <span class="arena__helpers-element">
              <button
                class="btn btn-secondary btn-moon"
                @click="handleEditTournament"
              >
                {{ $t('tournament.edit_tournament') }}
              </button>
            </span>
          </div>

        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapActions, mapGetters } from 'vuex'

export default {
  name: 'MainLadderViewV2',
  computed: {
    ...mapGetters({
      usableArenas: 'seasonalLeague/usableArenas'
    }),
    canUseArenaHelpers () {
      return me.isAdmin()
    }
  },
  async created () {
    await this.fetchUsableArenas()
  },
  updated () {
    try {
      $('#flying-focus').css({ top: 0, left: 0 }) // because it creates empty space on bottom of page when coming from /league page
    } catch (err) {
      console.log('flying-focus error deleting', err)
    }
  },
  methods: {
    ...mapActions({
      fetchUsableArenas: 'seasonalLeague/fetchUsableArenas'
    }),
    handleCreateTournament () {
      window.alert('Create Tournament not ready')
    },
    handleEditTournament () {
      window.alert('Dummy')
    },
    // if we want to i18n this, then we need to hardcode them in front-end
    readableDescription ({ description, imgPath }) {
      if (!imgPath) return description
      const imgExtension = imgPath.slice(imgPath.indexOf('.'))
      const imgExtensionIndex = description.indexOf(imgExtension)
      if (imgExtensionIndex === -1) return description
      const startPosition = imgExtensionIndex + imgExtension.length + 1
      return description.slice(startPosition) || null
    },
    difficultyStars (difficulty) {
      return Array(difficulty).fill().map(i => '★').join('')
    },
    hasActiveAiLeagueProduct () {
      return me.hasAiLeagueActiveProduct()
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/common/button";
.ladder-view-v2 {
  font-size: 62.5%;
}

.ladder-view {
  padding: 5rem 20rem;
  color: #ffffff;
}

.ladder-head {
  text-align: center;

  &__title {
    color: #30efd3;
  }

  &__subtitle {
    color: #fff;
  }
}

.ladder-subhead {
  text-align: center;

  & > * {
    margin-top: 1.5rem;
  }

  &__text {
    color: #ffffff;
    font-size: 1.8rem;
  }
}

.ladder-link {
  color: #30efd3;
  text-decoration: underline;
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

  &:not(:last-child) {
    padding-bottom: 2rem;
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
    box-shadow: 0 1.5rem 4rem rgba(black, 0.4);
    border-radius: 2px;
  }

  &__helpers {
    background-color: #d3d3d3;

    &__permission {
      text-align: right;
      padding: .5rem;
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
