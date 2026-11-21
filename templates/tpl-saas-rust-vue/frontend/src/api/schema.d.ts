/**
 * Starter OpenAPI schema placeholder.
 * Always regenerate via `just gen-api` after backend OpenAPI changes.
 */
export interface paths {
  '/api/health': {
    get: {
      responses: {
        200: { content: { 'application/json': components['schemas']['HealthResponse'] } }
        503: { content: { 'application/json': components['schemas']['HealthResponse'] } }
      }
    }
  }
  '/api/auth/register': {
    post: {
      requestBody: { content: { 'application/json': components['schemas']['RegisterRequest'] } }
      responses: {
        201: { content: { 'application/json': components['schemas']['UserResponse'] } }
        409: { content: { 'application/json': components['schemas']['ErrorBody'] } }
        422: { content: { 'application/json': components['schemas']['ErrorBody'] } }
      }
    }
  }
  '/api/auth/login': {
    post: {
      requestBody: { content: { 'application/json': components['schemas']['LoginRequest'] } }
      responses: {
        200: { content: { 'application/json': components['schemas']['UserResponse'] } }
        401: { content: { 'application/json': components['schemas']['ErrorBody'] } }
      }
    }
  }
  '/api/auth/logout': {
    post: {
      responses: {
        204: { content?: never }
      }
    }
  }
  '/api/auth/me': {
    get: {
      responses: {
        200: { content: { 'application/json': components['schemas']['UserResponse'] } }
        401: { content: { 'application/json': components['schemas']['ErrorBody'] } }
      }
    }
  }
}

export interface components {
  schemas: {
    HealthResponse: { status: string; db: string }
    RegisterRequest: { email: string; name: string; password: string }
    LoginRequest: { email: string; password: string }
    UserResponse: { id: string; email: string; name: string; created_at: string }
    ErrorDetail: { code: string; message: string }
    ErrorBody: { error: components['schemas']['ErrorDetail'] }
  }
}
