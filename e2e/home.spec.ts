import { expect, test } from "@playwright/test";

test("home page explains the platform and its migration status", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { name: /Every question is a chance to get sharper/i })).toBeVisible();
  await expect(page.getByRole("heading", { name: /Built around how students practice/i })).toBeVisible();
  await expect(page.getByText(/not a claim that the legacy workflows are already migrated/i)).toBeVisible();
});
