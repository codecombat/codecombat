<template>
  <header class="header">
    <div class="header__item header__item--1">
      <div class="header__content">
        <p class="header__title">Hello, {{ name }}</p>
        <p class="header__subtitle">Welcome to your parent dashboard.</p>
      </div>
      <div class="header__products">
        <div class="header__product">
          <img src="/images/pages/parents/dashboard/codecombat-logo.svg" alt="CodeCombat logo" class="header__logos">
        </div>
        <div class="header__product">
          <img src="/images/pages/parents/dashboard/ozaria-logo.svg" alt="Ozaria logo" class="header__logos">
        </div>
        <div class="header__product">
          <img src="/images/pages/parents/dashboard/roblox-logo.svg" alt="Roblox logo" class="header__logos">
        </div>
      </div>
    </div>
    <div class="header__item header__item--2">
      <div class="">
        <div class="header__item__img-parent">
          <img src="/images/pages/parents/dashboard/alejandro.png" alt="CodeCombat character" class="header__item__img">
        </div>
        <div class="header__item__data">
          <ul class="header__sell-info">
            <li class="header__sell-item">Full access to CodeCombat and Ozaria</li>
            <li class="header__sell-item">Unlock 500+ levels</li>
            <li class="header__sell-item">Access to all learning resources</li>
          </ul>
          <button class="header__premium-btn header__btn">Get Premium</button>
        </div>
      </div>
      <div class="header__item--line"></div>
      <div class="">
        <div class="header__item__data">
          <ul class="header__sell-info">
            <li class="header__sell-item">1:1 classes with an expert teacher</li>
            <li class="header__sell-item">Bonus activities & projects</li>
            <li class="header__sell-item">Monthly progress updates</li>
          </ul>
          <button class="header__online-class-btn header__btn">Try a Free Online Class</button>
        </div>
        <div class="header__item__img-parent">
          <img src="/images/pages/parents/dashboard/illia-reading.png" alt="CodeCombat character" class="header__item__img">
        </div>
      </div>
    </div>
  </header>
</template>

<script>
export default {
  name: 'HeaderComponent',
  data () {
    return {
      name: me.broadName()
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";

.header {
  grid-column: main-content-start / main-content-end;

  background: #355EA0;
  border: 1px solid #E6E6E6;
  box-shadow: inset 0px -2px 10px rgba(0, 0, 0, 0.15);

  display: flex;

  &__products {
    display: flex;

    @media (max-width: $screen-lg) {
      flex-direction: column;
    }
  }

  &__product {
    background: #5DB9AC;
    border: 1px solid #5DB9AC;
    box-shadow: 4px 0 7px rgba(0, 0, 0, 0.2), 0px -2px 5px rgba(0, 0, 0, 0.1);

    margin-left: 1rem;
    margin-right: 1rem;

    border-top-left-radius: 5px;
    border-top-right-radius: 5px;

    padding: 2px 1rem;
    cursor: pointer;

    &:not(:last-child) {
      @media (max-width: $screen-lg) {
        margin-bottom: 1rem;
      }
    }
  }

  &__item {
    padding-top: 1rem;
    &--1 {
      display: flex;
      justify-content: space-between;
      flex-direction: column;

      margin-right: auto;
    }

    &--2 {
      display: flex;
      align-items: center;

      & > * {
        display: flex;
        padding: 1rem;
      }
    }

    &--line {
      &::before,
      &::after {
        content: "";
        height: 100px;
        width: 1px;
        display: block;
        background-color: #D8D8D8;
      }
    }

    &__data {
      display: flex;
      flex-direction: column;
      align-items: flex-start;
    }

    &__img {
      width: 100%;
      height: 9rem;
    }

    &__parent-img {
      height: 9rem;
    }
  }

  &__content {
    padding-left: 1rem;
    color: #FFFFFF;
    display: flex;
    flex-direction: column;

    p {
      margin-bottom: 0;
    }
  }

  &__title {
    font-size: 2rem;
    line-height: 3rem;
    letter-spacing: 0.444444px;

    color: inherit;
  }

  &__subtitle {
    font-size: 1.4rem;
    line-height: 1.8rem;
    letter-spacing: 0.266667px;

    color: inherit;
  }

  &__sell-info {
    font-weight: 500;
    font-size: 1.2rem;
    line-height: 1.6rem;
    letter-spacing: 0.333333px;
    color: #FFFFFF;

    padding-left: 2rem;
  }

  @mixin button-base {
    border-radius: 1px;
    font-weight: 600;
    font-size: 1.4rem;
    line-height: 1.6rem;
    text-align: center;
    letter-spacing: 0.333333px;
    padding: .5rem 1rem;
    margin-left: 1rem;
  }

  &__premium-btn {
    @include button-base;
    background: #F7D047;
    color: #131B25;
    border-color: #ffffff;
  }

  &__online-class-btn {
    @include button-base;
    border: 2px solid #F7D047;
    background: #355EA0;
    color: #F7D047;
  }
}
</style>
