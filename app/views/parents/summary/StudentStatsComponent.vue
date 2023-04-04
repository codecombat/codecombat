<template>
  <div class="stats">
    <div class="stats__trophy">
      <img src="/images/pages/parents/dashboard/bronze-trophy.png" alt="Bronze trophy" />
    </div>
    <div class="stat stats__hours">
      <div class="stats__number">1</div>
      <div class="stats__text">Hours Played</div>
    </div>
    <div class="stat stats__levels">
      <div class="stats__number">1</div>
      <div class="stats__text">Levels Completed</div>
    </div>
    <div class="stat stats__loc">
      <div class="stats__number">1</div>
      <div class="stats__text">Lines of Code Written</div>
    </div>
    <div class="stat stats__concepts">
      <div class="stats__number">1</div>
      <div class="stats__text">Concepts Mastered</div>
    </div>
    <div class="stats__trophy">
      <img src="/images/pages/parents/dashboard/bronze-trophy.png" alt="Bronze trophy" />
    </div>
  </div>
</template>

<script>
export default {
  name: 'StudentStatsComponent'
}
</script>

<style scoped lang="scss">
.stats {
  display: flex;
  align-items: center;
  width: 100%;
  justify-content: space-evenly;
  flex-wrap: wrap;
  padding-bottom: 1rem;

  .stat {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
  }

  &__number {
    font-family: 'Space Mono', sans-serif;
    font-style: normal;
    font-weight: 700;
    font-size: 7rem;
    line-height: 10.4rem;
    color: #355EA0;
  }

  &__text {
    font-weight: 600;
    font-size: 1.4rem;
    line-height: 1.8rem;
    letter-spacing: 0.4px;
    text-transform: uppercase;
    color: #545B64;
    text-align: center;
  }

  &:after {
    content: "";
    height: 5px;
    display: block;
    width: 90%;
    background: linear-gradient(59.36deg, #D1B147 -5.07%, #D1B147 16.64%, #F7D047 93.04%, #F7D047 103.46%);
    margin-top: 2rem;
  }
}
</style>
