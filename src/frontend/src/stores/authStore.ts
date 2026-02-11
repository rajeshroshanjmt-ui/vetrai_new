// authStore.ts - Zustand auth store with JWT token management

import { create } from "zustand";
import { persist } from "zustand/middleware";
import {
  VETRAI_ACCESS_TOKEN,
  VETRAI_API_TOKEN,
  VETRAI_REFRESH_TOKEN,
} from "@/constants/constants";
import type { AuthStoreType } from "@/types/zustand/auth";
import { cookieManager } from "@/utils/cookie-manager";

interface User {
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

const useAuthStore = create<AuthStoreType>(
  persist(
    (set, get) => ({
      isAdmin: false,
      isAuthenticated: false,
      accessToken: null,
      refreshToken: null,
      userData: null,
      autoLogin: null,
      apiKey: null,
      authenticationErrorCount: 0,

      setIsAdmin: (isAdmin) => set({ isAdmin }),
      setIsAuthenticated: (isAuthenticated) => set({ isAuthenticated }),
      setAccessToken: (accessToken) => set({ accessToken }),
      setRefreshToken: (refreshToken) => set({ refreshToken }),
      setUserData: (userData) => set({ userData }),
      setAutoLogin: (autoLogin) => set({ autoLogin }),
      setApiKey: (apiKey) => set({ apiKey }),
      setAuthenticationErrorCount: (authenticationErrorCount) =>
        set({ authenticationErrorCount }),

      // Set tokens and user data from login response
      setAuthTokens: (accessToken: string, refreshToken: string, userData: User) => {
        set({
          accessToken,
          refreshToken,
          userData,
          isAuthenticated: true,
          isAdmin: userData.is_superuser,
        });
        // Store tokens in localStorage for persistence
        localStorage.setItem(VETRAI_ACCESS_TOKEN, accessToken);
        localStorage.setItem(VETRAI_REFRESH_TOKEN, refreshToken);
      },

      logout: async () => {
        // Clear local storage
        localStorage.removeItem(VETRAI_ACCESS_TOKEN);
        localStorage.removeItem(VETRAI_API_TOKEN);
        localStorage.removeItem(VETRAI_REFRESH_TOKEN);

        // Clear cookies
        cookieManager.clearAuthCookies();

        // Reset state
        set({
          isAdmin: false,
          userData: null,
          accessToken: null,
          refreshToken: null,
          isAuthenticated: false,
          autoLogin: false,
          apiKey: null,
        });
      },

      // Initialize store from localStorage on app load
      initializeAuth: () => {
        const storedAccessToken = localStorage.getItem(VETRAI_ACCESS_TOKEN);
        const storedRefreshToken = localStorage.getItem(VETRAI_REFRESH_TOKEN);
        
        if (storedAccessToken && storedRefreshToken) {
          set({
            accessToken: storedAccessToken,
            refreshToken: storedRefreshToken,
            isAuthenticated: true,
          });
        }
      },
    }),
    {
      name: "auth-store",
    }
  )
);

export default useAuthStore;
