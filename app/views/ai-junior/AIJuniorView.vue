<template>
  <div class="ai-junior-view">
    <header class="ai-junior-header">
      <a
        href="/ai-junior/demo"
        class="ai-junior-logo"
      >
        AI Junior
      </a>
      <!-- Add any common navigation or controls here -->
      <p
        v-if="!hasAccess()"
        class="no-access"
      >
        You do not have access to the AI Junior demo.
      </p>
    </header>

    <main class="ai-junior-content">
      <!-- This is where child routes will be rendered -->
      <router-view />
    </main>

    <footer class="ai-junior-footer">
      <!-- Add any common footer content here -->
    </footer>
  </div>
</template>

<script>
export default {
  name: 'AIJuniorView',
  methods: {
    hasAccess () {
      return me.hasAiJuniorAccess()
    },
  },
}
</script>

<style scoped>
.ai-junior-view {
  /* Add any global styles for AI Junior pages */
  padding: 3rem;
}

.ai-junior-header {
  text-align: center;
  margin-bottom: 2rem;
}

.ai-junior-content {
  /* Style your main content area */
}

.ai-junior-footer {
  /* Style your footer */
}

.ai-junior-logo {
  font-size: 4rem;
  color: #000;
  text-decoration: none;
  text-transform: uppercase;

  &:hover {
    text-decoration: underline;
  }
}

.no-access {
  color: red;
}
</style>
