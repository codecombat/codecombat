<template>
  <div class="library">
    <div class="library__name">
      Arapahoe
    </div>
    <div class="library__desc">
      Welcome to your dashboard, <span class="library__desc__name">ARAPAHOE LIBRARIES!</span> Give your members access to the most engaging way to learn coding!
    </div>
    <sidebar-component />
    <library-data-component />
  </div>
</template>

<script>
import SidebarComponent from './components/SidebarComponent'
import LibraryDataComponent from './components/LibraryDataComponent'

export default {
  name: 'MainView',
  components: {
    SidebarComponent,
    LibraryDataComponent
  }
}
</script>

<style scoped lang="scss">
@import "./css-mixins/variables";

.library {
  font-size: 62.5%; // 10px/16px = 62.5% -> 1rem = 10px
  font-family: Work Sans, "Open Sans", sans-serif;

  display: grid;
  grid-template-columns: [sidebar-start] 25rem [sidebar-end main-content-start] repeat(3, [main-start] 1fr [main-end]) [main-content-end];
  grid-template-rows: 7rem 1fr;

  &__name {
    grid-column: sidebar-start / sidebar-end;

    background: $color-yellow-1;
    box-shadow: 0px -4px 2rem 0px rgba(0, 0, 0, 0.20);
    text-transform: uppercase;
    text-align: center;

    color: $color-blue-2;
    font-feature-settings: 'clig' off, 'liga' off;
    font-size: 1.8rem;
    font-style: normal;
    font-weight: 600;
    line-height: 2.4rem; /* 133.333% */
    letter-spacing: 0.444px;

    padding: 2rem;
  }

  &__desc {
    grid-column: main-content-start / main-content-end;

    background: $color-blue-1;
    color: $color-yellow-2;
    font-feature-settings: 'clig' off, 'liga' off;
    font-size: 1.4rem;
    font-style: normal;
    font-weight: 700;
    line-height: 2.4rem; /* 171.429% */
    letter-spacing: 0.44px;

    &__name {
      color: $color-white;
      text-transform: uppercase;
    }

    padding: 2rem;
  }
}
</style>
