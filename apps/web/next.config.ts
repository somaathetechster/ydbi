import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  transpilePackages: ['@ydbi/sdk', '@ydbi/ui-tokens'],
  experimental: {
    // Enable when needed: ppr: true, taint: true
  },
}

export default nextConfig