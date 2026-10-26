import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  poweredByHeader: false,
  reactStrictMode: true,
  // Playwright uses this loopback host for the local development server.
  allowedDevOrigins: ["127.0.0.1"],
};

export default nextConfig;
