<script>
export default {
  props: {
    curriculumUrl: {
      type: String,
      default: ''
    }
  },
  methods: {
    onClick () {
      if (this.curriculumUrl !== '') {
        window.open(this.curriculumUrl, '_blank', 'noreferrer')
        this.$emit('click')
      }
    }
  }
}
</script>

<template>
  <button
    :class="{'disable-hover': curriculumUrl == ''}"
    @click="onClick"
  >
    <div id="IconRubric" />
    <span v-if="curriculumUrl !== ''">{{ $t('teacher_dashboard.curriculum') }}</span>
    <span v-else>{{ $t('teacher_dashboard.coming_soon') }}</span>
  </button>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#IconRubric {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconRubric.svg);
  height: 23px;
  width: 18px;
  display: inline-block;
  background-repeat: no-repeat;
  background-position: center;
  background-size: 100% 100%;

  margin-right: 7px;
}

button {
  background-color: #f7d047;
  border-radius: 4px;
  border-width: 0;
  text-shadow: unset;
  font-weight: bold;
  @include font-p-3-small-button-text-black;
  color: $pitch;
  font-size: 14px;
  line-height: 16px;
  background-image: unset;

  &:hover {
    background-color: #d1b147;
    transition: background-color .35s;
  }

  display: flex;
  height: 33px;
  padding: 0 15px;
  justify-content: center;
  align-items: center;
}

.disable-hover {
  &:hover {
    background-color: #f7d047;
  }
}

</style>
