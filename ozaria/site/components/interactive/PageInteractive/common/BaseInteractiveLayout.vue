<script>
  import InteractiveTitle from './InteractiveTitle'

  export default {
    components: {
      'interactive-title': InteractiveTitle
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
  <div class="interactive-container">
    <interactive-title
      :interactive="interactive"
    />

    <div class="interactive-row">
      <div class="interactive">
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
</template>

<style scoped lang="scss">
  .interactive-container {
    display: flex;
    flex-direction: column;

    background-color: #FFF;
   }

  .interactive-row {
    display: flex;
    flex-direction: row;

    align-items: stretch;
    justify-content: center;

    .interactive {
      flex-grow: 1;
    }

    .interactive-art {
      display: flex;

      align-items: center;
      justify-content: center;

      background-color: #9b9b9b;

      img {
        width: 100%;
        max-width: 1000px;

        height: auto;
      }
    }
  }
</style>
