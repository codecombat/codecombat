<script>
  export default {
    props: {
      link: {
        type: String,
        required: true
      },
      locked: {
        type: Boolean,
        default: false
      }
    }
  }
</script>
<template>
  <a
    v-if="!locked"
    :href="link"
    target="_blank"
    rel="noopener"
  >
    <button>
      <div id="IconLessonSlides" /><span>Lesson Slides</span>
    </button>
  </a>
  <button v-else :disabled="true" class="locked">
    <div id="IconLessonSlides" /><span>Lesson Slides</span>
  </button>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

a {
  text-decoration: none;
  display: inline-block
}

button {
  background-color: $dusk;
  border-radius: 4px;
  border-width: 0;
  @include font-p-3-small-button-text-black;
  color: $pitch;
  font-size: 14px;
  line-height: 16px;

  &:hover {
    background-color: $dusk-dark;
    transition: background-color .35s;
  }

  display: flex;
  height: 35px;
  padding: 0 15px;
  justify-content: center;
  align-items: center;

  &.locked {
    background-color: #adadad;
  }
}

#IconLessonSlides {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconComputer.svg);
  height: 23px;
  width: 18px;
  display: inline-block;
  background-repeat: no-repeat;
  background-position: center;
  background-size: 100% 100%;

  margin-right: 7px;
}
</style>
