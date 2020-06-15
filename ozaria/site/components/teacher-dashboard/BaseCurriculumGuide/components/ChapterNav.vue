<template>
  <div id="chapter-nav">
    <div class="chapter-btn selected">
      <div class="chapter-pill">
        <h4>Chapter 1</h4>
      </div>
    </div>
    <div class="chapter-btn">
      <div class="chapter-pill">
        <h4>Chapter 2</h4>
      </div>
    </div>
    <div class="chapter-btn">
      <div class="chapter-pill">
        <h4>Chapter 3</h4>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  #chapter-nav {
    display: flex;
    margin: 8px 25px 0;

    box-shadow: 0px 4px 4px rgba(0, 0, 0, 0.06);

    h4 {
      @include font-h-4-nav-uppercase-black;
      font-size: 14px;
      line-height: 18px;
      color: #545b64;
    }
  }

  .chapter-pill {
    padding: 9px 20px;
    border-radius: 20px;

    &:hover {
      background-color: #f2f2f2;
    }
  }

  .chapter-btn {
    margin: 0 2.5px;
    padding: 0 5px;

    cursor: pointer;

    &.selected {
      border-bottom: 4px solid #476fb1;
    }
  }
</style>
