<template>
  <div
    v-if="bannerType"
    :class="['domain-banner', 'domain-banner--info']"
    role="alert"
  >
    <span v-if="bannerType === 'info'">
      <strong>{{ $t('general.domain_banner_warning') }}</strong>
      {{ $t('general.domain_banner_message') }}
      <a
        href="https://codecombat.com"
        rel="noopener noreferrer"
      >{{ $t('general.domain_banner_link') }}</a>
    </span>
    <button
      class="domain-banner__dismiss"
      :aria-label="$t('teacher_dashboard.click_dismiss')"
      @click="dismiss"
    >
      ×
    </button>
  </div>
</template>

<script>
const LEGITIMATE_HOSTNAMES = [
  'codecombat.com',
  'ozaria.com',
  'localhost',
  '127.0.0.1',
]

// Matches EZProxy patterns like codecombat-com.ezproxy.orl.bc.ca regardless of TLD
const EZPROXY_RE = /^codecombat[.-](?:com|org).*(?:ezproxy|proxy)\./i

const DISMISS_KEY = 'domain-banner-dismissed'

function dismissKey () {
  return `${DISMISS_KEY}-${me.get('_id') || 'anonymous'}`
}

function isDismissed () {
  return localStorage.getItem(dismissKey()) === '1'
}

function setDismissed () {
  localStorage.setItem(dismissKey(), '1')
}

function detectDomainStatus (hostname) {
  // TODO: Implement china specific checks
  // TODO: verify all EZProxy URLs
  const isLegitimate = LEGITIMATE_HOSTNAMES.some(d => hostname === d || hostname.endsWith(`.${d}`))
  if (isLegitimate) return 'legitimate'
  if (EZPROXY_RE.test(hostname)) return 'ezproxy'
  return 'phishing'
}

export default Vue.extend({
  name: 'DomainBanner',

  data () {
    if (isDismissed()) return { bannerType: null }
    const status = detectDomainStatus(window.location.hostname)
    if (status === 'legitimate' || status === 'ezproxy') return { bannerType: null }
    return { bannerType: 'info' }
  },

  methods: {
    dismiss () {
      setDismissed()
      this.bannerType = null
    },
  },
})
</script>

<style scoped lang="scss">
.domain-banner {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 10px 16px;
  font-size: 14px;
  width: 100%;
  position: sticky;
  top: 0;
  z-index: 9999;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.25);

  a {
    font-weight: bold;
    text-decoration: underline;
  }

  &__dismiss {
    background: none;
    border: none;
    cursor: pointer;
    font-size: 18px;
    line-height: 1;
    padding: 0 4px;
    margin-left: 8px;
    opacity: 0.7;

    &:hover {
      opacity: 1;
    }
  }

  &--info {
    background-color: #e8f4fd;
    color: #1a6499;
    border-bottom: 1px solid #bee3f8;

    a,
    .domain-banner__dismiss {
      color: #1a6499;
    }
  }
}
</style>
