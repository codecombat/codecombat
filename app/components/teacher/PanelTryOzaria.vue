<script>
import OzariaCTA from './OzariaCTA'

export default Vue.extend({
  components: {
    OzariaCTA
  }
})
</script>

<template>
  <div class="container">
    <div class="gradient">
      <div id="panel-try-ozaria">
        <div class="top-gradient-border"></div>
        <div>
          <h3>
            {{ $t('teacher.ozaria_intro') }}
          </h3>
          <img class="oz-logo" alt="Ozaria logo" src="/images/pages/home/logo_ozaria.png"/>
        </div>
        <OzariaCTA />
      </div>
      <a class="try-oz-btn" href="https://ozaria.com/teachers" rel="external" target="_blank">
        {{ $t("teacher.try_ozaria_free") }}
      </a>
    </div>
  </div>
</template>

<style scoped>
#panel-try-ozaria {
  display: flex;
  flex-direction: row;

  padding: 34px 0;
  border-radius: 20px 20px 0 0;
  border-bottom: none;
  position: relative;

  background: white;
  background: url(/images/ozaria/modal/encouragement-modal/SpritLandReveal_Gradient.png) left bottom no-repeat, url(/images/ozaria/modal/encouragement-modal/Hero.png) left bottom no-repeat; /* Fallback */
  background: url(/images/ozaria/modal/encouragement-modal/Hero.png) 22px bottom no-repeat, url(/images/ozaria/modal/encouragement-modal/SpritLandReveal_Gradient.png) left bottom no-repeat, linear-gradient(66.45deg, #FFFEF0 15.94%, #FFFDEA 29.45%, #FFF8CF 46.45%, #FDF7D7 76.99%, #FFFCE9 83.48%);

}

.gradient {
  background-color: #F7D047;
  background: linear-gradient(59.36deg, #D1B147 -5.07%, #D1B147 16.64%, #F7D047 93.04%, #F7D047 103.46%);
  padding: 4px;
  border-radius: 20px;

  margin-bottom: 20px;
}

a.try-oz-btn {
    text-align: center;
    width: 100%;
    display: block;

    border-radius: 0 0 20px 20px;

    font-family: Open Sans;
    font-style: normal;
    font-weight: bold;
    font-size: 24px;
    line-height: 33px;
    color: black;
    text-transform: uppercase;

    padding: 16px 0;
}

#panel-try-ozaria > div {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;

  flex: 1;
}

#panel-try-ozaria > div:nth-of-type(2) {
  justify-content: start;
  justify-content: flex-start;
}

div.top-gradient-border {
  position: absolute;
}

h3 {
  font-family: Open Sans;
  font-style: normal;
  font-weight: bold;
  font-size: 24px;
  line-height: 30px;
  text-align: center;

  color: #232323;
  margin: 30px 70px 16px;
}

img {
  max-height: 78px;
}
</style>