<template>
  <div class="sidebar">
    <div class="sidebar__img">
      <img
        src="/images/pages/play/arapahoe-logo.png"
        alt="Library logo"
      />
    </div>
    <div class="sidebar__licenses">
      <div class="sidebar__licenses__container">
        <div class="sidebar__licenses__text sidebar__text">
          Licenses Used:
        </div>
        <div class="sidebar__licenses__tooltip">
          ?
        </div>
      </div>
      <div class="sidebar__licenses__number sidebar__value">
        15
      </div>
    </div>
    <div class="sidebar__renewal">
      <div class="sidebar__renewal__text sidebar__text">
        Renewal Date:
      </div>
      <div class="sidebar__renewal__date sidebar__value">
        17 Apr'93
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'SidebarComponent'
}
</script>

<style scoped lang="scss">
@import "../css-mixins/variables";

.sidebar {
  grid-column: sidebar-start / sidebar-end;

  display: flex;
  flex-direction: column;
  //align-items: center;
  padding: 2rem;
  box-shadow: 0 0 20px 0 rgba(0, 0, 0, 0.20);

  &__img {
    img {
      width: 12rem;
    }
  }

  &__licenses {
    &__container {
      display: flex;
      justify-content: space-between;
    }

    &::after {
      content: "";
      height: 1px;
      background: $color-yellow-1;
      display: block;
      width: 100%;
      margin-top: 1rem;
    }
  }

  &__text {
    font-feature-settings: 'clig' off, 'liga' off;
    font-size: 1.4rem;
    font-style: normal;
    font-weight: 400;
    line-height: 1.8rem; /* 128.571% */
    letter-spacing: 0.4px;
    text-transform: uppercase;
  }

  &__value {
    color: $color-blue-2;
    font-family: Space Mono, sans-serif;
    font-size: 3.5rem;
    font-style: normal;
    font-weight: 700;
    line-height: normal;
  }

  & > div {
    margin-bottom: 4rem;
  }
}
</style>
