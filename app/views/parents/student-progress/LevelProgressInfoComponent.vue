<template>
  <div class="lprogress__intro">
    <div class="lprogress__intro__title">
      Levels progress
    </div>
    <div class="lprogress__intro__options">
      <div class="lprogress__intro__option">
        <div class="lprogress__intro__dot not-started-dot" />
        <div class="lprogress__intro__text">
          Not Started
        </div>
      </div>
      <div class="lprogress__intro__option">
        <div class="lprogress__intro__dot in-progress-dot" />
        <div class="lprogress__intro__text">
          In progress
        </div>
      </div>
      <div class="lprogress__intro__option">
        <div class="lprogress__intro__dot complete-dot" />
        <div class="lprogress__intro__text">
          Complete
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'LevelProgressInfoComponent'
}
</script>

<style scoped lang="scss">
@import "../css-mixins/variables";
@import "../css-mixins/common";

.lprogress {
  &__intro {
    display: flex;
    align-items: center;

    &__title {
      font-weight: 500;
      font-size: 1.6rem;
      line-height: 2rem;
      text-transform: uppercase;

      margin-right: auto;
    }

    &__text {
      font-weight: 400;
      font-size: 1rem;
      line-height: 1.1rem;
    }

    &__options {
      display: flex;
    }

    &__option {
      display: flex;
      flex-direction: column;
      align-items: center;

      padding: 1rem;
    }

    &__dot {
      width: 1rem;
      height: 1rem;
      border-radius: 1rem;
      margin-bottom: .5rem;
    }
  }
}
</style>
