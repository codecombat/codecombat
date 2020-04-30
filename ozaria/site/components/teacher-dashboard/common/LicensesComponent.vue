<template>
  <div id="licenses-component">
    <div id="Licenses" />
    <div id="license-text">
      <span>No licenses yet</span>
      <a>Request Licenses</a>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#Licenses {
  background-image: url(/images/ozaria/teachers/dashboard/svg_icons/IconLicense_Gray.svg);
  background-repeat: no-repeat;
  background-position: center;

  width: 22px;
  height: 20px;
  margin-right: 8px;
}

#licenses-component {
  display: flex;
  flex-direction: row;
  justify-content: center;
  align-items: center;
}

#license-text {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;

  span {
    @include font-p-4-paragraph-smallest-gray;
    font-weight: bold;
  }

  a {
    @include font-p-4-paragraph-smallest-gray;
    font-size: 12px;
    text-decoration: underline;
  }
}
</style>
