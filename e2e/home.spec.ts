import { expect, test } from "@playwright/test";

test("home page presents the redesigned practice routes and honest availability", async ({ page }) => {
  await page.goto("/");
  await expect(
    page.getByRole("heading", { name: /Practice smarter\.\s*Show up stronger\./i }),
  ).toBeVisible();
  await expect(
    page.getByRole("heading", { name: /Choose your next step/i }),
  ).toBeVisible();
  await expect(
    page.getByRole("heading", { name: /Find the practice that fits today/i }),
  ).toBeVisible();
  await expect(page.getByRole("link", { name: /Open daily challenge/i })).toHaveAttribute(
    "href",
    "/challenge",
  );
  await expect(page.getByRole("link", { name: /Explore previous-year questions/i })).toHaveAttribute(
    "href",
    "/pyq",
  );
  await expect(page.getByText("Migration queued").first()).toBeVisible();
});

test("sign-in renders without browser errors", async ({ page }) => {
  const pageErrors: string[] = [];
  page.on("pageerror", (error) => pageErrors.push(error.message));

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
  expect(pageErrors).toEqual([]);
});

test("sign-in provider failures do not expose raw authentication errors", async ({ page }) => {
  await page.route("**/auth/v1/token*", async (route) => {
    await route.fulfill({
      status: 400,
      contentType: "application/json",
      body: JSON.stringify({ message: "Invalid login credentials", code: "invalid_credentials" }),
    });
  });

  await page.goto("/login");
  await page.getByLabel("Email address").fill("student@example.com");
  await page.getByLabel("Password").fill("wrong-password");
  await page.getByRole("button", { name: "Sign in" }).click();

  await expect(page.locator('p[role="alert"]')).toHaveText(
    "Unable to sign in. Check your credentials and try again.",
  );
  await expect(page.getByText("Invalid login credentials")).toHaveCount(0);
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

test("password-reset success uses a neutral confirmation", async ({ page }) => {
  await page.route("**/auth/v1/recover*", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({}),
    });
  });

  await page.goto("/auth/reset-password");
  await page.getByLabel("Email address").fill("student@example.com");
  await page.getByRole("button", { name: "Send reset link" }).click();

  await expect(page.getByRole("status")).toHaveText(
    "If the account is eligible, a reset link will be sent to this address.",
  );
  await expect(page.locator('p[role="alert"]')).toHaveCount(0);
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
test("anonymous visitors cannot open the admin dashboard", async ({ page }) => {
  await page.goto("/admin");
  await expect(page).toHaveURL(/\/login(?:\?|$)/);
  await expect(page.getByRole("heading", { name: "Sign in" })).toBeVisible();
});

test("anonymous visitors cannot open the admin PYQ workbench", async ({ page }) => {
  await page.goto("/admin/pyq");
  await expect(page).toHaveURL(/\/login(?:\?|$)/);
  await expect(page.getByRole("heading", { name: "Sign in" })).toBeVisible();
});

test("anonymous visitors see a safe sign-in prompt on their profile", async ({ page }) => {
  await page.goto("/profile");
  await expect(page.getByRole("heading", { name: "Your profile" })).toBeVisible();
  await expect(
    page.getByText("Sign in to see your challenge history and account details."),
  ).toBeVisible();
  await expect(page.getByRole("link", { name: "Sign in" })).toHaveAttribute(
    "href",
    "/login?next=%2Fprofile",
  );
});

test("OAuth callback without a code returns safely to sign-in", async ({ page }) => {
  await page.goto("/auth/callback?next=https%3A%2F%2Fevil.example%2Fsteal");
  await expect(page).toHaveURL(/login\?error=oauth_callback$/);
  await expect(page.getByRole("heading", { name: "Sign in" })).toBeVisible();
  await expect(page).not.toHaveURL(/evil\.example/);
});
