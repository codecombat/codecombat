<template>
  <div class="lprogress">
    <div class="lprogress__intro">
      <div class="lprogress__intro__title">
        Levels progress
      </div>
      <div class="lprogress__intro__options">
        <div class="lprogress__intro__option">
          <div class="lprogress__intro__dot not-started-dot"></div>
          <div class="lprogress__intro__text">Not Started</div>
        </div>
        <div class="lprogress__intro__option">
          <div class="lprogress__intro__dot in-progress-dot"></div>
          <div class="lprogress__intro__text">In progress</div>
        </div>
        <div class="lprogress__intro__option">
          <div class="lprogress__intro__dot complete-dot"></div>
          <div class="lprogress__intro__text">Complete</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
// import ModuleRow from '../../../../ozaria/site/components/teacher-dashboard/BaseCurriculumGuide/components/ModuleRow'
export default {
  name: 'LevelprogressDataComponent'
  // components: {
  //   ModuleRow
  // }
}
</script>

<style scoped lang="scss">
.lprogress {
  padding: 2rem;
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
      background: #FFFFFF;
      border-radius: 1rem;
      margin-bottom: .5rem;
    }
  }
}

.not-started-dot {
  border: 1.5px solid #C8CDCC;
}

.in-progress-dot {
  background-color: #1ad0ff;
}

.complete-dot {
  background-color: #2dcd38;
}
</style>
