<template>
  <div
    class="main-ladder-view-v2"
    v-if="usableArenas"
  >
    <div class="ladder-view">
      <div
        class="arena"
        v-for="arena in usableArenas"
      >
        <a class="arena__info" :href="`/play/ladder/${arena.slug}`">
          <!--        <span class="arena__name">{{ arena.name }}</span>-->
          <img :src="arena.image" :alt="arena.name" class="arena__image">
          <span class="arena__difficulty">
            Difficulty: <span class="arena__stars">★★★</span>
          </span>
        </a>
        <div
          class="arena__helpers"
          v-if="canUseArenaHelpers"
        >

          <span class="arena__helpers-element">
            <button
              class="btn btn-secondary btn-moon"
              @click="handleCreateTournament"
            >
              Create Tournament
            </button>
          </span>

          <span class="arena__helpers-element">
            <button
              class="btn btn-secondary btn-moon"
              @click="handleEditTournament"
            >
              Edit Tournament
            </button>
          </span>

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
    }
  }
}
</script>

<style scoped lang="scss">
.main-ladder-view-v2 {
  font-size: 62.5%;
}

.ladder-view {
  padding: 10rem 20rem;
  color: #ffffff;
}

.btn-moon {
  background-color: #d1b147;
  color: #232323;
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
    background-color: lightgrey;
    text-align: right;
    padding: .5rem;

    &-element {
      &:not(:last-child) {
        padding-right: 1rem;
      }
    }
  }
}
</style>
