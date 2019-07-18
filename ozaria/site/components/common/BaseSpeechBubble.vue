<template>
  <div class="speech-bubble">
    <slot />

  </div>
</template>

<style lang="scss" scoped>
    .speech-bubble {
      position: relative;
      background-color: #FFF;

      border-radius: 20px;
      filter: drop-shadow(0 5px 10px #CCC);

      padding: 20px;

      &:after {
        content: '';

        position: absolute;
        bottom: 0;
        left: 50%;

        width: 0;
        height: 0;

        border: 20px solid transparent;
        border-top-color: #FFF;
        border-bottom: 0;
        border-left: 0;

        filter: drop-shadow(0 5px 10px #CCC);

        margin-left: -10px;
        margin-bottom: -20px;
      }
    }
</style>
