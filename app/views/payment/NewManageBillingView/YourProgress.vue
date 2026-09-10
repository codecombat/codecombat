<template>
  <div class="your-progress">
    <div class="head container">
      <div class="icon">
        <img
          alt="your progress icon"
          src="/images/pages/payment/your-progress.png"
        >
      </div>
      <div class="titles">
        <div class="title">
          {{ $t('payments.your_progress_title') }}
        </div>
        <div class="desc">
          {{ $t('payments.your_progress_desc') }}
        </div>
      </div>
    </div>
    <div class="body">
      <div class="sub-title">
        <div /> <!-- grid layout space placeholder -->
        <div class="current-status">
          {{ $t('payments.current_status') }}
        </div>
        <div class="continue">
          {{ $t('common.continue') }}
        </div>
      </div>
      <div
        v-for="stat of stats"
        :key="stat.product"
        class="products"
      >
        <div /> <!-- grid layout space placeholder -->
        <div class="current-status">
          <img :src="iconMap[stat.product]">
          <div class="infos">
            <div class="product-title">
              {{ stat.displayName }}
            </div>
            <div class="product-progress outer-loading-bar">
              <div
                class="inner-loading-bar"
                :style="{ width: `${stat.progress * 120}px` }"
              />
            </div>
            <div class="product-desc">
              {{ stat.desc }}
            </div>
          </div>
        </div>
        <div class="continue">
          <button
            type="button"
            class="continue-btn"
            @click="goto(stat.next)"
          >
            <img
              alt=""
              :src="`/images/pages/payment/NewManageBillingPage/${stat.product}-continue.png`"
            >
            <div>
              <div class="continue-title">
                {{ $t(`payments.${stat.product}_continue_title`) }} →
              </div>
              <div class="continue-desc">
                {{ $t(`payments.${stat.product}_continue_desc`) }}
              </div>
            </div>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'YourProgress',
  components: {
  },
  props: {
    cocoProgress: {
      type: Object,
      required: true,
    },
    aileagueProgress: {
      type: Object,
      required: true,
    },
    hsProgress: {
      type: Object,
      required: true,
    },
  },
  data () {
    return {
      iconMap: {
        codecombat: '/images/pages/home-v2/coco_square_logo.webp',
        hackstack: '/images/pages/hackstack/ai-hs-icon.webp',
        aileague: '/images/pages/league/logo_badge.png',
      },
    }
  },
  computed: {
    stats () {
      return [this.cocoStat, this.aileagueStat, this.hsStat].filter(x => Object.keys(x).length)
    },
    cocoStat () {
      if (Object.values(this.cocoProgress).length) {
        const { levels, total, campaign, campaignName } = this.cocoProgress
        return {
          product: 'codecombat',
          displayName: $.i18n.t('schools_page.codecombat'),
          progress: levels / total,
          desc: $.i18n.t('payments.codecombat_desc_template', {
            levels, total, name: campaignName || campaign,
          }),
          next: `/play/${campaign}`,
        }
      } else {
        return {}
      }
    },
    aileagueStat () {
      if (Object.values(this.aileagueProgress).length) {
        const { myRank, total, slug, name } = this.aileagueProgress
        return {
          product: 'aileague',
          displayName: $.i18n.t('schools_page.ai_league'),
          progress: (total > 1) ? ((total - myRank) / (total - 1)) : 1,
          desc: $.i18n.t('payments.aileague_desc_template', {
            myRank, name: name || slug,
          }),
          next: `/play/ladder/${slug}`,
        }
      } else {
        return {}
      }
    },
    hsStat () {
      if (Object.values(this.hsProgress).length) {
        const { levels, total, campaign, campaignName } = this.hsProgress
        return {
          product: 'hackstack',
          displayName: $.i18n.t('schools_page.ai_hackstack'),
          progress: levels / total,
          desc: $.i18n.t('payments.hs_desc_template', {
            levels, total, name: campaignName || campaign,
          }),
          next: `/ai/play/${campaign}`,
        }
      } else {
        return {}
      }
    },
  },
  methods: {
    goto (link) {
      window.tracker?.trackEvent('ManagePayment View click link from YourProgress', {
        link,
      })
      application.router.navigate(link, { trigger: true })
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

.body {
  display: grid;
  grid-template-columns: 1fr 4fr 4fr;
  grid-template-rows: 1fr;
  align-items: center;
  gap: 12px;

  .sub-title, .products {
    display: contents;
  }

  .sub-title {
    font-weight: 800;
  }

  .products {

    .current-status {
      display: grid;
      grid-template-columns: 1fr 5fr;
      align-items: center;

      img {
        width: 64px;
      }
    }
    .product-title, .continue-title {
      font-weight: 800;
    }

    .product-desc {
      font-size: 0.8em;
    }

    .continue-btn {
      background-color: transparent !important;
      text-align: left;
      width: 380px;
      border: 2px solid #dbdbdb;
      display: grid;
      grid-template-columns: 1fr 3fr;
      align-items: center;

      img {
        width: 40px;
        justify-self: center;
      }
      .continue-desc {
        font-size: 0.8em;
      }
    }
  }

  .outer-loading-bar {
    width: 120px;
    height: 16px;

    border: 1px solid #adadad;
    background-color: white;
  }

  .inner-loading-bar {
    height: 100%;
    width: 75px;

    background-color: #9487ff;
  }
}
</style>