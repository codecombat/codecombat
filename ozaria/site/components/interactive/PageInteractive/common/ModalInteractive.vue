<script>
  import BaseModalContainer from '../../../common/BaseModalContainer'
  import BaseSpeechBubble from '../../../common/BaseSpeechBubble'
  import BaseButton from '../../../common/BaseButton'

  export default {
    components: {
      BaseModalContainer,
      BaseSpeechBubble,
      BaseButton
    },

    props: {
      image: {
        type: String,
        default: undefined
      },

      show: {
        type: Boolean,
        default: false
      },

      success: {
        type: Boolean,
        default: false
      },

      smallText: {
        type: Boolean,
        default: false
      }
    },

    computed: {
      imageUrl () {
        if (this.image) {
          return this.image
        }

        if (this.success) {
          return '/images/ozaria/interactives/alejandro_modal.png'
        }

        return '/images/ozaria/level/vega_headshot_transparent.png'
      }
    }
  }
</script>

<template>
  <base-modal-container class="modal">
    <div
      class="interactive-modal-content"
    >
      <img
        :src="imageUrl"
        alt="Hero Image"
        class="hero"
      >

      <div class="interactive-modal-right-col">
        <base-speech-bubble
                :class="{ message: true, smallText }"
        >
          <slot />
        </base-speech-bubble>

        <base-button
          class="interactive-modal-close"
          @click="$emit('close')"
        >
          {{ $t('modal.try_again') }}
        </base-button>
      </div>
    </div>
  </base-modal-container>
</template>

<style lang="scss" scoped>
  .modal {
    ::v-deep .modal-container {
      width: 528px;
      height: 329px;

      padding: 40px;

      background: linear-gradient(230.93deg, #FBF7BB 0%, #E2F3F9 55.98%, #C9DFFE 100%);
      border-radius: 40px;

      transition: all .3s ease;
    }
  }

  .interactive-modal-content {
    width: 100%;
    height: 100%;

    display: flex;
    flex-direction: row;

    align-items: center;
    justify-content: space-around;

    .hero {
      max-height: 100%;

      width: auto;
      max-width: 40%;
    }

    .message {
      max-height: 50%;

      margin-bottom: auto;

      color: #000;

      font-family: Avro, 'Open Sans', serif;
      font-size: 24px;
      font-weight: bold;

      letter-spacing: 0.48px;
      line-height: 32px;

      text-align: center;
    }

    .smallText {
      font-size: 18px;
      line-height: 22px;
      letter-spacing: 0.48px;
    }

    .interactive-modal-right-col {
      flex-grow: 0;

      width: 50%;
      height: 100%;

      display: flex;
      flex-direction: column;

      align-items: center;
      justify-content: space-between;
    }
  }
</style>
