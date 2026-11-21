import { defineStore } from 'pinia'
import { ref } from 'vue'
import { apiClient } from '@/api/client'
import type { components } from '@/api/schema'

type User = components['schemas']['UserResponse']

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const initialized = ref(false)
  const loading = ref(false)

  async function fetchMe() {
    loading.value = true
    try {
      const { data } = await apiClient.GET('/api/auth/me')
      user.value = data ?? null
    } finally {
      initialized.value = true
      loading.value = false
    }
  }

  async function login(email: string, password: string): Promise<string | null> {
    loading.value = true
    try {
      const { data, error } = await apiClient.POST('/api/auth/login', {
        body: { email, password },
      })
      if (error || !data) {
        return error?.error?.message ?? 'Invalid email or password'
      }
      user.value = data
      return null
    } finally {
      loading.value = false
    }
  }

  async function register(name: string, email: string, password: string): Promise<string | null> {
    loading.value = true
    try {
      const { data, error } = await apiClient.POST('/api/auth/register', {
        body: { name, email, password },
      })
      if (error || !data) {
        return error?.error?.message ?? 'Registration failed'
      }
      user.value = data
      return null
    } finally {
      loading.value = false
    }
  }

  async function logout() {
    loading.value = true
    try {
      await apiClient.POST('/api/auth/logout')
      user.value = null
    } finally {
      loading.value = false
    }
  }

  return { user, initialized, loading, fetchMe, login, register, logout }
})
