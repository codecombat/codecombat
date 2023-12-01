<template>
  <div>
    <div class="library">
      <div class="container">
        <section class="row library__heading">
          <img src="/images/pages/base/logo.png">
          <div class="library__heading-row">
            <div class="col-md-4">
              <img
                class="library__heading-image-books"
                src="/images/pages/library/books_1.png"
              >
            </div>
            <div class="col-md-4">
              <h1 class="library__heading-title pixel-text">
                for
              </h1>
              <h1 class="library__heading-title pixel-text">
                Libraries
              </h1>
            </div>
            <div class="col-md-4">
              <img
                class="library__heading-image-books"
                src="/images/pages/library/books_2.png"
              >
            </div>
          </div>
          <h2 class="library__heading-text pixel-text">
            {{ $t('library.engage_members') }}
          </h2>
          <button
            class="btn library__heading-btn btn-moon"
            @click="toggleLicenseModal"
          >
            {{ $t('general.contact_us') }}
          </button>
        </section>

        <section class="library__sub">
          <div class="row library__sub-1">
            <div class="library__sub-text col-md-6">
              <div class="library__needs__info__text-heading">
                {{ $t('library.educational_equity') }}
              </div>
              <div class="library__needs__info__text-sub">
                {{ $t('library.importance_blurb') }}
              </div>
            </div>
            <div class="library__sub-image col-md-6">
              <img
                src="/images/pages/library/library-students.png"
                alt="Students in library"
                class="library__sub-image-img img-responsive teal-border"
              >
            </div>
          </div>

          <div class="library__continue">
            <img
              class="img-responsive library__continue__image"
              src="/images/pages/library/image-1.png"
            >
          </div>

          <div class="row library__sub-2 row-reverse-order">
            <div class="library__sub-text col-md-6">
              <div class="library__needs__info__text-heading">
                {{ $t('library.power_of_play') }}
              </div>
              <div class="library__needs__info__text-sub">
                {{ $t('library.games_teach_blurb') }}
              </div>
            </div>
            <div class="library__sub-image col-md-6">
              <img
                src="/images/pages/library/power-of-play.png"
                alt="Teach real code"
                class="library__sub-image-img img-responsive teal-border"
              >
            </div>
          </div>
        </section>

        <div class="library__continue">
          <img
            class="img-responsive library__continue__image"
            src="/images/pages/library/image-2.png"
          >
        </div>

        <section class="library__needs">
          <div class="library__needs__heading pixel-text">
            {{ $t('library.platform_built') }}
          </div>

          <div class="library__continue">
            <img
              class="img-responsive library__continue__image"
              src="/images/pages/library/image-3.png"
            >
          </div>

          <div class="row library__needs__info">
            <div class="col-md-6 library__needs__info__text">
              <div class="library__needs__info__text-heading">
                {{ $t('library.accessible') }}
              </div>
              <div class="library__needs__info__text-sub">
                {{ $t('library.accessible_blurb') }}
              </div>
            </div>
            <div class="col-md-6 library__needs__info-img">
              <img
                src="/images/pages/library/accessible.png"
                alt="Students with computer"
                class="img-responsive teal-border"
              >
            </div>
          </div>

          <div class="library__continue">
            <img
              class="img-responsive library__continue__image"
              src="/images/pages/library/image-4.png"
            >
          </div>

          <div class="row library__needs__info row-reverse-order">
            <div class="col-md-6 library__needs__info__text">
              <div class="library__needs__info__text-heading">
                {{ $t('library.self_paced_intuitive') }}
              </div>
              <div class="library__needs__info__text-sub">
                {{ $t('library.self_paced_intuitive_blurb') }}
              </div>
            </div>
            <div class="col-md-6 library__needs__info-img">
              <img
                src="/images/pages/library/self-paced.png"
                alt="Self paced and intuitive"
                class="img-responsive teal-border"
              >
            </div>
          </div>

          <div class="library__continue">
            <img
              class="img-responsive library__continue__image"
              src="/images/pages/library/image-5.png"
            >
          </div>

          <div class="row library__needs__info">
            <div class="col-md-6 library__needs__info__text">
              <div class="library__needs__info__text-heading">
                {{ $t('library.engaging_content') }}
              </div>
              <div class="library__needs__info__text-sub">
                {{ $t('library.engaging_content_blurb') }}
              </div>
            </div>
            <div class="col-md-6 library__needs__info-img">
              <img
                src="/images/pages/library/engaging.png"
                alt="Engaging"
                class="img-responsive teal-border"
              >
            </div>
          </div>

          <div class="library__continue">
            <img
              class="img-responsive library__continue__image"
              src="/images/pages/library/image-6.png"
            >
          </div>

          <div class="row library__needs__info  row-reverse-order">
            <div class="col-md-6 library__needs__info__text">
              <div class="library__needs__info__text-heading">
                {{ $t('library.api_integrate') }}
              </div>
              <div class="library__needs__info__text-sub">
                {{ $t('library.api_integrate_blurb') }}
              </div>
            </div>
            <div class="col-md-6 library__needs__info-img">
              <img
                src="/images/pages/library/api-integration.png"
                alt="Calgary library page"
                class="img-responsive teal-border"
              >
            </div>
          </div>

          <div class="library__continue">
            <img
              class="img-responsive library__continue__image"
              src="/images/pages/library/image-7.png"
            >
          </div>

          <div
            id="carousel-libraries"
            class="carousel slide"
            data-interval="8000"
          >
            <div class="carousel-indicators carousel-tabs">
              <div
                class="carousel-tabs__tab pixel-text active"
                data-target="#carousel-libraries"
                data-slide-to="0"
              >
                {{ $t('library.privacy') }}
              </div>
              <div
                class="carousel-tabs__tab pixel-text"
                data-target="#carousel-libraries"
                data-slide-to="1"
              >
                {{ $t('library.communication_limit') }}
              </div>
              <div
                class="carousel-tabs__tab pixel-text"
                data-target="#carousel-libraries"
                data-slide-to="2"
              >
                {{ $t('library.usage_stats') }}
              </div>
              <div
                class="carousel-tabs__tab pixel-text"
                data-target="#carousel-libraries"
                data-slide-to="3"
              >
                {{ $t('library.esports') }}
              </div>
            </div>

            <div class="carousel-inner">
              <div
                class="item active"
                data-slide="0"
              >
                <div class="row library__needs__info library__needs-only-text">
                  <div class="col-md-5 library__needs__info__image">
                    <img src="/images/pages/library/privacy1.png">
                  </div>
                  <div class="col-md-7 library__needs__info__text">
                    <div class="library__needs__info__text-heading">
                      {{ $t('library.privacy') }}
                    </div>
                    <div class="library__needs__info__text-sub">
                      {{ $t('library.privacy_blurb') }} {{ $t('library.see') }} <a
                        href="/privacy"
                        target="_blank"
                      >{{
                        $t('library.privacy_policy')
                      }}</a>
                    </div>
                  </div>
                </div>
              </div>

              <div
                class="item"
                data-slide="1"
              >
                <div class="row library__needs__info library__needs-only-text">
                  <div class="col-md-5 library__needs__info__image">
                    <img src="/images/pages/library/differentiation1.png">
                  </div>
                  <div class="col-md-7 library__needs__info__text">
                    <div class="library__needs__info__text-heading">
                      {{ $t('library.communication_limit') }}
                    </div>
                    <div class="library__needs__info__text-sub">
                      {{ $t('library.communication_limit_blurb') }}
                    </div>
                  </div>
                </div>
              </div>

              <div
                class="item"
                data-slide="2"
              >
                <div class="row library__needs__info library__needs-only-text">
                  <div class="col-md-5 library__needs__info__image">
                    <img src="/images/pages/library/dashboard1.png">
                  </div>
                  <div class="col-md-7 library__needs__info__text">
                    <div class="library__needs__info__text-heading">
                      {{ $t('library.usage_stats') }}
                    </div>
                    <div class="library__needs__info__text-sub">
                      {{ $t('library.usage_stats_blurb') }}
                    </div>
                  </div>
                </div>
              </div>

              <div
                class="item"
                data-slide="3"
              >
                <div class="row library__needs__info library__needs-only-text">
                  <div class="col-md-5 library__needs__info__image">
                    <img src="/images/pages/library/esports-powered-by-hyper1.png">
                  </div>
                  <div class="col-md-7 library__needs__info__text">
                    <div class="library__needs__info__text-heading">
                      {{ $t('library.esports') }}
                    </div>
                    <div class="library__needs__info__text-sub">
                      {{ $t('library.esports_blurb') }}
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <ol class="carousel-indicators">
              <li
                data-target="#carousel-libraries"
                data-slide-to="0"
                class="active"
              />
              <li
                data-target="#carousel-libraries"
                data-slide-to="1"
              />
              <li
                data-target="#carousel-libraries"
                data-slide-to="2"
              />
              <li
                data-target="#carousel-libraries"
                data-slide-to="3"
              />
            </ol>
          </div>
          <section class="library__footer">
            <div class="library__footer-content row">
              <div class="col-md-offset-1 col-md-10">
                <h2 class="library__footer-text pixel-text">
                  {{ $t('library.work_with_us_blurb') }}
                </h2>
                <div class="library__footer-cta">
                  <button
                    class="btn library__footer-cta-btn btn-moon"
                    @click="toggleLicenseModal"
                  >
                    {{ $t('library.schedule_demo') }}
                  </button>
                </div>
              </div>
            </div>
          </section>
        </section>
      </div>
    </div>
    <div class="container-footer-mountains" />
    <modal-get-licenses
      v-if="showLicenseModal"
      :subtitle="$t('library.license_modal_subtitle')"
      email-message="Hi CodeCombat team! I’m interested in learning more about CodeCombat and how it can be used for my library or library network membership.

        Name of Library or Library Network:
        State or Region Served:
        My Role:
        My Phone Number:
      "
      :ask-school-info="askSchoolInfo"
      :licenses-needed-text="$t('library.license_modal_members')"
      :licenses-needed-placeholder="$t('library.license_modal_members_placeholder')"
      :modal-title="$t('library.license_modal_contact')"
      @close="toggleLicenseModal"
    />
  </div>
