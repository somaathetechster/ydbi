export interface AuthTokens {
  accessToken: string
  refreshToken: string
  expiresIn: number
}

export interface JwtPayload {
  sub: string      // user id
  email: string
  tier: string
  iat: number
  exp: number
}