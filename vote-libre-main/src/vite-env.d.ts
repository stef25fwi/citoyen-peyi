/// <reference types="vite/client" />

interface ImportMetaEnv {
	readonly CP_FIREBASE_API_KEY?: string;
	readonly CP_FIREBASE_AUTH_DOMAIN?: string;
	readonly CP_FIREBASE_PROJECT_ID?: string;
	readonly CP_FIREBASE_STORAGE_BUCKET?: string;
	readonly CP_FIREBASE_MESSAGING_SENDER_ID?: string;
	readonly CP_FIREBASE_APP_ID?: string;
	readonly CP_FIREBASE_ENFORCE_ROLE_GUARDS?: string;
	readonly CP_API_BASE_URL?: string;
}

interface ImportMeta {
	readonly env: ImportMetaEnv;
}
