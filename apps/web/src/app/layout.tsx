import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'YDBI',
  description: 'Your Digital Butler Intelligence',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}