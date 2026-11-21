<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const router = useRouter()

async function onLogout() {
  await auth.logout()
  await router.push({ name: 'login' })
}
</script>

<template>
  <div class="min-h-screen bg-background">
    <header class="border-b border-border bg-card">
      <div class="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <span class="text-base font-semibold tracking-tight">__PROJECT_NAME__</span>
        <div class="flex items-center gap-4">
          <span class="text-sm text-muted-foreground" data-testid="user-email">
            {{ auth.user?.email }}
          </span>
          <button
            type="button"
            data-testid="logout-btn"
            :disabled="auth.loading"
            class="rounded-md border border-border px-3 py-1.5 text-sm font-medium hover:bg-accent disabled:opacity-50"
            @click="onLogout"
          >
            Sign out
          </button>
        </div>
      </div>
    </header>

    <main class="mx-auto max-w-6xl px-6 py-10">
      <h1 class="text-2xl font-semibold tracking-tight">Dashboard</h1>
      <p class="mt-2 text-sm text-muted-foreground">
        Welcome, {{ auth.user?.name }}. Replace this starter shell with your domain modules.
      </p>
    </main>
  </div>
</template>
