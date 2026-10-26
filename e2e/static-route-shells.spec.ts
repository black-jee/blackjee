import { expect, test } from "@playwright/test";

const staticRouteShells = [
  { path: "/chapterwise", heading: /Chapter-wise practice/i },
  { path: "/chapter-practice", heading: /Chapter practice/i },
  { path: "/pyq", heading: /Previous-year questions/i },
  { path: "/profile", heading: /Your profile/i },
];

for (const route of staticRouteShells) {
  test(`\${route.path} renders its route shell on direct navigation`, async ({ page }) => {
    await page.goto(route.path);
    await expect(page.getByRole("heading", { name: route.heading }).first()).toBeVisible();
  });
}

test("login route is directly reachable", async ({ page }) => {
  await page.goto("/login");
  await expect(page.getByRole("heading", { name: /sign in/i })).toBeVisible();
});
