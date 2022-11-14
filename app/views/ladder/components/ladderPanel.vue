<template>
  <div class="arena">
    <a
      class="arena__info"
      :href="`/play/ladder/${arena.slug}`"
    >
      <img
        :src="arena.image"
        :alt="arena.name"
        class="arena__image"
      >
      <span
        v-if="arena.difficulty"
        class="arena__difficulty"
      >
        {{ $t('play.level_difficulty') }} <span class="arena__stars">{{ difficultyStars(arena.difficulty) }}</span>
      </span>
    </a>
    <div
      class="arena__helpers"
    >
      <div class="arena__helpers__description">
        {{ readableDescription({ description: arena.description, imgPath: arena.image }) }}
      </div>
      <div
        class="arena__helpers__permission"
      >
        <span class="arena__helpers-element">
          <button
            v-if="canCreate"
            class="btn btn-secondary btn-moon"
            @click="emit('createTournament')"
          >
            {{ $t('tournament.create_tournament') }}
          </button>
        </span>

        <span class="arena__helpers-element">
          <button
            v-if="canEdit"
            class="btn btn-secondary btn-moon"
            @click="emit('editTournament')"
          >
            {{ $t('tournament.edit_tournament') }}
          </button>
        </span>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'LadderPanel',
  props: {
    arena: {
      type: Object,
      default () {
        return {}
      }
    },
    canCreate: {
      type: Boolean
    },
    canEdit: {
      type: Boolean
    }
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
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/common/button";
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
