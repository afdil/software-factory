<script setup lang="ts">
const config = useRuntimeConfig()
const siteName = config.public.siteName || '__PROJECT_NAME__'

useSeoMeta({
  title: `${siteName} — Official Site`,
  description: 'Replace with the SEO-optimized value proposition defined in .factory/SPEC.md.',
  ogTitle: `${siteName} — Official Site`,
  ogDescription: 'Replace with the SEO-optimized value proposition defined in .factory/SPEC.md.',
  twitterCard: 'summary_large_image',
})

useSchemaOrg([
  defineWebSite({
    name: siteName,
  }),
  defineWebPage({
    name: `${siteName} Home`,
  }),
])
</script>

<template>
  <header class="border-b border-border bg-card">
    <nav class="mx-auto flex max-w-6xl items-center justify-between px-6 py-4" aria-label="Primary">
      <a href="/" class="text-base font-semibold tracking-tight">{{ siteName }}</a>
      <a
        href="#cta"
        class="rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground"
      >
        Get started
      </a>
    </nav>
  </header>

  <main>
    <section class="mx-auto max-w-4xl px-6 py-24 text-center">
      <h1 class="text-4xl font-bold tracking-tight sm:text-5xl">
        {{ siteName }}
      </h1>
      <p class="mx-auto mt-6 max-w-2xl text-lg text-muted-foreground">
        Replace this starter hero with the copy and layout locked in .factory/SPEC.md and .factory/DESIGN_SYSTEM.md.
      </p>
      <div id="cta" class="mt-10 flex items-center justify-center gap-4">
        <a
          href="#features"
          class="rounded-md bg-primary px-6 py-3 text-sm font-medium text-primary-foreground"
        >
          Explore features
        </a>
      </div>
    </section>

    <section id="features" class="mx-auto max-w-6xl px-6 py-16">
      <h2 class="text-2xl font-semibold tracking-tight">Key capabilities</h2>
      <p class="mt-2 text-sm text-muted-foreground">Structured sections go here.</p>
    </section>
  </main>

  <footer class="border-t border-border py-10 text-center text-sm text-muted-foreground">
    &copy; {{ new Date().getFullYear() }} {{ siteName }}. All rights reserved.
  </footer>
</template>
