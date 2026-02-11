/**
 * useJWTLogin hook - Integrates with new JWT-based auth API
 * Handles login, token storage, and user session management
 */

import { useState } from "react";
import { useNavigate } from "react-router-dom";
import useAuthStore from "@/stores/authStore";
import { AuthAPIClient } from "@/utils/authAPIClient";

export const useJWTLogin = () => {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();
  const { setAuthTokens } = useAuthStore();

  const login = async (username: string, password: string) => {
    setIsLoading(true);
    setError(null);

    try {
      // Call backend login endpoint
      const response = await AuthAPIClient.login(username, password);

      // Store tokens and user data in Zustand store
      setAuthTokens(
        response.access_token,
        response.refresh_token,
        response.user
      );

      // Redirect to app
      navigate("/app", { replace: true });
      return response;
    } catch (err: any) {
      const errorMessage = err.message || "Login failed";
      setError(errorMessage);
      throw err;
    } finally {
      setIsLoading(false);
    }
  };

  return { login, isLoading, error };
};
