<script>
import { mapGetters } from 'vuex'
import InteractiveTitle from './InteractiveTitle'
import LayoutAspectRatioContainer from '../../../common/LayoutAspectRatioContainer'
import LayoutChrome from '../../../common/LayoutChrome'
import utils from 'core/utils'

export default {
  components: {
    LayoutAspectRatioContainer,
    LayoutChrome,
    InteractiveTitle
  },

  props: {
    interactive: {
      type: Object,
      required: true
    },

    artUrl: {
      type: String,
      default: undefined
    }
  },
  computed: {
    ...mapGetters({
      soundOn: 'layoutChrome/soundOn',
      getLevelNumber: 'gameContent/getLevelNumber'
    }),
    title () {
      if (!this.interactive) {
        return ''
      }
      const id = this.interactive._id
      const levelNumber = this.getLevelNumber(id) || this.getLevelNumber(this.interactive.original)
      const levelName = utils.i18n(this.interactive, 'displayName') || utils.i18n(this.interactive, 'name')
      return `${levelNumber ? `${levelNumber}.` : ''} ${levelName}`
    }
  }
}
</script>

<template>
  <LayoutChrome
    :title="title"
  >
    <div class="interactive-page">
      <LayoutAspectRatioContainer
        class="interactive-container"
        :aspect-ratio="16 / 9"
      >
        <div class="interactive">
          <interactive-title
            class="title-bar"
            :interactive="interactive"
          />

          <div class="interactive-row">
            <div class="interactive-content">
              <slot />
            </div>

            <div
              v-if="artUrl"
              class="interactive-art"
            >
              <img
                :src="artUrl"
                alt="Interactive Art"
              >
            </div>
          </div>
        </div>
      </LayoutAspectRatioContainer>
    </div>
  </LayoutChrome>
</template>

<style scoped lang="scss">
  .interactive-page {
    width: 100%;
    height: 100%;

    display: flex;
    flex-direction: column;

    align-items: center;
    justify-content: center;

    .interactive-container {
      min-width: 760px !important;
      min-height: 397px !important;

      overflow: hidden;

      .interactive {
        width: 100%;
        height: 100%;

        background-color: #FFF;

        display: flex;

        flex-direction: column;
      }
    }
   }

  .title-bar {
    flex-grow: 0;
    flex-shrink: 0;

    height: 14.1%;
  }

  .interactive-row {
    display: flex;
    flex-direction: row;

    align-items: stretch;
    justify-content: center;

    height: 85.9%;

    .interactive-content {
      flex-grow: 1;
    }

    .interactive-art {
      flex-grow: 0;
      flex-shrink: 0;

      width: 41.6%;

      display: flex;

      align-items: center;
      justify-content: center;

      background-color: #9b9b9b;

      overflow: hidden;
      height: 100%;

      img {
        width: 100%;
        object-fit: contain;
      }
    }
  }
</style>
