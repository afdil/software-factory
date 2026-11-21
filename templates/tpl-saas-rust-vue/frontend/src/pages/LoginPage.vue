<script setup lang="ts">
import { ref } from 'vue'
import { useRouter, RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const router = useRouter()

const email = ref('')
const password = ref('')
const errorMessage = ref<string | null>(null)

async function onSubmit() {
  if (auth.loading) return
  errorMessage.value = null
  const err = await auth.login(email.value, password.value)
  if (err) {
    errorMessage.value = err
    return
  }
  await router.push({ name: 'dashboard' })
}
</script>

<template>
  <main class="min-h-screen flex items-center justify-center p-6 bg-background">
    <div class="w-full max-w-md rounded-md border border-border bg-card p-8 shadow-xs">
      <h1 class="text-2xl font-semibold tracking-tight text-card-foreground">Sign in</h1>
      <p class="mt-1 text-sm text-muted-foreground">Enter your credentials to continue.</p>

      <form class="mt-6 space-y-4" @submit.prevent="onSubmit">
        <div
          v-if="errorMessage"
          role="alert"
          data-testid="auth-error"
          class="rounded-md border border-destructive/40 bg-destructive/10 px-3 py-2 text-sm text-destructive"
        >
          {{ errorMessage }}
        </div>

        <div class="space-y-1.5">
          <label for="email" class="block text-sm font-medium">Email</label>
          <input
            id="email"
            v-model="email"
            type="email"
            required
            autocomplete="email"
            data-testid="login-email"
            class="w-full rounded-md border border-border bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
          />
        </div>

        <div class="space-y-1.5">
          <label for="password" class="block text-sm font-medium">Password</label>
          <input
            id="password"
            v-model="password"
            type="password"
            required
            autocomplete="current-password"
            data-testid="login-password"
            class="w-full rounded-md border border-border bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
          />
        </div>

        <button
          type="submit"
          :disabled="auth.loading"
          data-testid="login-submit"
          class="w-full rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-opacity disabled:opacity-50"
        >
          {{ auth.loading ? 'Signing in...' : 'Sign in' }}
        </button>
      </form>

      <p class="mt-6 text-center text-sm text-muted-foreground">
        Need an account?
        <RouterLink to="/register" class="font-medium text-foreground underline underline-offset-4">
          Create one
        </RouterLink>
      </p>
    </div>
  </main>
</template>
