<script>
export default {
  props: {
    doneRegistering: {
      type: Boolean,
      required: true
    },
    isClanCreator: {
      required: true
    },
    onHandleJoinCTA: {
      required: true
    }
  }
}
</script>

<template>
  <div class="section-first-cta">
    <div class="text-code-section">
      <img class="img-responsive" src="/images/pages/league/text_code.svg" width="501" height="147" />
    </div>
    <div class="row flex-row text-center">
      <p
        class="subheader2"
        style="max-width: 800px;"
      >{{ $t('league.summary') }}</p>
    </div>
    <div v-if="!doneRegistering && !isClanCreator()" class="row flex-row text-center xs-m-0">
      <a class="btn btn-large btn-primary btn-moon" @click="onHandleJoinCTA">{{ $t('league.join_now') }}</a>
    </div>
    <div class="text-2021-section section-space">
      <img class="img-responsive" src="/images/pages/league/text_2021.svg" width="501" height="147" />
    </div>
  </div>
</template>

<style lang="scss" scoped>

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