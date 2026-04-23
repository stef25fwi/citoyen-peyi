# vote-libre-main

Application front Vite/React pour administrer des sondages, valider des inscriptions et permettre l'acces au vote via QR code ou code manuel.

## Prerequis Firebase

Renseigner les variables presentes dans `.env.example`.

Activer dans Firebase Authentication la methode `Anonymous`.

Si vous voulez activer les gardes de roles cote front, positionner `VITE_FIREBASE_ENFORCE_ROLE_GUARDS=true` et fournir des custom claims Firebase.

Claims attendus:

- `role: "admin"` ou `admin: true`
- `role: "controller"` ou `controller: true`

Claims emis par le backend de confiance:

- `POST /api/auth/controller/exchange` -> `role: "controller"`, `controller: true`, `controleurCodeId`, `communeCode`
- `POST /api/auth/admin/exchange` -> `role: "admin"`, `admin: true`, `adminScope: "global"`

Cette session Firebase minimale est utilisee pour fournir une identite Firestore des le chargement de l'application, y compris pour le parcours de vote public.

## Backend de confiance

Le backend Express dans `app/backend` doit etre configure avec Firebase Admin pour emettre les custom tokens:

- `FIREBASE_ADMIN_PROJECT_ID`
- `FIREBASE_ADMIN_CLIENT_EMAIL`
- `FIREBASE_ADMIN_PRIVATE_KEY`
- `CORS_ORIGIN`
- `ADMIN_ACCESS_KEY` pour l'echange administrateur

Le front utilise `VITE_API_BASE_URL` pour appeler ce backend.

## Limite actuelle

Le parcours controleur et la connexion administrateur peuvent maintenant passer par le backend de confiance. La securite effective depend toujours de la configuration reelle de Firebase Admin, de `ADMIN_ACCESS_KEY` et de l'activation des gardes de roles cote front.

## Commandes utiles

- `npm install`
- `npm run build`
- `npm run dev`
