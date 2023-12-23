<template>
  <div class="a-ozaria">
    <div class="content">
      <div class="info">
        <div class="frame">
          <img
            class="group"
            alt="Group"
            src="/images/pages/codequest/frame/full-week.svg"
          >
          <p class="title">
            <span class="text-wrapper">International: </span>
            <span class="span">FULL WEEK</span>
          </p>
        </div>
        <p class="text">
          The complete experience including all three hackathon days, multiple university campus experiences and two
          days of San Francisco and Silicon Valley immersion.
        </p>
      </div>
      <div class="text-button-link">
        <div class="flexcontainer">
          <p class="div">
            <span class="text-wrapper-2">
              Pricing: $ 10,000
              <br>
            </span>
          </p>
          <p class="div">
            <span class="text-wrapper-3">For our </span>
            <span class="text-wrapper-4">international participants</span>
            <span class="text-wrapper-3">
              coming from outside the US
              <br>
            </span>
          </p>
          <p class="div">
            <span class="text-wrapper-3">Includes air-travel and accommodations</span>
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AOzaria'
}
</script>

<style scoped lang="scss">
.a-ozaria {
  box-shadow: 0px 0px 22px 0px rgba(0, 0, 0, 0.15);
  background: linear-gradient(100deg, #F9F9FF 0%, #FFF 100%);
  border-radius: 24px;
  align-items: flex-start;
  display: flex;
  flex-direction: column;
  position: relative;
  flex:1;
}

.a-ozaria .content {
  align-items: center;
  display: inline-flex;
  flex: 0 0 auto;
  flex-direction: column;
  gap: 20px;
  padding: 40px 50px;
  position: relative;
  height: 100%;
  min-height: 350px;
}

.a-ozaria .info {
  align-items: flex-start;
  align-self: stretch;
  display: flex;
  flex: 0 0 auto;
  flex-direction: column;
  gap: 12px;
  padding: 4px 0px 0px;
  position: relative;
  width: 100%;
}

.a-ozaria .frame {
  align-items: center;
  display: inline-flex;
  flex: 0 0 auto;
  gap: 30px;
  position: relative;
}

.a-ozaria .group {
  height: 40px;
  position: relative;
  width: 40px;
}

.a-ozaria .title {
  color: transparent;
  font-family: "Plus Jakarta Sans-Bold", Helvetica;
  font-size: 20px;
  font-weight: 700;
  letter-spacing: 0;
  line-height: 36px;
  position: relative;
  width: fit-content;
}

.a-ozaria .text-wrapper {
  color: #0a2239;
}

.a-ozaria .span {
  color: #4799A9;
}

.a-ozaria .text {
  color: var(--dark);
  font-family: "Plus Jakarta Sans-Regular", Helvetica;
  font-size: 18px;
  font-weight: 400;
  letter-spacing: 0;
  line-height: 24px;
  position: relative;
}

.a-ozaria .text-button-link {
  align-items: center;
  align-self: stretch;
  display: flex;
  flex: 0 0 auto;
  gap: 8px;
  padding: 6px 0px;
  width: 100%;
  position: absolute;
  bottom: 40px;
  @media (max-width: 991px) {
    position: relative;
    bottom: auto;
  }
}

.a-ozaria .flexcontainer {
  align-items: flex-start;
  display: inline-flex;
  flex-direction: column;
  gap: 1px;
}

.a-ozaria .div {
  align-self: stretch;
  color: transparent;
  font-family: "Plus Jakarta Sans-Medium", Helvetica;
  font-size: 14px;
  font-weight: 400;
  letter-spacing: 0;
  line-height: 20px;
  position: relative;
}

.a-ozaria .text-wrapper-2 {
  color: #4799A9;
  font-weight: 500;
}

.a-ozaria .text-wrapper-3 {
  color: #6b7280;
  font-family: "Plus Jakarta Sans-Regular", Helvetica;
}

.a-ozaria .text-wrapper-4 {
  color: #111928;
  font-family: "Plus Jakarta Sans-Regular", Helvetica;
}
</style>
