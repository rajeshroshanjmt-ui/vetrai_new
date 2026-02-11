/**
 * Auth API Client - handles login, refresh, and user context calls
 * Integrates with the new JWT-based backend auth system
 */

const API_BASE = process.env.REACT_APP_API_URL || "http://localhost:7860";
const AUTH_BASE = `${API_BASE}/api/auth`;

export interface LoginResponse {
  access_token: string;
  refresh_token: string;
  user: {
    id: number;
    username: string;
    email: string;
    full_name: string | null;
    is_active: boolean;
    is_superuser: boolean;
    org_id: number;
    role: string;
    created_at: string;
  };
}

export interface User {
  id: number;
  username: string;
  email: string;
  full_name: string | null;
  is_active: boolean;
  is_superuser: boolean;
  org_id: number;
  role: string;
  created_at: string;
}

export class AuthAPIClient {
  /**
   * Login with username and password
   */
  static async login(username: string, password: string): Promise<LoginResponse> {
    const response = await fetch(`${AUTH_BASE}/login`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ username, password }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.detail || "Login failed");
    }

    return response.json();
  }

  /**
   * Get current authenticated user
   */
  static async getMe(accessToken: string): Promise<User> {
    const response = await fetch(`${AUTH_BASE}/me`, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });

    if (!response.ok) {
      throw new Error("Failed to fetch current user");
    }

    return response.json();
  }

  /**
   * Refresh access token
   */
  static async refreshToken(refreshToken: string): Promise<{ access_token: string; refresh_token: string }> {
    const response = await fetch(`${AUTH_BASE}/refresh`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ refresh_token: refreshToken }),
    });

    if (!response.ok) {
      throw new Error("Failed to refresh token");
    }

    return response.json();
  }

  /**
   * Logout (revoke tokens on backend)
   */
  static async logout(accessToken: string): Promise<void> {
    await fetch(`${AUTH_BASE}/logout`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });
  }
}
