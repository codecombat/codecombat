<script>
export default {
  props: {
    doneRegistering: {
      type: Boolean,
      required: true,
    },
    isClanCreator: {
      required: true,
      type: Function,
    },
    onHandleJoinCTA: {
      required: true,
      type: Function,
    },
    championshipActive: {
      type: Boolean,
      required: true,
    },
  },
}
</script>

<template>
  <div class="section-first-cta">
    <div class="row flex-row text-center">
      <p
        class="subheader2"
        style="max-width: 800px;"
      >
        <!-- eslint-disable vue/no-v-html -->
        <span v-if="championshipActive">
          <span v-html="$t('league.championship_summary', { championshipArena: $t('league.golden_goal'), championshipMonth: $t('calendar.december'), championshipType: $t('league.cup') })" />
        </span>
        <span v-else>
          {{ $t('league.summary') }}
        </span>
      </p>
    </div>
    <div
      v-if="!doneRegistering && !isClanCreator()"
      class="row flex-row text-center xs-m-0"
    >
      <a
        class="btn btn-large btn-primary btn-moon"
        @click="onHandleJoinCTA"
      >{{ $t('league.join_now') }}</a>
    </div>
  </div>
</template>

<style lang="scss" scoped>
p {
  color: white;
}

.text-code-section {
  width: 100%;
  overflow-x: hidden;
  padding: 0 10px;
}

.text-2021-section {
  width: 100%;
  overflow-x: hidden;
  display: flex;
  justify-content: flex-end;
}

.section-first-cta > div {
  max-width: 1820px;
  width:100%;
  padding: 0 70px;
  position: relative;
  z-index: 1;
  margin: 25px 0;
}

@media screen and (max-width: 767px) {
  .text-code-section {
    padding: 0 10px;
  }

  .text-2021-section {
    margin-bottom: auto;
    padding: 0 10px;
  }

  .section-first-cta > div {
    padding: 0px;
  }
}
</style>
