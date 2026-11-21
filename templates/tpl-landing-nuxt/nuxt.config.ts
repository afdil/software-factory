import tailwindcss from '@tailwindcss/vite'

export default defineNuxtConfig({
  compatibilityDate: '2025-05-01',
  devtools: { enabled: false },
  future: {
    compatibilityVersion: 4,
  },
  modules: ['@nuxtjs/seo'],
  css: ['~/assets/css/main.css'],
  vite: {
    plugins: [tailwindcss()],
  },
  site: {
    url: process.env.NUXT_PUBLIC_SITE_URL || 'http://localhost:8080',
    name: process.env.NUXT_PUBLIC_SITE_NAME || '__PROJECT_NAME__',
    defaultLocale: 'en',
  },
  runtimeConfig: {
    public: {
      siteUrl: process.env.NUXT_PUBLIC_SITE_URL || 'http://localhost:8080',
      siteName: process.env.NUXT_PUBLIC_SITE_NAME || '__PROJECT_NAME__',
    },
  },
  app: {
    head: {
      htmlAttrs: { lang: 'en' },
      charset: 'utf-8',
      viewport: 'width=device-width, initial-scale=1',
    },
  },
  routeRules: {
    '/**': {
      headers: {
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'DENY',
        'Referrer-Policy': 'strict-origin-when-cross-origin',
      },
    },
  },
})
