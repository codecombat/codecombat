<template>
  <div
    class="ladder-view-v2"
  >
    <div class="ladder-head">
      <h3 class="ladder-head__title">{{ $t('ladder.title') }}</h3>
      <h5 class="ladder-head__subtitle">{{ $t('play.campaign_multiplayer_description') }}</h5>
    </div>
    <div class="ladder-view" v-if="usableArenas">
      <div
        class="arena"
        v-for="arena in usableArenas"
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
import { mapActions, mapGetters } from "vuex";

export default {
  name: 'MainLadderViewV2',
  async created() {
    await this.fetchUsableArenas()
  },
  updated() {
    try {
      $('#flying-focus').css({top: 0, left: 0}) // because it creates empty space on bottom of page when coming from /league page
    } catch (err) {
      console.log('flying-focus error deleting', err)
    }
  },
  computed: {
    ...mapGetters({
      usableArenas: 'seasonalLeague/usableArenas'
    }),
    canUseArenaHelpers () {
      return me.isAdmin()
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
    }
  }
}
</script>

<style scoped lang="scss">
.ladder-view-v2 {
  font-size: 62.5%;
}

.ladder-view {
  padding: 5rem 20rem;
  color: #ffffff;
}

.btn-moon {
  background-color: #d1b147;
  color: #232323;
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

.arena {
  //text-align: center;

  &__info {
    display: block;
    position: relative;

    text-decoration: none;
    color: inherit;
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
