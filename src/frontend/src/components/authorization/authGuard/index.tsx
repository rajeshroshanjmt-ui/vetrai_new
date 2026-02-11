import { useEffect } from "react";
import {
  IS_AUTO_LOGIN,
  VETRAI_ACCESS_TOKEN_EXPIRE_SECONDS,
  VETRAI_ACCESS_TOKEN_EXPIRE_SECONDS_ENV,
} from "@/constants/constants";
import { CustomNavigate } from "@/customization/components/custom-navigate";
import useAuthStore from "@/stores/authStore";
import { AuthAPIClient } from "@/utils/authAPIClient";

export const ProtectedRoute = ({ children }) => {
  const { isAuthenticated, accessToken, refreshToken, setAuthTokens } = useAuthStore();
  const autoLogin = useAuthStore((state) => state.autoLogin);
  const userData = useAuthStore((state) => state.userData);
  const isAutoLoginEnv = IS_AUTO_LOGIN;
  const testMockAutoLogin = sessionStorage.getItem("testMockAutoLogin");

  const shouldRedirect =
    !isAuthenticated &&
    autoLogin !== undefined &&
    (!autoLogin || !isAutoLoginEnv);

  // Token refresh effect
  useEffect(() => {
    if (!isAuthenticated || !refreshToken) return;

    const envRefreshTime = VETRAI_ACCESS_TOKEN_EXPIRE_SECONDS_ENV;
    const automaticRefreshTime = VETRAI_ACCESS_TOKEN_EXPIRE_SECONDS;
    const refreshInterval = isNaN(envRefreshTime) ? automaticRefreshTime : envRefreshTime;

    const refreshAccessToken = async () => {
      try {
        const result = await AuthAPIClient.refreshToken(refreshToken);
        if (userData) {
          setAuthTokens(result.access_token, result.refresh_token, userData);
        }
      } catch (error) {
        // Refresh failed, redirect to login
        useAuthStore.getState().logout();
      }
    };

    const intervalId = setInterval(refreshAccessToken, refreshInterval * 1000);
    return () => clearInterval(intervalId);
  }, [isAuthenticated, refreshToken, userData, setAuthTokens]);

  if (shouldRedirect || testMockAutoLogin) {
    const currentPath = window.location.pathname;
    const isHomePath = currentPath === "/" || currentPath === "/flows";
    const isLoginPage = location.pathname.includes("login");
    return (
      <CustomNavigate
        to={
          "/login" +
          (!isHomePath && !isLoginPage ? "?redirect=" + currentPath : "")
        }
        replace
      />
    );
  } else {
    return children;
  }
};
