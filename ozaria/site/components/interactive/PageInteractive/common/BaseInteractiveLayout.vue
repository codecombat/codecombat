<script>
  import InteractiveTitle from './InteractiveTitle'
  import LayoutAspectRatioContainer from '../../../common/LayoutAspectRatioContainer'
  import LayoutChrome from '../../../common/LayoutChrome'

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
    }
  }
</script>

<template>
  <LayoutChrome>
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

    background-color: #F1BF33;

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
  }

  .interactive-row {
    flex-grow: 1;

    display: flex;
    flex-direction: row;

    align-items: stretch;
    justify-content: center;

    .interactive-content {
      flex-grow: 7;
    }

    .interactive-art {
      flex-grow: 5;

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
