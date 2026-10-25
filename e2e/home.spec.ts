import { expect, test } from "@playwright/test";

test("home page explains the platform and its migration status", async ({ page }) => {
  await page.goto("/");
  await expect(
    page.getByRole("heading", { name: /Every question is a chance to get sharper/i }),
  ).toBeVisible();
  await expect(
    page.getByRole("heading", { name: /Built around how students practice/i }),
  ).toBeVisible();
  await expect(
    page.getByText(/not a claim that the legacy workflows are already migrated/i),
  ).toBeVisible();
});

test("sign-in page exposes accessible email and password controls", async ({ page }) => {
  await page.goto("/login");
  await expect(page.getByRole("heading", { name: "Sign in" })).toBeVisible();
  await expect(page.getByLabel("Email address")).toHaveAttribute("type", "email");
  await expect(page.getByLabel("Password")).toHaveAttribute("type", "password");
  await expect(page.getByRole("button", { name: "Continue with Google" })).toBeVisible();
  await expect(page.getByRole("button", { name: "Sign in" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Forgot password?" })).toHaveAttribute(
    "href",
    "/auth/reset-password",
  );
});
