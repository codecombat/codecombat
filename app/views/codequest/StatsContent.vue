<template>
  <div class="content">
    <div class="title">
      {{ $t('codequest_page.how_it_works') }}
    </div>
    <div class="data-text">
      <ContentBlock
        :title="$t('codequest_page.apply')"
        :supporting-text="$t('codequest_page.apply_time')"
        :steps="[
          $t('codequest_page.apply_steps_1'),
          $t('codequest_page.apply_steps_2'),
        ]"
        image-src="/images/pages/codequest/stats/confirm.svg"
        number="1"
      />
      <ContentBlock
        :title="$t('codequest_page.confirm')"
        :supporting-text="$t('codequest_page.confirm_time')"
        :steps="[
          $t('codequest_page.confirm_steps_1'),
          $t('codequest_page.confirm_steps_2'),
          $t('codequest_page.confirm_steps_3'),
          $t('codequest_page.confirm_steps_4'),
        ]"
        image-src="/images/pages/codequest/stats/confirm.svg"
        number="2"
      />
      <ContentBlock
        :title="$t('codequest_page.travel')"
        :supporting-text="$t('codequest_page.travel_time')"
        :steps="[
          $t('codequest_page.travel_steps_1'),
          $t('codequest_page.travel_steps_2'),
          $t('codequest_page.travel_steps_3'),
        ]"
        image-src="/images/pages/codequest/stats/travel.svg"
        number="3"
      />
    </div>
  </div>
</template>

<script>
import ContentBlock from './StatsContentBlock.vue'

export default {
  name: 'ContentComponent',
  components: {
    ContentBlock
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
.content {
  align-items: center;
  display: flex;
  flex-direction: column;
  gap: 80px;
  justify-content: center;
  padding: 100px 0px;
  position: relative;
  border-radius: 24px;
  background: #F0FDFD;
  box-shadow: 0px 4px 22px 0px rgba(0, 0, 0, 0.15);
}

.content .title {
  align-self: stretch;
  color: #4799A9;
  font-family: "Plus Jakarta Sans-Medium", Helvetica;
  font-size: 36px;
  font-weight: 500;
  letter-spacing: 0;
  line-height: 45px;
  margin-top: -1px;
  position: relative;
  text-align: center;
}

.content .data-text {
  align-items: flex-start;
  align-self: stretch;
  display: flex;
  gap: 40px;
  justify-content: center;
  position: relative;
  padding: 0 100px;
  width: 100%;
}

@media (max-width: $screen-md-max) {
  .content .data-text {
    flex-direction: column;
    align-items: center;
  }
}
</style>
