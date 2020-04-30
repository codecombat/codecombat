<template>
  <button><div id="Curriculum" /><span>Curriculum Guide</span></button>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#Curriculum {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Curriculum.svg);
  height: 20px;
  width: 16px;
  display: inline-block;
  background-repeat: no-repeat;
  background-position: center;

  margin-right: 10px;
}

button {
  background-color: $dusk;
  color: $pitch;
  border-radius: 1px;
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
