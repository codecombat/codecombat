<template>
  <button @click="$emit('click')">
    <div id="Curriculum" />
    <span>{{ $t('teacher_dashboard.curriculum_guide') }}</span>
  </button>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#Curriculum {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconCurriculumGuide.svg);
  height: 20px;
  width: 20px;
  display: inline-block;
  background-repeat: no-repeat;
  background-position: center;
  background-size: 100% 100%;

  margin-right: 5px;
}

button {
  background-color: $dusk;
  color: $pitch;
  border-radius: 4px;
  border-width: 0;
  text-shadow: unset;
  font-weight: bold;
  @include font-p-3-small-button-text-black;
  background-image: unset;

  &:hover {
    background-color: $dusk-dark;
    transition: background-color .35s;
  }

  display: flex;
  height: 33px;
  padding: 0 17px;
  justify-content: center;
  align-items: center;
}
</style>
