<template>
  <div class="sidebar">
    <div class="sidebar__top">
      <div class="sidebar__child">
        <select name="child-select" id="sidebar__child__select-id" class="sidebar__child__select">
          <optgroup>
            <option
              v-for="(child, index) in children"
              :key="index"
              :value="child.broadName"
              class="sidebar__child__option"
              :selected="index === 0">
              {{ child.broadName }}
            </option>
            <option value="No other children added" class="sidebar__child__option" disabled v-if="children.length > 0">No other children added</option>
            <option value="No children added" class="sidebar__child__option" disabled v-if="children.length === 0" :selected="children.length === 0">No children added</option>
          </optgroup>
        </select>
      </div>
      <ul class="sidebar__tabs">
        <li class="sidebar__tabs__item">
          <img src="/images/pages/parents/dashboard/icon-productivity.svg" alt="Progress" class="sidebar__tabs__img">
          <span class="sidebar__tabs__name">Progress</span>
        </li>
        <li class="sidebar__tabs__item">
          <img src="/images/pages/parents/dashboard/icon-summary.svg" alt="Summary" class="sidebar__tabs__img">
          <span class="sidebar__tabs__name">Summary</span>
        </li>
        <li class="sidebar__tabs__item">
          <img src="/images/pages/parents/dashboard/icon-online-classes.svg" alt="Online Classes" class="sidebar__tabs__img">
          <span class="sidebar__tabs__name">Online Classes</span>
        </li>
        <li class="sidebar__tabs__item">
          <img src="/images/pages/parents/dashboard/icon-ai-league.svg" alt="AI League" class="sidebar__tabs__img">
          <span class="sidebar__tabs__name">AI League</span>
        </li>
      </ul>
      <div class="sidebar__add-child">
        <button
          class="sidebar__add-child__btn"
          @click.prevent="onAddAnotherChild"
        >
          Add another child
        </button>
      </div>
    </div>
    <div class="sidebar__bottom">
      <div class="sidebar__bottom__item">Parent toolkit</div>
      <div class="sidebar__bottom__item">Account</div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'SidebarComponent',
  props: {
    children: {
      type: Array,
      required: true
    }
  },
  methods: {
    onAddAnotherChild () {
      this.$emit('onAddAnotherChild')
    }
  }
}
</script>

<style scoped lang="scss">
.sidebar {
  grid-column: sidebar-start / sidebar-end;
  grid-row: 1 / -1;
  border: 1px solid #E6E6E6;
  box-shadow: 0 4px 4px rgba(0, 0, 0, 0.06);
  height: 80vh;

  display: flex;
  flex-direction: column;
  justify-content: space-between;

  &__top {
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  &__child {
    align-self: stretch;
    padding-bottom: 1rem;

    &__select {
      width: 100%;
      padding: 1rem;

      font-size: 2rem;
      line-height: 3rem;
      letter-spacing: 0.444444px;

      border: 1px solid #E6E6E6;
      box-shadow: inset 0px -2px 6px rgba(0, 0, 0, 0.15);
    }
  }

  &__tabs {
    list-style: none;
    padding: 0;

    &__item {
      display: flex;
      align-items: center;
      justify-content: flex-start;

      padding: 1rem;
    }

    &__name {
      font-size: 1.8rem;
      line-height: 2.2rem;
      font-weight: 400;

      margin-left: 1rem;
    }

    &__img {
      width: 2.1rem;
      height: 2rem;
    }
  }

  &__add-child {
    &__btn {
      background: #F7D047;
      border-radius: 1px;

      font-weight: 600;
      font-size: 1.6rem;
      line-height: 1.7rem;
      letter-spacing: 0.333333px;
      color: #131B25;

      padding: .5rem 1.5rem;
      border-color: #ffffff;
    }
  }

  &__bottom {
    display: flex;
    align-items: flex-start;
    flex-direction: column;
    padding-bottom: 5rem;

    &__item {
      align-self: stretch;
      border: 1px solid #E6E6E6;

      font-weight: 600;
      font-size: 1.8rem;
      line-height: 3rem;

      display: flex;
      align-items: center;
      letter-spacing: 0.444444px;
      text-transform: uppercase;
      color: #545B64;
      padding: .5rem;
    }
  }
}
</style>
