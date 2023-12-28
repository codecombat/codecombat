<template>
  <div class="data">
    <div class="apply">
      <div class="overlap-group">
        <div
          class="text-wrapper"
          :style="`${imageSrc.match(/travel/)?'left: 95px;':''}`"
        >
          {{ number }}
        </div>
        <img
          class="img"
          :alt="title"
          :src="imageSrc"
        >
      </div>
    </div>
    <div class="content-wrapper">
      <div class="div">
        <div class="frame">
          <div class="title-2">
            {{ title }}
          </div>
          <div class="supporting-text">
            {{ supportingText }}
          </div>
        </div>
        <div class="flexcontainer">
          <p
            v-for="(step, index) in steps"
            :key="index"
            class="text"
          >
            <span class="span">{{ step }}</span>
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ContentBlock',
  props: ['title', 'supportingText', 'steps', 'imageSrc', 'number']
}
</script>

<style scoped lang="scss">
.data {
    align-items: flex-start;
    display: inline-flex;
    flex-direction: column;
    gap: 30px;
    flex: 1;
    justify-content: center;
    margin-left: -5px;
    position: relative;
}

.apply {
    position: relative;
}

.overlap-group {
    height: 111px;
    position: relative;
    top: 15px;
}

.text-wrapper {
    color: #4799A9;
    font-family: "Port Lligat Slab-Regular", Helvetica;
    font-size: 40px;
    font-weight: 400;
    left: 129px;
    letter-spacing: 0;
    line-height: 45px;
    position: absolute;
    top: -1px;
    white-space: nowrap;
    width: 18px;
    width: 70px;
    height: 70px;
    text-align: center;
    display: flex;
    justify-content: center;
    background: #BAF5F7;
    align-items: center;
    border-radius: 70px;
    left: 80px;
}

.img {
    height: 111px;
    left: 0;
    position: absolute;
    top: 0;
    width: 120px;
}

.content-wrapper {
    align-items: flex-start;
    display: inline-flex;
    flex: 0 0 auto;
    flex-direction: column;
    position: relative;
}

.div {
    align-items: flex-start;
    display: inline-flex;
    flex: 0 0 auto;
    flex-direction: column;
    gap: 30px;
    justify-content: center;
    position: relative;
}

.frame {
    align-items: flex-start;
    display: inline-flex;
    flex-direction: column;
    gap: 8px;
    height: 77px;
    justify-content: center;
    position: relative;
}

.title-2 {
    color: var(--dark);
    font-family: "Plus Jakarta Sans-Medium", Helvetica;
    font-size: 36px;
    font-weight: 500;
    letter-spacing: 0;
    line-height: 45px;
    margin-top: -1px;
    position: relative;
}

.supporting-text {
    color: #4799A9;
    font-family: "Plus Jakarta Sans-Regular", Helvetica;
    font-size: 18px;
    font-weight: 400;
    letter-spacing: 0;
    line-height: 24px;
    position: relative;

}

.flexcontainer {
    align-items: flex-start;
    display: flex;
    flex-direction: column;
    gap: 30px;

}

.text {
    align-self: stretch;
    color: #000000;
    font-family: "Plus Jakarta Sans-Regular", Helvetica;
    font-size: 18px;
    font-weight: 400;
    letter-spacing: 0;
    line-height: 24px;
    position: relative;
}

.span {
    color: #000000;
    font-family: "Plus Jakarta Sans-Regular", Helvetica;
    font-size: 18px;
    font-weight: 400;
    letter-spacing: 0;
    line-height: 24px;
}
</style>
