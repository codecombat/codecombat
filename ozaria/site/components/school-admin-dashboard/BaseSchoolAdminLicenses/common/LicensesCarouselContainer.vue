<script>
  import ScrollArrow from 'ozaria/site/components/teacher-dashboard/common/buttons/ScrollArrow'
  export default {
    components: {
      ScrollArrow
    }
  }
</script>

<template>
  <div
    id="licenses-carousel-div"
    class="carousel slide"
  >
    <!-- Indicators -->
    <ol class="carousel-indicators">
      <li data-target="#licenses-carousel-div" data-slide-to="0" class="active" />
      <li data-target="#licenses-carousel-div" data-slide-to="1"/>
      <li data-target="#licenses-carousel-div" data-slide-to="2"/>
      <li data-target="#licenses-carousel-div" data-slide-to="3"/>
      <li data-target="#licenses-carousel-div" data-slide-to="4"/>
    </ol>

    <!-- Wrapper for slides -->
    <div class="carousel-inner">
      <div class="item active">
        <div class="item-row">
          <div>
            <img src="/images/ozaria/school-admins/dashboard/my_licenses/Device_1.png" class="computer">
          </div>
          <div class="text-part-carousel">
            <span class="subtitle-24 text-twilight"> {{ $t("no_licenses_page.real_world_skills") }} </span>
            <p class="p-medium-text">
              {{ $t("no_licenses_page.real_world_skills_desc") }}
            </p>
            <div class="icons">
              <img src="/images/pages/home/python_logo.png">
              <img src="/images/pages/home/javascript_logo.png">
            </div>
          </div>
        </div>
      </div>
      <div class="item">
        <div class="item-row">
          <div>
            <img src="/images/ozaria/school-admins/dashboard/my_licenses/Device_2.png" class="computer">
          </div>
          <div class="text-part-carousel">
            <span class="subtitle-24 text-twilight"> {{ $t("no_licenses_page.personalized_learning") }} </span>
            <p class="p-medium-text">
              {{ $t("no_licenses_page.personalized_learning_desc") }}
            </p>
          </div>
        </div>
      </div>
      <div class="item">
        <div class="item-row">
          <div>
            <img src="/images/ozaria/school-admins/dashboard/my_licenses/Device_3.png" class="computer">
          </div>
          <div class="text-part-carousel">
            <span class="subtitle-24 text-twilight"> {{ $t("no_licenses_page.flexible_curriculum") }} </span>
            <p class="p-medium-text">
              {{ $t("no_licenses_page.flexible_curriculum_desc") }}
            </p>
          </div>
        </div>
      </div>
      <div class="item">
        <div class="item-row">
          <div>
            <img src="/images/ozaria/school-admins/dashboard/my_licenses/Device_4.png" class="computer">
          </div>
          <div class="text-part-carousel">
            <span class="subtitle-24 text-twilight"> {{ $t("no_licenses_page.resources_to_support") }} </span>
            <p class="p-medium-text">
              {{ $t("no_licenses_page.resources_to_support_desc") }}
            </p>
          </div>
        </div>
      </div>
      <div class="item">
        <div class="item-row">
          <div>
            <img src="/images/ozaria/school-admins/dashboard/my_licenses/Device_5.png" class="computer">
          </div>
          <div class="text-part-carousel">
            <span class="subtitle-24 text-twilight"> {{ $t("no_licenses_page.actionable_insights") }} </span>
            <p class="p-medium-text">
              {{ $t("no_licenses_page.actionable_insights_desc") }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Left and right controls -->
    <a
      href="#licenses-carousel-div"
      role="button"
      data-slide="prev"
      class="left carousel-control"
    >
      <scroll-arrow :face-left="true" />
    </a>
    <a
      href="#licenses-carousel-div"
      role="button"
      data-slide="next"
      class="right carousel-control"
    >
      <scroll-arrow />
    </a>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.carousel {
  background: #FFFFFF;
  box-shadow: -1px 0px 1px rgba(0, 0, 0, 0.06), 3px 0px 8px rgba(0, 0, 0, 0.15);
  border-radius: 10px;
}
.carousel-indicators {
  bottom: 0px;
}
.carousel-indicators li {
  background-color: #ADADAD;
}
.carousel-indicators .active {
  background-color: $dusk;
}

.item-row {
  display: flex;
  flex-direction: row;
  justify-content: space-around;
  align-items: center;
  width: 88%;
  height: 360px;
  margin: auto;
}
.computer {
  width: 100%;
}
.text-part-carousel {
  max-width: 300px;
}
.icons {
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: center;
  img {
    height: 50px;
    margin: 0px 10px;
  }
}

.carousel-control.left, .carousel-control.right {
  background-image: unset;
  opacity: unset;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 7%;
}

// text

.subtitle-24 {
  @include font-h-2-subtitle-white-24;
}

.text-twilight {
  color: $twilight;
}

.p-medium-text {
  @include font-p-2-paragraph-medium-gray;
  width: 280px;
  margin: 10px 0px;
}
</style>
