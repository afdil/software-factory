import { test, expect } from '@playwright/test'

test.describe('Landing Page SEO & Smoke Suite', () => {
  test('renders home with valid SEO metadata and zero console/server errors', async ({ page, request }) => {
    const pageErrors: string[] = []
    const serverErrors: string[] = []

    page.on('pageerror', (err) => pageErrors.push(err.message))
    page.on('response', (res) => {
      if (res.status() >= 500) serverErrors.push(`${res.status()} ${res.url()}`)
    })

    await page.goto('/')
    await expect(page.locator('h1')).toHaveCount(1)
    expect((await page.title()).length).toBeGreaterThan(3)

    const metaDesc = await page.locator('meta[name="description"]').getAttribute('content')
    expect(metaDesc && metaDesc.length > 10).toBeTruthy()

    const ogTitle = await page.locator('meta[property="og:title"]').getAttribute('content')
    expect(ogTitle && ogTitle.length > 3).toBeTruthy()

    const robots = await request.get('/robots.txt')
    expect(robots.status()).toBe(200)

    const sitemap = await request.get('/sitemap.xml')
    expect(sitemap.status()).toBe(200)

    expect(pageErrors).toEqual([])
    expect(serverErrors).toEqual([])
  })
})
