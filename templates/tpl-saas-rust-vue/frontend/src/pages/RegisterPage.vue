<script setup lang="ts">
import { ref } from 'vue'
import { useRouter, RouterLink } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const router = useRouter()

const name = ref('')
const email = ref('')
const password = ref('')
const errorMessage = ref<string | null>(null)

async function onSubmit() {
  if (auth.loading) return
  errorMessage.value = null
  const err = await auth.register(name.value, email.value, password.value)
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
      <h1 class="text-2xl font-semibold tracking-tight text-card-foreground">Create account</h1>
      <p class="mt-1 text-sm text-muted-foreground">Start using __PROJECT_NAME__.</p>

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
          <label for="name" class="block text-sm font-medium">Name</label>
          <input
            id="name"
            v-model="name"
            type="text"
            required
            autocomplete="name"
            data-testid="register-name"
            class="w-full rounded-md border border-border bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
          />
        </div>

        <div class="space-y-1.5">
          <label for="email" class="block text-sm font-medium">Email</label>
          <input
            id="email"
            v-model="email"
            type="email"
            required
            autocomplete="email"
            data-testid="register-email"
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
            minlength="8"
            autocomplete="new-password"
            data-testid="register-password"
            class="w-full rounded-md border border-border bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
          />
        </div>

        <button
          type="submit"
          :disabled="auth.loading"
          data-testid="register-submit"
          class="w-full rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-opacity disabled:opacity-50"
        >
          {{ auth.loading ? 'Creating account...' : 'Create account' }}
        </button>
      </form>

      <p class="mt-6 text-center text-sm text-muted-foreground">
        Already have an account?
        <RouterLink to="/login" class="font-medium text-foreground underline underline-offset-4">
          Sign in
        </RouterLink>
      </p>
    </div>
  </main>
</template>
