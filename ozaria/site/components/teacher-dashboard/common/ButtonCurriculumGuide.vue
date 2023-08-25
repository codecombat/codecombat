<template>
  <button
    class="dusk-btn"
    @click="$emit('click')"
  >
    <div id="Curriculum" />
    <span>{{ $t('teacher_dashboard.curriculum_guide') }}</span>
  </button>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";
@import "dusk-button";

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

</style>