</template>

<script>
import ModalGetLicenses from '../../components/common/ModalGetLicenses'
import _ from 'lodash'

export default {
  name: 'LibraryMainView',
  components: {
    ModalGetLicenses
  },
  data () {
    return {
      showLicenseModal: false,
      askSchoolInfo: false
    }
  },
  mounted () {
    _.delay(this.activateCarousels, 1000)
  },

  methods: {
    toggleLicenseModal () {
      this.showLicenseModal = !this.showLicenseModal
    },
    activateCarousels () {
      if (this.destroyed) {
        return
      }
      $('.carousel').carousel().off().on('slid.bs.carousel', this.onCarouselSlide)
    },
    onCarouselSlide (e) {
      $('[data-slide-to]').removeClass('active')
      $('[data-slide-to="' + $(e.relatedTarget).data('slide') + '"]').addClass('active')
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/common/button";
@import "app/styles/style-flat-variables";
@import "app/styles/bootstrap/variables";

.library {
  font-size: 62.5%;
  font-family: "Work Sans", "Open Sans", sans-serif;
  overflow: hidden;

  padding-top: 3rem;
  background: #DCF1F3;

  &__heading {
    text-align: center;
    margin-bottom: 5rem;

    background-image: url(/images/pages/parents/image_cloud_3.svg);
    background-repeat: no-repeat;

    &-text {
      font-weight: 700;
      font-size: 4.5rem;
      line-height: 6rem;

      margin-bottom: 2rem;
    }

    &-title {
      font-weight: 700;
      font-size: 6rem;
      line-height: 6rem;
    }

    &-row {
      display: flex;
      justify-content: center;
      align-items: center;
      margin: 3rem auto;
    }

    &-image-books {
      max-width: 100%;
    }

    &-btn {
      margin: 50px;
    }
  }

  &__sub {
    background-image: url(/images/pages/parents/image_cloud_4.svg);
    background-repeat: no-repeat;
    background-position: center top;

    &-text {
      &__blurb {
        font-size: 2.4rem;
        line-height: 3rem;
        letter-spacing: 0.44px;
        color: #0E4C60;
      }

      &__title {
        font-weight: 700;
        font-size: 2.8rem;
        line-height: 3.8rem;
        color: #0E4C60;

      }
    }

    &-image {
      padding: 1rem 5rem 0;
      @media (max-width: $screen-md) {
        display: none;
      }
    }
  }

  &__needs {
    background-image: url(/images/pages/parents/image_cloud_1.svg);
    background-repeat: no-repeat;
    background-position: right top;

    &-only-text:nth-child(even) {
      background-image: url(/images/pages/parents/image_cloud_4.svg);
      background-repeat: no-repeat;
      background-position: right top;
    }

    &__heading {
      text-align: center;
      font-weight: 700;
      font-size: 4rem;
      line-height: 5rem;
      padding: 12px 0 12px 20px;
    }

    &__info {

      &__image {
        padding: 0 50px;

        img {
          max-height: 100%;
          max-width: 100%;
        }
      }

      &__text {
        text-align: left;

        &-heading {
          font-weight: 700;
          font-size: 2.5rem;
          line-height: 3.8rem;
          letter-spacing: .56px;
          margin-bottom: 1rem;
          color: #0E4C60;
        }

        &-sub {
          font-size: 2.4rem;
          line-height: 3rem;
          letter-spacing: .444px;
        }
      }

      &-img {
        padding-top: 1rem;
      }

      @media (max-width: $screen-md) {
        &-img {
          display: none;
        }
      }
    }
  }

  &__footer {
    padding: 3rem;

    text-align: center;

    &-text {
      font-size: 3.3rem;
      line-height: 6rem;
      letter-spacing: 0.444px;
      font-weight: 700;
      margin-bottom: 2rem;
    }
  }

  &__continue {
    position: relative;
    text-align: center;

    &__image {
      margin: 0px auto;
    }
  }
}

.pixel-text {
  font-family: $pixel-headline-font;
  color: $navy;
}

.teal-border {
  border: 10px solid $teal;
  box-sizing: border-box;
  border-radius: 20px;
}

.carousel {
  margin-top: 30px;

  &-inner {
    border-radius: 38px;
    border: 4px solid #6AE8E3;
    text-align: center;

    .item {
      margin: 50px;
    }
  }

  &-tabs {
    bottom: 20px;
    position: relative;
    display: flex;
    justify-content: space-between;
    margin: 0 30px;
    width: auto;
    left: auto;
    bottom: auto;

    @media (max-width: $screen-md) {
      overflow-x: scroll;
    }

    &__tab {
      cursor: pointer;
      color: white;
      background: #0E4C60;
      width: auto;
      font-style: normal;
      font-weight: 700;
      font-size: 2.6rem;
      line-height: 2.8rem;
      text-align: center;
      border-radius: 10px 10px 0 0;
      margin: 0 5px;
      height: 80px;
      padding: 0 60px;
      display: flex;
      justify-content: center;
      align-items: center;

      &.active {
        background: #6AE8E3;
        color: #0E4C60;

      }

    }
  }

  &-indicators {
    bottom: 0;

    li {
      border: none;
      background-color: #C4C4C4;
      width: 13px;
      height: 13px;
      margin: 5px;

      &.active {
        background-color: #1FBAB4;
      }
    }
  }
}

.row-reverse-order {
  display: flex;

  @media (min-width: $screen-md-min) {
    > :first-child {
      order: 1;
    }
    > :last-child {
      order: 0;
    }
    .library__sub-image {
    }
  }
}

.container-footer-mountains {
  width: 100%;
  background-color: #DCF1F3;
  background-image: url(/images/pages/parents/parents_footer_mountain_compressed.svg);
  background-repeat: no-repeat;
  background-position: top;
  background-size: cover;
  height: 170px;
  margin-bottom: -50px;
}
</style>
