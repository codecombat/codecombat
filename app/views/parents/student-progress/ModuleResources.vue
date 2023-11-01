<template>
  <div class="resources">
    <div class="resources__text">Resources</div>
    <div class="resources__btns">
      <a
        v-if="canViewSlides"
        :href="lessonSlidesUrl"
        target="_blank"
        class="resource resources__slides resources__link"
      >
        <span class="resource__text">Lesson Slides</span>
        <img src="/images/ozaria/teachers/dashboard/svg_icons/IconComputer.svg" alt="Slides icon" class="resource__icon resource__slides">
      </a>
      <div
        v-else
        class="resource resources__slides"
        @click="onLessonSlidesClicked"
      >
        <span class="resource__text">Lesson Slides</span>
        <img src="/images/ozaria/teachers/dashboard/svg_icons/IconComputer.svg" alt="Slides icon" class="resource__icon resource__slides">
      </div>
<!--      <div class="resource resources__project">-->
<!--        <span class="resource__text">Project Rubric</span>-->
<!--        <img src="/images/ozaria/teachers/dashboard/svg_icons/IconRubric.svg" alt="Project Rubric icon" class="resource__icon resource__project">-->
<!--      </div>-->
<!--      <div class="resource resources__exemplar">-->
<!--        <span class="resource__text">Exemplar Project</span>-->
<!--        <img src="/images/ozaria/teachers/dashboard/svg_icons/IconExemplarProject.svg" alt="Example project icon" class="resource__icon resource__exemplar">-->
<!--      </div>-->
    </div>
  </div>
</template>

<script>
export default {
  name: 'ModuleResources',
  props: {
    lessonSlidesUrl: {
      type: String,
      default: ''
    },
    isFree: {
      type: Boolean,
      default: false
    }
  },
  methods: {
    onLessonSlidesClicked () {
      console.log('lessonSlide', this.lessonSlidesUrl)
      const url = this.lessonSlidesUrl
      if (this.isFree) {
        window.location = url
        return
      }
      if (me.isPaidOnlineClassUser()) {
        if (!url) {
          noty({
            text: 'Sorry, lesson not available for this campaign currently',
            type: 'information',
            timeout: 5000,
            layout: 'center'
          })
        } else {
          window.location = url
        }
      } else {
        noty({
          text: 'Only available to users with online classes subscription',
          type: 'information',
          timeout: 5000,
          layout: 'center'
        })
      }
    }
  },
  computed: {
    canViewSlides () {
      if (this.isFree || me.isPaidOnlineClassUser()) return true
      return false
    }
  }
}
</script>

<style scoped lang="scss">
@import "../css-mixins/variables";

.resources {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  flex-direction: column;
  padding: 2rem;

  &__text {
    font-weight: 500;
    font-size: 1.6rem;
    line-height: 3rem;
    letter-spacing: 0.444444px;
    text-transform: uppercase;

    border-bottom: 1px solid $color-grey-1;
    padding: .5rem;
    width: 100%;
    align-self: flex-start;
  }

  &__btns {
    display: flex;
    flex-direction: column;
  }

  &__slides {
    cursor: pointer;
  }

  &__link {
    color: inherit;
    text-decoration: none;
  }
}

.resource {
  border: 1px solid $color-twilight;
  border-radius: 8px;
  padding: .5rem 2rem;
  position: relative;

  &:not(:last-child) {
    margin-bottom: 2rem;
  }

  &:first-child {
    margin-top: 2rem;
  }

  &__text {
    font-weight: 600;
    font-size: 1.6rem;
    line-height: 1.7rem;
    letter-spacing: 0.333333px;
  }

  &__icon {
    position: absolute;
    top: -20%;
    right: -10%;

    width: 3rem;
    height: 2rem;
  }

  &__exemplar, &__project {
    background-color: $color-yellow-1;
  }

  &__slides {
    background-color: $color-green-1;
  }
}
</style>
