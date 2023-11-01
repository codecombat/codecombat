<template>
    <div class="carousel-component">
        <div class="content-template-carousel">
            <div v-if="showTabs" class="carousel-tabs content-tabs">
                <button v-for="(item, index) in items" :key="'tab' + index" @click="goTo(index)" class="content-point">
                    <div class="content-bg" :class="{ active: currentIndex === index }">
                        <p class="content-text">{{ item.title }}</p>
                    </div>
                </button>
            </div>

            <div v-for="(item, index) in items" :key="'item' + index" class="carousel-item" v-show="currentIndex === index">
                <div class="content-details">
                    <div class="content-icon-container">
                        <button class="btn prev-button" @click="goTo(currentIndex - 1)" :disabled="currentIndex <= 0">
                            <svg xmlns="http://www.w3.org/2000/svg" width="40" height="41" viewBox="0 0 40 41" fill="none">
                                <circle cx="20" cy="20.6301" r="20" transform="rotate(180 20 20.6301)" fill="#0E4C60" />
                                <path
                                    d="M13.9393 19.5695C13.3536 20.1553 13.3536 21.105 13.9393 21.6908L23.4853 31.2367C24.0711 31.8225 25.0208 31.8225 25.6066 31.2367C26.1924 30.6509 26.1924 29.7012 25.6066 29.1154L17.1213 20.6301L25.6066 12.1448C26.1924 11.5591 26.1924 10.6093 25.6066 10.0235C25.0208 9.43774 24.0711 9.43774 23.4853 10.0235L13.9393 19.5695ZM16 19.1301L15 19.1301L15 22.1301L16 22.1301L16 19.1301Z"
                                    fill="white" />
                            </svg>
                        </button>
                        <img class="content-icon" :src="item.image">
                        <button class="btn next-button" @click="goTo(currentIndex + 1)"
                            :disabled="currentIndex >= items.length - 1">
                            <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 40 40" fill="none">
                                <circle cx="20" cy="20" r="20" fill="#0E4C60" />
                                <path
                                    d="M26.0607 21.0607C26.6464 20.4749 26.6464 19.5251 26.0607 18.9393L16.5147 9.3934C15.9289 8.80761 14.9792 8.80761 14.3934 9.3934C13.8076 9.97919 13.8076 10.9289 14.3934 11.5147L22.8787 20L14.3934 28.4853C13.8076 29.0711 13.8076 30.0208 14.3934 30.6066C14.9792 31.1924 15.9289 31.1924 16.5147 30.6066L26.0607 21.0607ZM24 21.5H25V18.5H24V21.5Z"
                                    fill="white" />
                            </svg>
                        </button>
                    </div>
                    <div class="content-text">
                        <p class="content-title">{{ item.title }}</p>
                        <div class="content-text">
                            <p v-html="item.text"></p>
                        </div>

                    </div>
                </div>
            </div>

            <div v-if="showDots" class="carousel-dots">
                <button v-for="(item, index) in items" :key="'dot' + index" @click="goTo(index)"
                    :class="{ active: currentIndex === index }">
                    {{ index + 1 }}
                </button>
            </div>
        </div>
    </div>
</template>
  
<script>
export default {
    props: {
        items: {
            type: Array,
            required: true
        },
        showTabs: {
            type: Boolean,
            default: false
        },
        showDots: {
            type: Boolean,
            default: false
        }
    },
    data() {
        return {
            currentIndex: 0
        };
    },
    methods: {
        goTo(index) {
            if (index >= 0 && index < this.items.length) {
                this.currentIndex = index;
            }
        }
    }
};
</script>
  
<style scoped lang="scss">
%font-18-24 {
  font-size: 18px;
  line-height: 24px;
  @media screen and (max-width: 768px) {
    font-size: 14px;
    line-height: 20px;
  }
}
.carousel-tabs>button.active,
.carousel-dots>button.active {}

.content-template-carousel {
    position: relative;
    justify-content: center;
    display: flex;
    padding-top: 70px;
    box-sizing: border-box;
    min-height: 365px;
    width: 100%;

    @media screen and (max-width: 768px) {
        padding-top: 33px;
    }
}

.content-details {
    padding-top: 60px;
    padding-bottom: 60px;
    padding-right: 70px;
    padding-left: 70px;
    justify-content: center;
    align-items: center;
    gap: 70px;
    height: 100%;
    box-sizing: border-box;
    background-color: rgba(255, 255, 255, 1);
    box-shadow: 0px 0px 0px 4px rgba(242, 190, 25, 1) inset;
    box-shadow-width: 4px;
    display: flex;
    width: 100%;
    border-radius: 14px;
    color: rgba(0, 0, 0, 1);
    text-align: left;

    @media screen and (max-width: 768px) {
        padding-left: 0px;
        padding-right: 0px;
    }

    @media screen and (max-width: 768px) {
        flex-direction: column;
    }

    >* {

        @media screen and (max-width: 768px) {
            margin-right: 30px;
            margin-left: 30px;
        }
    }
}

.content-icon-container {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 10px;

    @media screen and (max-width: 768px) {
        width: calc(100% - 60px);
    }

    .prev-button,
    .next-button {
        outline: none;
        background: none;
        border: none;
        padding: 0;
        cursor: pointer;
        box-shadow: none;

        @media screen and (min-width: 769px) {
            display: none;
        }
    }
}

.content-icon {
    height: 175px;
    width: 175px;
}


.content-title {
    @extend %font-18-24;
    max-width: 835px;
    width: 100%;
    font-weight: 700;
}

.content-text {
    @extend %font-18-24;
    max-width: 835px;
    width: 100%;
    line-height: 1;
    position: relative;
    font-weight: 400;
    align-items: flex-start;
    flex-direction: column;
    display: flex;

    @media screen and (max-width: 768px) {
        gap: 14px;
        width: auto;
    }

    p {
        @extend %font-18-24;
        display: inline;
    }
}

.content-tabs {
    font-weight: 700;
    text-align: center;
    position: absolute;
    top: 0;
    align-items: flex-start;
    display: flex;
    gap: 7px;
    width: 100%;
    padding-left: 36px;
    padding-right: 36px;

    .content-point {
        color: rgba(14, 76, 96, 1);
        align-items: center;
        justify-content: center;
        display: flex;
        border-top-right-radius: 14px;
        border-top-left-radius: 14px;
        box-sizing: border-box;
        height: 70px;
        border: none;
        flex: 1;
        padding: 0;
        background: none;


        .content-bg {
            width: 100%;
            align-items: center;
            justify-content: center;
            display: flex;
            border-top-right-radius: 14px;
            border-top-left-radius: 14px;
            background-color: rgba(14, 76, 96, 1);
            color: rgba(255, 255, 255, 1);

            &.active {
                background-color: rgba(242, 190, 25, 1);
                color: #0E4C60;
            }

            &:not(.active):hover {
                background-color: #186882;
            }

            box-sizing: border-box;
            height: 100%;

            @media (max-width: 768px) {
                width: 20px;
                height: 20px;
                border-radius: 20px;
            }

            .content-text {
                @extend %font-18-24;
                display: flex;
                align-items: center;
                justify-content: center;
                height: 70px;
                text-align: center;
                font-family: Open Sans;
                font-style: normal;
                font-weight: 700;
                line-height: normal;
                color: inherit;

                @media (max-width: 768px) {
                    display: none;
                }
            }
        }
    }
}

.carousel-dots {
    display: none;
}
</style>