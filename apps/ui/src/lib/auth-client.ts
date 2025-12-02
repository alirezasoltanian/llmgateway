import {
	genericOAuthClient,
	passkeyClient,
	phoneNumberClient,
} from "better-auth/client/plugins";
import { createAuthClient } from "better-auth/react";
import { useMemo } from "react";

import { useAppConfig } from "./config";

// React hook to get the auth client
export function useAuthClient() {
	const config = useAppConfig();

	return useMemo(() => {
		return createAuthClient({
			baseURL:
				process.env.NODE_ENV === "production"
					? process.env.SOLOP_APP_URL
					: config.apiUrl + "/auth",
			plugins:
				process.env.NODE_ENV === "production"
					? [phoneNumberClient(), genericOAuthClient()]
					: [passkeyClient()],
		});
	}, [config.apiUrl]);
}

// React hook for auth methods
export function useAuth() {
	const authClient = useAuthClient();

	return useMemo(
		() => ({
			signIn: authClient.signIn,
			signUp: authClient.signUp,
			signOut: authClient.signOut,
			useSession: authClient.useSession,
			getSession: authClient.getSession,
		}),
		[authClient],
	);
}
