<template>
  <div id="ozaria-cta">
    <div class="ozaria-row">
      <img src="/images/ozaria/modal/encouragement-modal/Icon_StandardsAlignment.svg" />
      <div>
        <h4>{{ $t('ozaria_cta.title1') }}</h4>
        <p>{{ $t('ozaria_cta.description1') }}</p>
      </div>
    </div>
    <div class="ozaria-row">
      <img src="/images/ozaria/modal/encouragement-modal/Icon_Turnkey.svg" />
      <div>
        <h4>{{ $t('ozaria_cta.title2') }}</h4>
        <p>{{ $t('ozaria_cta.description2') }}</p>
      </div>
    </div>
    <div class="ozaria-row">
      <img src="/images/ozaria/modal/encouragement-modal/Icon_NewTeacherDashboard.svg" />
      <div>
        <h4>{{ $t('ozaria_cta.title3') }}</h4>
        <p>{{ $t('ozaria_cta.description3') }}</p>
      </div>
    </div>
  </div>
</template>

<style scoped>

#ozaria-cta {
  width:100%;
  height:100%;

  display: flex;
  justify-content: center;
  align-items: center;
  flex-direction: column;
}

.ozaria-row {
  display: flex;
  flex-direction: row;
  align-items: center;
  width: 90%;
  max-width: 520px;
}

.ozaria-row img {
  width: 80px;
  height: 80px;
  margin-right: 30px;
}

.ozaria-row p {
  font-family: Open Sans;
  font-style: normal;
  font-weight: 300;
  font-size: 18px;
  line-height: 25px;
  color: #232323;
}

.ozaria-row h4 {
  font-family: Open Sans;
  font-style: normal;
  font-weight: bold;
  font-size: 22px;
  line-height: 30px;
  color: black;
  margin: 2px 0;
  font-variant: normal;
}
</style>