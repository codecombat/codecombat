<template>
  <div class="subview success-view">
    <div class="head1">
      <img
        class="check-mark"
        src="/images/pages/account/checkmark.svg"
      >
      <span>
        {{ $t('account.all_set') }}
      </span>
    </div>
    <div class="desc">
      {{ roleDesc }}
    </div>
    <div class="video">
      <YoutubeBox
        class="youtube-video"
        :video-id="'rOXRBQIXvlI'"
      />
    </div>
    <div class="awards-and-partners">
      <div class="head3">
        {{ $t('home_v3.awards_partners') }}
      </div>
      <PartnersList />
    </div>
  </div>
</template>

<script>
import PartnersList from 'app/views/home/PartnersList.vue'
import YoutubeBox from 'app/components/common/image-containers/YoutubeBox.vue'
export default {
  components: {
    PartnersList,
    YoutubeBox,
  },
  props: {
    role: {
      type: String,
      default: 'individual',
    },
  },
  computed: {
    roleDesc () {
      return $.i18n.t(`account.${this.role}_completion`)
    },
  },
}

</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";
.success-view {
  width: 100%;
  max-width: 90vw;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  text-align: center;

  .head1 {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: .5rem;

    .check-mark {
      width: 6rem;
    }

    span {
      font-size: 2.4rem;
    }
  }

  .video {
    margin-top: 2rem;

    .youtube-video {
      width: min(100%, 50rem);
    }
  }

  .awards-and-partners {
    width: 100%;
    background-color: white;
    text-align: center;
    padding: 4rem 2rem;
    border-radius: 2rem;
    box-shadow: 0 1rem 3rem rgba(0, 0, 0, 0.08);
    margin-top: 2rem;

    .head3 {
      font-size: 2.6rem;
      color: black;
      text-align: center;
      margin-bottom: 1rem;
    }

    ::v-deep .frame {
      .image {
        width: 6rem;
      }

      .text-wrapper {
        font-size: 1.4rem;
        line-height: 1.6rem;
      }
    }
  }
}
@media (max-width: $screen-sm-min) {
  .success-view {
    gap: 2rem;
    .head1 {
      flex-direction: row;
      .check-mark {
        width: 2.8rem;
      }
      span {
        line-height: 2.8rem;
        font-size: 3rem;
      }
    }

    .awards-and-partners {
      width: 100vw;
      position: absolute;
      top: 65vh;
      margin-top: 4rem;
      border-radius: unset;
      box-shadow: 0 1rem 1rem rgba(0, 0, 0, 0.08), 0 -0.5rem 1rem rgba(0, 0, 0, 0.08);

      ::v-deep .frame {
        gap: .3rem;

        .image {
          width: 8rem;
        }
      }
      ::v-deep .frame .div {
        gap: .3rem;
      }
    }
  }
}
</style>
