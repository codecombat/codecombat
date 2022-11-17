<script>
  export default {
    props: {
      locked: {
        type: Boolean,
        default: false
      }
    }
  }
</script>

<template>
  <button
    :class="locked ? 'locked' : null"
    :disabled="locked"
    @click="$emit('click')"
  >
    <div
      id="PlayChapter"
    />
    <span>{{ $t('teacher_dashboard.play_chapter') }}</span>
  </button>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#PlayChapter {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_UnitMap.svg);
  height: 23px;
  width: 19px;
  display: inline-block;
  background-repeat: no-repeat;
  background-position: center;
  background-size: 100% 100%;
  margin-right: 7px;
}

.locked #PlayChapter {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_UnitMapLocked.svg);
}

button {
  background-color: $twilight;
  border-radius: 4px;
  border-width: 0;
  text-shadow: unset;
  font-weight: bold;
  @include font-p-3-small-button-text-black;
  color: $moon;
  font-size: 14px;
  line-height: 16px;
  font-weight: 600;
  background-image: unset;

  &:hover {
    background-color: #355ea0;
    transition: background-color .35s;
  }

  display: flex;
  height: 33px;
  padding: 0 15px;
  justify-content: center;
  align-items: center;

  &.locked {
    background: #adadad;
    cursor: default;
    color: $pitch;
  }
}
</style>
