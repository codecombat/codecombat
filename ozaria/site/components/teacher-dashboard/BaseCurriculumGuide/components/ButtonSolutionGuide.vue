<template>
  <button @click="$emit('click')">
    <div id="IconSolution" /><span>Solution Guide</span>
  </button>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#IconSolution {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconSolution.svg);
  height: 23px;
  width: 18px;
  display: inline-block;
  background-repeat: no-repeat;
  background-position: center;
  background-size: 100% 100%;

  margin-right: 7px;
}

button {
  background-color: $dusk;
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
    background-color: $dusk-dark;
    transition: background-color .35s;
  }

  display: flex;
  height: 33px;
  padding: 0 15px;
  justify-content: center;
  align-items: center;
}
</style>
