import { test, expect } from '@playwright/test'

test.describe('Core SaaS Smoke Suite', () => {
  test('GET /api/health returns 200 and healthy database', async ({ request }) => {
    const res = await request.get('/api/health')
    expect(res.status()).toBe(200)
    const body = await res.json()
    expect(body).toEqual({ status: 'ok', db: 'ok' })
  })

  test('register, view dashboard, logout, and login with zero runtime errors', async ({ page }) => {
    const pageErrors: string[] = []
    const serverErrors: string[] = []

    page.on('pageerror', (err) => pageErrors.push(err.message))
    page.on('response', (res) => {
      if (res.status() >= 500) serverErrors.push(`${res.status()} ${res.url()}`)
    })

    const email = `smoke-${Date.now()}@example.com`
    const password = 'Password123!'

    await page.goto('/register')
    await page.getByTestId('register-name').fill('Smoke Tester')
    await page.getByTestId('register-email').fill(email)
    await page.getByTestId('register-password').fill(password)
    await page.getByTestId('register-submit').click()

    await expect(page).toHaveURL('/')
    await expect(page.getByTestId('user-email')).toHaveText(email)

    await page.getByTestId('logout-btn').click()
    await expect(page).toHaveURL('/login')

    await page.getByTestId('login-email').fill(email)
    await page.getByTestId('login-password').fill(password)
    await page.getByTestId('login-submit').click()

    await expect(page).toHaveURL('/')
    expect(pageErrors).toEqual([])
    expect(serverErrors).toEqual([])
  })
})
