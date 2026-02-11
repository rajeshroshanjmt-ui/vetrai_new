import * as Form from "@radix-ui/react-form";
import { useContext, useState } from "react";
import VetraiLogo from "@/assets/VetraiLogo.svg?react";
import { CustomLink } from "@/customization/components/custom-link";
import InputComponent from "../../components/core/parameterRenderComponent/components/inputComponent";
import { Button } from "../../components/ui/button";
import { Input } from "../../components/ui/input";
import { CONTROL_LOGIN_STATE } from "../../constants/constants";
import useAlertStore from "../../stores/alertStore";
import { useJWTLogin } from "@/hooks/useJWTLogin";
import type {
  inputHandlerEventType,
  loginInputStateType,
} from "../../types/components";

export default function LoginPage(): JSX.Element {
  const [inputState, setInputState] =
    useState<loginInputStateType>(CONTROL_LOGIN_STATE);

  const { password, username } = inputState;
  const { login, isLoading, error: loginError } = useJWTLogin();
  const setErrorData = useAlertStore((state) => state.setErrorData);

  function handleInput({
    target: { name, value },
  }: inputHandlerEventType): void {
    setInputState((prev) => ({ ...prev, [name]: value }));
  }

  async function signIn() {
    if (!username.trim() || !password.trim()) {
      setErrorData({
        title: "Login Error",
        list: ["Please enter both username and password"],
      });
      return;
    }

    try {
      await login(username.trim(), password.trim());
    } catch (error: any) {
      setErrorData({
        title: "Login Error",
        list: [loginError || "Login failed. Please try again."],
      });
    }
  }

  return (
    <Form.Root
      onSubmit={async (event) => {
        event.preventDefault();
        if (password === "") {
          return;
        }
        await signIn();
      }}
      className="h-screen w-full"
    >
      <div className="flex h-full w-full">
        {/* Left Side - Login Form */}
        <div className="flex w-1/2 flex-col items-center justify-center bg-white px-8">
          <div className="w-full max-w-md">
            <div className="mb-8 flex flex-col items-center">
              <VetraiLogo
                title="Vetrai logo"
                className="mb-4 h-12 w-12 scale-[1.5]"
              />
              <h1 className="mb-2 text-3xl font-bold text-slate-900">
                Welcome Back
              </h1>
              <p className="text-center text-slate-600">
                Sign in to your account to continue
              </p>
            </div>

            {/* Username Field */}
            <div className="mb-4">
              <Form.Field name="username">
                <Form.Label className="mb-2 block text-sm font-semibold text-slate-700 data-[invalid]:label-invalid">
                  Username <span className="font-medium text-red-500">*</span>
                </Form.Label>

                <Form.Control asChild>
                  <Input
                    type="username"
                    onChange={({ target: { value } }) => {
                      handleInput({ target: { name: "username", value } });
                    }}
                    value={username}
                    className="w-full rounded-lg border border-slate-300 px-4 py-2 transition-all focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-200"
                    required
                    placeholder="Enter your username"
                  />
                </Form.Control>

                <Form.Message match="valueMissing" className="mt-1 text-sm text-red-500">
                  Please enter your username
                </Form.Message>
              </Form.Field>
            </div>

            {/* Password Field */}
            <div className="mb-6">
              <Form.Field name="password">
                <Form.Label className="mb-2 block text-sm font-semibold text-slate-700 data-[invalid]:label-invalid">
                  Password <span className="font-medium text-red-500">*</span>
                </Form.Label>

                <InputComponent
                  onChange={(value) => {
                    handleInput({ target: { name: "password", value } });
                  }}
                  value={password}
                  isForm
                  password={true}
                  required
                  placeholder="Enter your password"
                  className="w-full rounded-lg border border-slate-300 px-4 py-2 transition-all focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-200"
                />

                <Form.Message className="mt-1 text-sm text-red-500" match="valueMissing">
                  Please enter your password
                </Form.Message>
              </Form.Field>
            </div>

            {/* Sign In Button */}
            <div className="mb-4 w-full">
              <Form.Submit asChild>
                <Button 
                  disabled={isLoading}
                  className="w-full rounded-lg bg-blue-600 py-2.5 font-semibold text-white transition-all hover:bg-blue-700 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isLoading ? "Signing in..." : "Sign in"}
                </Button>
              </Form.Submit>
            </div>

            {/* Sign Up Link */}
            <div className="w-full">
              <CustomLink to="/signup">
                <Button 
                  className="w-full rounded-lg border-2 border-slate-300 py-2.5 font-semibold text-slate-700 transition-all hover:border-blue-500 hover:bg-blue-50"
                  variant="outline" 
                  type="button"
                >
                  Don't have an account?&nbsp;<span className="font-bold text-blue-600">Sign Up</span>
                </Button>
              </CustomLink>
            </div>

            {/* Footer */}
            <p className="mt-6 text-center text-xs text-slate-500">
              By signing in, you agree to our Terms of Service and Privacy Policy
            </p>
          </div>
        </div>

        {/* Right Side - Product Description */}
        <div className="flex w-1/2 flex-col items-center justify-center bg-gradient-to-br from-blue-600 via-blue-500 to-blue-700 px-8 text-white">
          <div className="w-full max-w-md">
            <div className="mb-12">
              <h2 className="mb-4 text-4xl font-bold">VetRAI</h2>
              <p className="mb-6 text-lg font-light leading-relaxed opacity-90">
                Your intelligent AI-powered platform for veterinary care management and analysis
              </p>
            </div>

            {/* Features */}
            <div className="space-y-4">
              <FeatureItem
                icon="🤖"
                title="AI-Powered Analytics"
                description="Advanced machine learning insights for better decision making"
              />
              <FeatureItem
                icon="🏥"
                title="Complete Management"
                description="Manage patients, treatments, and records all in one place"
              />
              <FeatureItem
                icon="📊"
                title="Real-time Insights"
                description="Get actionable insights with real-time data visualization"
              />
              <FeatureItem
                icon="🔒"
                title="Secure & Compliant"
                description="Enterprise-grade security for healthcare data protection"
              />
              <FeatureItem
                icon="⚡"
                title="Fast & Reliable"
                description="Built for performance with 99.9% uptime guarantee"
              />
            </div>

            {/* Bottom CTA */}
            <div className="mt-12 rounded-lg bg-white/10 p-4 backdrop-blur-sm">
              <p className="text-sm font-medium">🚀 New to VetRAI?</p>
              <p className="text-xs opacity-90">
                Join thousands of veterinary professionals using VetRAI to transform their practice
              </p>
            </div>
          </div>
        </div>
      </div>
    </Form.Root>
  );
}

function FeatureItem({
  icon,
  title,
  description,
}: {
  icon: string;
  title: string;
  description: string;
}): JSX.Element {
  return (
    <div className="flex items-start gap-3 rounded-lg bg-white/10 p-3 backdrop-blur-sm">
      <span className="mt-1 text-xl">{icon}</span>
      <div>
        <p className="font-semibold">{title}</p>
        <p className="text-sm opacity-80">{description}</p>
      </div>
    </div>
  );
}
