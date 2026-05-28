<template>
  <div class="discover-more">
    <div class="head container">
      <div class="icon">
        <img
          alt=""
          src="/images/pages/payment/discover.png"
        >
      </div>
      <div class="titles">
        <div class="title">
          {{ $t('payments.discover_more_title') }}
        </div>
        <div class="desc">
          {{ $t('payments.discover_more_desc') }}
        </div>
      </div>
    </div>
    <div class="cards">
      <box-panel
        :items="cards"
        columns="3"
      />
    </div>
  </div>
</template>

<script>
import { getJuniorUrl } from 'core/utils'
import BoxPanel from 'app/components/common/elements/BoxPanel.vue'
export default {
  name: 'DiscoverMore',
  components: {
    BoxPanel,
  },
  props: {
    location: {
      type: String,
      default: 'ManageBillingView',
    },
  },
  computed: {
    cards () {
      return [
        // junior
        {
          title: this.$t('new_premium.junior_title'),
          text: this.$t('new_premium.junior_text_short'),
          link: getJuniorUrl(),
          linkText: this.$t('home_v3.try_it_now'),
          image: '/images/pages/premium/tiles/pbox_1.webp',
          linkEvent: this.track,
        },
        // codecombat
        {
          title: this.$t('parents_v2.codecombat_title'),
          text: this.$t('new_premium.codecombat_text_short'),
          link: 'https://codecombat.com/play',
          linkText: this.$t('home_v3.try_it_now'),
          image: '/images/pages/premium/tiles/pbox_2.webp',
          linkEvent: this.track,
        },
        // esports
        {
          title: this.$t('parents_v2.ai_league_sports_title'),
          text: this.$t('new_premium.ai_league_text_short'),
          link: 'https://codecombat.com/league',
          linkText: this.$t('home_v3.try_it_now'),
          image: '/images/pages/parents/tiles/pbox_3.webp',
          linkEvent: this.track,
        },
        // ccw
        {

          title: this.$t('parents_v2.codecombat_worlds_title'),
          text: this.$t('new_premium.codecombat_worlds_text_short'),
          image: '/images/pages/parents/tiles/pbox_4.webp',
          link: 'https://codecombat.com/roblox',
          linkText: this.$t('home_v3.try_it_now'),
          linkEvent: this.track,
        },
        // hackstack
        {
          title: this.$t('parents_v2.ai_hackstack_title'),
          text: this.$t('new_premium.ai_hackstack_text_short'),
          image: '/images/pages/premium/tiles/pbox_5.webp',
          link: 'https://codecombat.com/hackstack/',
          linkText: this.$t('home_v3.try_it_now'),
          linkEvent: this.track,
        },
        // subscription inlcudes
        {
          title: this.$t('new_premium.subscription_includes_title'),
          lists: [
            {
              listType: 'check',
              text: this.$t('new_premium.subscription_includes_1'),
            },
            {
              listType: 'check',
              text: this.$t('new_premium.subscription_includes_2'),
            },
            {
              listType: 'check',
              text: this.$t('new_premium.subscription_includes_3'),
            },
            {
              listType: 'check',
              text: this.$t('new_premium.subscription_includes_4'),
            },
            {
              listType: 'check',
              text: this.$t('new_premium.subscription_includes_5'),
            },
          ],
        },
      ]
    },
  },
  methods: {
    track (link) {
      window.tracker?.trackEvent(`click link to ${link} from ${this.location}`)
    },
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";
.head {
  display: flex;
  margin-bottom: 20px;

  .title {
    color: $dark-grey;
    font-family: "Plus Jakarta Sans-Bold", Helvetica;
    font-size: 20px;
    font-weight: 700;
    letter-spacing: 0;
    line-height: 20px;
  }
  .desc {
    font-size: 14px;
    line-height: 16px;
  }
  .icon {
    margin-right: 10px;
    img {
      width: 33px;
    }
  }
}
.cards {
  ::v-deep {
    .row {
      .box {
        height: 270px;
        width: 250px !important;

        .box__div {
          margin: 4px;
          padding: 8px;
          gap: unset;

          .info {
            gap: 2px;

            &.no-main-image {
              gap: 20px;

              .title {
                margin-top: 10px;
              }
            }

            .title {
              font-size: 16px;
            }
            span {
              font-size: 12px;
              line-height: 16px;
            }
            .learn-more-buttons-container {
              font-size: 12px;
            }

            .list-items {
              font-size: 12px;
              line-height: 14px;

              &:last-child {
                margin-top: unset;
                margin-bottom: unset;
              }
            }
          }
        }
      }
    }
  }
}
</style>