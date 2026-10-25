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

test("password-reset page explains the neutral recovery response", async ({ page }) => {
  await page.goto("/auth/reset-password");
  await expect(page.getByRole("heading", { name: "Reset your password" })).toBeVisible();
  await expect(
    page.getByText(/show a neutral confirmation so account existence is not disclosed/i),
  ).toBeVisible();
  await expect(page.getByLabel("Email address")).toHaveAttribute("type", "email");
  await expect(page.getByRole("button", { name: "Send reset link" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Back to sign in" })).toHaveAttribute(
    "href",
    "/login",
  );
});

test("password-reset provider failures stay neutral", async ({ page }) => {
  await page.route("**/auth/v1/recover*", async (route) => {
    await route.fulfill({
      status: 400,
      contentType: "application/json",
      body: JSON.stringify({ message: "User not found", code: "user_not_found" }),
    });
  });

  await page.goto("/auth/reset-password");
  await page.getByLabel("Email address").fill("student@example.com");
  await page.getByRole("button", { name: "Send reset link" }).click();

  await expect(page.locator('p[role="alert"]')).toHaveText(
    "Could not request a password reset. Please try again later.",
  );
  await expect(page.getByText("User not found")).toHaveCount(0);
});

test("password update rejects mismatched passwords before contacting auth", async ({ page }) => {
  await page.goto("/auth/update-password");
  await expect(page.getByRole("heading", { name: "Choose a new password" })).toBeVisible();
  await expect(page.getByLabel("New password")).toHaveAttribute("minlength", "12");
  await page.getByLabel("New password").fill("StrongPassword123");
  await page.getByLabel("Confirm password").fill("DifferentPassword456");
  await page.getByRole("button", { name: "Update password" }).click();
  await expect(page.locator('p[role="alert"]')).toHaveText("The passwords do not match.");
});
