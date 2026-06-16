# Audit Geo API Gouv - iliprestō

**Date :** Fri Jun 12 21:45:15 UTC 2026

## 1. Projet détecté
```text
/workspaces/citoyen-peyi
## main...origin/main
?? audits/
```

## 2. Fichiers potentiellement concernés
```text
```

## 3. Occurrences détaillées

### ./.auth-flow-smoke.local.json
```text
8:  "commune": {
10:    "name": "Commune QA Citoyen Peyi"
```

### ./.firebase-ghpages-public/flutter_bootstrap.js
```text
1:(()=>{var _={blink:!0,gecko:!1,webkit:!1,unknown:!1},K=()=>navigator.vendor==="Google Inc."||navigator.userAgent.includes("Edg/")?"blink":navigator.vendor==="Apple Computer, Inc."?"webkit":navigator.vendor===""&&navigator.userAgent.includes("Firefox")?"gecko":"unknown",C=K(),R=()=>typeof ImageDecoder>"u"?!1:C==="blink",B=()=>typeof Intl.v8BreakIterator<"u"&&typeof Intl.Segmenter<"u",z=()=>{let i=[0,97,115,109,1,0,0,0,1,5,1,95,1,120,0];return WebAssembly.validate(new Uint8Array(i))},M=()=>{let i=document.createElement("canvas");return i.width=1,i.height=1,i.getContext("webgl2")!=null?2:i.getContext("webgl")!=null?1:-1},D=()=>window.chrome&&chrome.runtime&&chrome.runtime.id,w={browserEngine:C,hasImageCodecs:R(),hasChromiumBreakIterators:B(),supportsWasmGC:z(),crossOriginIsolated:window.crossOriginIsolated,webGLVersion:M(),isChromeExtension:D()};function c(...i){return new URL(I(...i),document.baseURI).toString()}function I(...i){return i.filter(e=>!!e).map((e,n)=>n===0?S(e):F(S(e))).filter(e=>e.length).join("/")}function F(i){let e=0;for(;e<i.length&&i.charAt(e)==="/";)e++;return i.substring(e)}function S(i){let e=i.length;for(;e>0&&i.charAt(e-1)==="/";)e--;return i.substring(0,e)}function E(i,e){return i.canvasKitBaseUrl?i.canvasKitBaseUrl:e.engineRevision&&!e.useLocalCanvasKit?I("https://www.gstatic.com/flutter-canvaskit",e.engineRevision):"canvaskit"}var v=class{constructor(){this._scriptLoaded=!1}setTrustedTypesPolicy(e){this._ttPolicy=e}async loadEntrypoint(e){let{entrypointUrl:n=c("main.dart.js"),onEntrypointLoaded:t,nonce:r}=e||{};return this._loadJSEntrypoint(n,t,r)}async load(e,n,t,r,a){a??=l=>{l.initializeEngine(t).then(u=>u.runApp())};let{entrypointBaseUrl:s}=t,{entryPointBaseUrl:o}=t;if(!s&&o&&(console.warn("[deprecated] `entryPointBaseUrl` is deprecated and will be removed in a future release. Use `entrypointBaseUrl` instead."),s=o),e.compileTarget==="dart2wasm")return this._loadWasmEntrypoint(e,n,s,a);{let l=e.mainJsPath??"main.dart.js",u=c(s,l);return this._loadJSEntrypoint(u,a,r)}}didCreateEngineInitializer(e){typeof this._didCreateEngineInitializerResolve=="function"&&(this._didCreateEngineInitializerResolve(e),this._didCreateEngineInitializerResolve=null,delete _flutter.loader.didCreateEngineInitializer),typeof this._onEntrypointLoaded=="function"&&this._onEntrypointLoaded(e)}_loadJSEntrypoint(e,n,t){let r=typeof n=="function";if(!this._scriptLoaded){this._scriptLoaded=!0;let a=this._createScriptTag(e,t);if(r)console.debug("Injecting <script> tag. Using callback."),this._onEntrypointLoaded=n,document.head.append(a);else return new Promise((s,o)=>{console.debug("Injecting <script> tag. Using Promises. Use the callback approach instead!"),this._didCreateEngineInitializerResolve=s,a.addEventListener("error",o),document.head.append(a)})}}async _loadWasmEntrypoint(e,n,t,r){if(!this._scriptLoaded){this._scriptLoaded=!0,this._onEntrypointLoaded=r;let{mainWasmPath:a,jsSupportRuntimePath:s}=e,o=c(t,a),l=c(t,s);this._ttPolicy!=null&&(l=this._ttPolicy.createScriptURL(l));let d=(await import(l)).compileStreaming(fetch(o)),p;e.renderer==="skwasm"?p=(async()=>{let h=await n.skwasm;return window._flutter_skwasmInstance=h,{skwasm:h.wasmExports,skwasmWrapper:h,ffi:{memory:h.wasmMemory}}})():p=Promise.resolve({}),await(await(await d).instantiate(await p,{loadDynamicModule:async(h,j)=>{let A=fetch(c(t,h)),L=c(t,j);this._ttPolicy!=null&&(L=this._ttPolicy.createScriptURL(L));let x=import(L);return[await A,await x]}})).invokeMain()}}_createScriptTag(e,n){let t=document.createElement("script");t.type="application/javascript",n&&(t.nonce=n);let r=e;return this._ttPolicy!=null&&(r=this._ttPolicy.createScriptURL(e)),t.src=r,t}};async function T(i,e,n){if(e<0)return i;let t,r=new Promise((a,s)=>{t=setTimeout(()=>{s(new Error(`${n} took more than ${e}ms to resolve. Moving on.`,{cause:T}))},e)});return Promise.race([i,r]).finally(()=>{clearTimeout(t)})}var g=class{setTrustedTypesPolicy(e){this._ttPolicy=e}loadServiceWorker(e){if(!e||!("serviceWorker"in navigator))return Promise.resolve();let n=()=>{console.warn(`Loading the service worker using Flutter bootstrap is deprecated and will stop working in a future release.
2:For more details, see: https://github.com/flutter/flutter/issues/156910`)},t=()=>{let{serviceWorkerVersion:r,serviceWorkerUrl:a=c(`flutter_service_worker.js?v=${r}`),timeoutMillis:s=4e3}=e,o=a;this._ttPolicy!=null&&(o=this._ttPolicy.createScriptURL(o));let l=navigator.serviceWorker.register(o).then(u=>this._getNewServiceWorker(u,r)).then(this._waitForServiceWorkerActivation);return T(l,s,"prepareServiceWorker")};return e.serviceWorkerUrl!=null?(n(),t()):navigator.serviceWorker.getRegistration().then(r=>r?t():Promise.resolve())}async _getNewServiceWorker(e,n){if(!e.active&&(e.installing||e.waiting))return console.debug("Installing/Activating first service worker."),e.installing||e.waiting;if(e.active.scriptURL.endsWith(n))return console.debug("Loading from existing service worker."),e.active;{let t=await e.update();return console.debug("Updating service worker."),t.installing||t.waiting||t.active}}async _waitForServiceWorkerActivation(e){if(!e||e.state==="activated")if(e){console.debug("Service worker already active.");return}else throw new Error("Cannot activate a null service worker!");return new Promise((n,t)=>{e.addEventListener("statechange",()=>{e.state==="activated"&&(console.debug("Activated new service worker."),n())})})}};var y=class{constructor(e,n="flutter-js"){let t=e||[/\.js$/,/\.mjs$/];window.trustedTypes&&(this.policy=trustedTypes.createPolicy(n,{createScriptURL:function(r){if(r.startsWith("blob:"))return r;let a=new URL(r,window.location),s=a.pathname.split("/").pop();if(t.some(l=>l.test(s)))return a.toString();console.error("URL rejected by TrustedTypes policy",n,":",r,"(download prevented)")}}))}};var k=i=>{let e=WebAssembly.compileStreaming(fetch(i));return(n,t)=>((async()=>{let r=await e,a=await WebAssembly.instantiate(r,n);t(a,r)})(),{})};var U=(i,e,n,t)=>(window.flutterCanvasKitLoaded=(async()=>{if(window.flutterCanvasKit)return window.flutterCanvasKit;let r=n.hasChromiumBreakIterators&&n.hasImageCodecs;if(!r&&e.canvasKitVariant=="chromium")throw"Chromium CanvasKit variant specifically requested, but unsupported in this browser";let a=r&&e.canvasKitVariant!=="full",s=t;e.canvasKitVariant=="experimentalWebParagraph"?s=c(s,"experimental_webparagraph"):a&&(s=c(s,"chromium"));let o=c(s,"canvaskit.js");i.flutterTT.policy&&(o=i.flutterTT.policy.createScriptURL(o));let l=k(c(s,"canvaskit.wasm")),u=await import(o);return window.flutterCanvasKit=await u.default({instantiateWasm:l}),window.flutterCanvasKit})(),window.flutterCanvasKitLoaded);var W=async(i,e,n,t)=>{let a=!n.hasImageCodecs||!n.hasChromiumBreakIterators?"skwasm_heavy":e.enableWimp?"wimp":"skwasm",s=c(t,`${a}.js`),o=s;i.flutterTT.policy&&(o=i.flutterTT.policy.createScriptURL(o));let l=k(c(t,`${a}.wasm`));return await(await import(o)).default({skwasmSingleThreaded:e.enableWimp||!n.crossOriginIsolated||n.isChromeExtension||e.forceSingleThreadedSkwasm,instantiateWasm:l,locateFile:(d,p)=>d.endsWith(".ww.js")?URL.createObjectURL(new Blob([`
```

### ./.firebase-ghpages-public/manifest.json
```text
5:  "display": "standalone",
10:  "prefer_related_applications": false,
```

### ./.github/workflows/ci.yml
```text
11:    runs-on: ubuntu-latest
81:    runs-on: ubuntu-latest
96:    name: Firestore rules (emulator)
97:    runs-on: ubuntu-latest
112:      - name: Run rules unit tests against emulator
114:        run: firebase emulators:exec --only firestore --project demo-citoyen-peyi "npm test"
```

### ./.github/workflows/deploy-backend.yml
```text
2:# NB: le secret GCP_RUNTIME_SERVICE_ACCOUNT doit pointer vers un SA existant que
3:# GCP_DEPLOY_SERVICE_ACCOUNT peut "actAs" (roles/iam.serviceAccountUser), sinon
8:# Les secrets sont montes en ":latest" : une rotation (nouvelle version) n'est prise
28:    runs-on: ubuntu-latest
41:    runs-on: ubuntu-latest
44:      GCP_PROJECT_ID: ${{ vars.GCP_PROJECT_ID }}
45:      GCP_REGION: ${{ vars.GCP_REGION }}
49:      GCP_WORKLOAD_IDENTITY_PROVIDER: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
50:      GCP_DEPLOY_SERVICE_ACCOUNT: ${{ secrets.GCP_DEPLOY_SERVICE_ACCOUNT }}
51:      GCP_RUNTIME_SERVICE_ACCOUNT: ${{ secrets.GCP_RUNTIME_SERVICE_ACCOUNT }}
58:          for name in GCP_PROJECT_ID GCP_REGION CORS_ORIGIN GCP_WORKLOAD_IDENTITY_PROVIDER GCP_DEPLOY_SERVICE_ACCOUNT GCP_RUNTIME_SERVICE_ACCOUNT; do
72:          workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
73:          service_account: ${{ secrets.GCP_DEPLOY_SERVICE_ACCOUNT }}
78:          project_id: ${{ vars.GCP_PROJECT_ID }}
82:          # Defense contre un secret GCP_RUNTIME_SERVICE_ACCOUNT contenant un
86:          clean="$(printf '%s' "$GCP_RUNTIME_SERVICE_ACCOUNT" | tr -d '[:space:]')"
88:            echo "::error::GCP_RUNTIME_SERVICE_ACCOUNT est vide apres nettoyage." >&2
91:          echo "GCP_RUNTIME_SERVICE_ACCOUNT=$clean" >> "$GITHUB_ENV"
113:          fix_cmd="gcloud iam service-accounts add-iam-policy-binding $GCP_RUNTIME_SERVICE_ACCOUNT --member=\"serviceAccount:$GCP_DEPLOY_SERVICE_ACCOUNT\" --role=\"roles/iam.serviceAccountUser\" --project=$GCP_PROJECT_ID"
114:          if ! policy="$(gcloud iam service-accounts get-iam-policy "$GCP_RUNTIME_SERVICE_ACCOUNT" --format=json 2>/dev/null)"; then
119:             echo "$policy" | grep -q "serviceAccount:$GCP_DEPLOY_SERVICE_ACCOUNT"; then
135:        run: gcloud auth configure-docker "$GCP_REGION-docker.pkg.dev" --quiet
140:            --location="$GCP_REGION" >/dev/null 2>&1 || \
143:            --location="$GCP_REGION" \
149:          IMAGE="$GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/citoyen-peyi/backend:${{ github.sha }}"
160:          ENV_VARS="^@^NODE_ENV=production@CORS_ORIGIN=$CORS_ORIGIN@LOG_LEVEL=info@GOOGLE_CLOUD_PROJECT=$GCP_PROJECT_ID"
168:          SECRET_BINDINGS="SUPER_ADMIN_KEY=SUPER_ADMIN_KEY:latest,VOTE_ACCESS_TOKEN_SECRET=VOTE_ACCESS_TOKEN_SECRET:latest,ACCESS_CODE_PEPPER=ACCESS_CODE_PEPPER:latest,CITIZEN_FINGERPRINT_PEPPER=CITIZEN_FINGERPRINT_PEPPER:latest,PARTICIPATION_PEPPER=PARTICIPATION_PEPPER:latest"
171:              SECRET_BINDINGS="$SECRET_BINDINGS,$optional_secret=$optional_secret:latest"
178:            --region="$GCP_REGION" \
179:            --platform=managed \
181:            --service-account="$GCP_RUNTIME_SERVICE_ACCOUNT" \
187:            --cpu=1 \
194:              echo "  gcloud iam service-accounts add-iam-policy-binding $GCP_RUNTIME_SERVICE_ACCOUNT --member=\"serviceAccount:$GCP_DEPLOY_SERVICE_ACCOUNT\" --role=\"roles/iam.serviceAccountUser\" --project=$GCP_PROJECT_ID" >&2
201:          SERVICE_URL="$(gcloud run services describe citoyen-peyi-backend --region="$GCP_REGION" --format='value(status.url)')"
```

### ./.github/workflows/deploy-firebase-hosting.yml
```text
22:    runs-on: ubuntu-latest
37:          workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
38:          service_account: ${{ secrets.GCP_DEPLOY_SERVICE_ACCOUNT }}
```

### ./.github/workflows/deploy-firestore-rules.yml
```text
16:    runs-on: ubuntu-latest
35:          workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
36:          service_account: ${{ secrets.GCP_DEPLOY_SERVICE_ACCOUNT }}
```

### ./.github/workflows/deploy-pages.yml
```text
20:    runs-on: ubuntu-latest
69:          cp build/web/index.html build/web/404.html
81:    runs-on: ubuntu-latest
```

### ./.vscode/tasks.json
```text
117:        "export PATH=\"$HOME/flutter/bin:$PATH\"; cd flutter_app && flutter create . --platforms=web"
125:      "detail": "Genere les fichiers plateforme Flutter Web autour du squelette existant."
346:        "cd /workspaces/citoyen-peyi/tests/firestore-rules && npm install --no-package-lock && npx --yes firebase-tools@13 emulators:exec --only firestore --project demo-citoyen-peyi \"npm test\"; status=$?; rm -rf node_modules; exit $status"
354:      "detail": "Lance les tests unitaires des regles Firestore via emulateur."
```

### ./OPERATIONS.md
```text
6:- **Projet GCP** : `citoyen-peyi`
7:- **Région** : `europe-west1`
50:| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Fournisseur WIF pour l'auth CI |
51:| `GCP_DEPLOY_SERVICE_ACCOUNT` | `github-deploy@…` (sans espace/retour parasite !) |
52:| `GCP_RUNTIME_SERVICE_ACCOUNT` | `1087566305566-compute@…` (sans espace/retour parasite !) |
57:| `GCP_PROJECT_ID` | `citoyen-peyi` |
58:| `GCP_REGION` | `europe-west1` |
87:Les secrets sont montés en `:latest` → **une rotation n'est prise en compte qu'au
100:gcloud secrets versions access latest --secret=SUPER_ADMIN_KEY --project=citoyen-peyi
102:# 3. Redéployer pour activer :latest (Run workflow ou push backend)
143:# Option A — Memorystore (Redis géré GCP, même région)
145:  --size=1 --region=europe-west1 --redis-version=redis_7_0 \
161:Le `HEALTHCHECK` du Dockerfile est **ignoré** par Cloud Run (qui fait un probe TCP par
165:gcloud run deploy citoyen-peyi-backend --region=europe-west1 --project=citoyen-peyi \
```

### ./README.md
```text
8:- script pour generer un ZIP complet du projet
13:- `app/scripts/`: utilitaires (zip)
16:- `tests/firestore-rules/`: tests unitaires des regles Firestore (emulateur)
25:## Installation
33:	cp .env.example .env
53:- `SUPER_ADMIN_KEY`: cle longue et aleatoire exigee dans le header `x-super-admin-key` pour les routes super administrateur.
76:# Long random strings. NEVER commit, NEVER reuse across environments.
150:Les builds de production refusent volontairement `http://localhost:4000` afin
153:## Creer le ZIP complet de l'app
155:npm run zip
159:app-release.zip
229:	"communeName": "Fort-de-France",
```

### ./app/backend/src/index.js
```text
47:      res.status(503).json({ message: 'Requete trop longue, reessayez.' });
```

### ./app/backend/src/middlewares/rateLimit.js
```text
37:  // faible mais reste fonctionnelle (max-instances volontairement bas). On
```

### ./app/backend/src/middlewares/requireFirebaseAuth.js
```text
27:export const isCommuneAdmin = (user) => hasRole(user, 'admin') || hasRole(user, 'commune_admin') || isSuperAdmin(user);
43:export const communeScopeFromUser = (user) => {
44:  if (typeof user?.communeId === 'string' && user.communeId.trim()) return user.communeId.trim();
45:  if (typeof user?.communeCode === 'string' && user.communeCode.trim()) return user.communeCode.trim();
55:export const requireCommuneAdmin = requireRole(isCommuneAdmin, 'Reserve aux administrateurs communaux.');
```

### ./app/backend/src/routes/admins.js
```text
10:const COLLECTION = 'communeAdmins';
40:          communeName: data.communeName,
41:          communeCode: data.communeCode,
42:          codePostal: data.codePostal,
56:    const communeName = sanitize(req.body?.communeName, 200);
57:    const communeCode = sanitize(req.body?.communeCode, 64);
58:    const codePostal = sanitize(req.body?.codePostal, 16);
60:    if (!label || !communeName) {
61:      return res.status(400).json({ message: 'Libelle et commune sont requis.' });
71:      communeName,
72:      communeCode,
73:      codePostal,
82:      communeName,
83:      communeCode,
84:      codePostal,
```

### ./app/backend/src/routes/auth.js
```text
124:      communeCode: record.commune?.code || '',
125:      communeId: record.commune?.code || record.commune?.name || '',
134:        commune: record.commune ?? null,
167:    let snapshot = await db.collection('communeAdmins').where('accessKeyHash', '==', accessKeyHash).limit(1).get();
170:      const legacySnapshot = await db.collection('communeAdmins').where('accessKeyHash', '==', hashLegacySha256(providedAccessKey)).limit(1).get();
174:        snapshot = await db.collection('communeAdmins').where('accessKeyHash', '==', accessKeyHash).limit(1).get();
179:    let communeId = '';
180:    let communeName = '';
182:    let adminScope = 'commune';
191:      communeId = data.communeCode || data.communeName || '';
192:      communeName = data.communeName || '';
208:      role: 'commune_admin',
211:      communeId,
212:      communeCode: communeId,
218:      profile: { id: adminId, label, communeId, communeName },
```

### ./app/backend/src/routes/citizenAccess.js
```text
70:  // augmenter la finesse de l'empreinte et reduire les faux doublons.
139:  communeId: data.communeId,
140:  communeName: data.communeName,
157:  communeId: data.communeId,
158:  communeName: data.communeName,
186:  const communeId = data.commune?.code || data.commune?.name || user?.communeCode || '';
187:  const tokenCommune = user?.communeId || user?.communeCode || '';
188:  if (tokenCommune && communeId && tokenCommune !== communeId) return null;
193:    communeId: communeId || 'unknown-commune',
194:    communeName: data.commune?.name || user?.communeCode || 'Commune non renseignee',
220:    communeId: payload.communeId,
221:    communeName: payload.communeName,
252:    // "all_open_polls" (toutes les consultations ouvertes de la commune).
275:        const existingAccessCodeId = fingerprint.latestAccessCodeId || fingerprint.firstAccessCodeId || '';
290:          communeId: controller.communeId,
291:          communeName: controller.communeName,
327:        communeId: controller.communeId,
328:        communeName: controller.communeName,
353:        latestAccessCodeId: accessRef.id,
354:        communeId: controller.communeId,
398:      if (req.query.communeId) query = query.where('communeId', '==', String(req.query.communeId));
411:    return res.status(500).json({ message: 'Lecture des demandes doublon impossible.' });
447:      const previousCodeId = fingerprint.latestAccessCodeId || request.existingAccessCodeId;
464:        communeId: request.communeId,
465:        communeName: request.communeName,
492:        latestAccessCodeId: newAccessRef.id,
506:        communeId: request.communeId,
507:        communeName: request.communeName,
551:      communeId: request.communeId,
552:      communeName: request.communeName,
611:      if (req.query.communeId) query = query.where('communeId', '==', String(req.query.communeId));
```

### ./app/backend/src/routes/controllers.js
```text
6:  communeScopeFromUser,
8:  requireCommuneAdmin,
53:    commune: data.commune,
74:  const scope = communeScopeFromUser(req.user);
75:  if (data.commune?.code !== scope) {
76:    res.status(403).json({ message: 'Ce controleur appartient a une autre commune.' });
93:router.use(ensureConfigured, requireFirebaseAuth, requireCommuneAdmin);
95:const resolveCommuneScope = (req) => {
98:      communeName: sanitize(req.body?.communeName, 200),
99:      communeCode: sanitize(req.body?.communeCode, 64),
100:      codePostal: sanitize(req.body?.codePostal, 16),
104:    communeName: sanitize(req.body?.communeName, 200) || communeScopeFromUser(req.user),
105:    communeCode: communeScopeFromUser(req.user),
106:    codePostal: sanitize(req.body?.codePostal, 16),
115:      const scope = communeScopeFromUser(req.user);
116:      if (!scope) return res.status(403).json({ message: 'Aucune commune attachee au compte.' });
117:      query = query.where('commune.code', '==', scope);
135:    const scope = resolveCommuneScope(req);
136:    if (!scope.communeName) {
137:      return res.status(400).json({ message: 'Commune requise pour creer un controleur.' });
147:      commune: {
148:        name: scope.communeName,
149:        code: scope.communeCode,
150:        codePostal: scope.codePostal,
```

### ./app/backend/src/routes/news.js
```text
6:  communeScopeFromUser,
8:  requireCommuneAdmin,
24:router.use(ensureConfigured, requireFirebaseAuth, requireCommuneAdmin);
33:    const communeId = isSuperAdmin(req.user)
34:      ? sanitize(req.body?.communeId, 64)
35:      : communeScopeFromUser(req.user);
36:    const communeName = sanitize(req.body?.communeName, 200);
44:      communeId,
45:      communeName,
63:    if (!isSuperAdmin(req.user) && communeScopeFromUser(req.user) && data.communeId !== communeScopeFromUser(req.user)) {
83:    if (!isSuperAdmin(req.user) && communeScopeFromUser(req.user) && data.communeId !== communeScopeFromUser(req.user)) {
```

### ./app/backend/src/routes/notifications.js
```text
22:    communeId: data.communeId || '',
23:    communeName: data.communeName || '',
44:  const platform = typeof req.body?.platform === 'string' ? req.body.platform.trim() : 'web';
64:      platform,
70:      communeId: access.communeId,
71:      communeName: access.communeName,
```

### ./app/backend/src/routes/polls.js
```text
6:  communeScopeFromUser,
7:  isCommuneAdmin,
9:  requireCommuneAdmin,
12:import { notifyCommunePollPublished } from '../services/notificationService.js';
78:const scopeFromAdmin = (user) => (isSuperAdmin(user) ? '' : communeScopeFromUser(user));
80:const requireMatchingCommune = (req, res, next) => {
82:  const scope = communeScopeFromUser(req.user);
84:    return res.status(403).json({ message: 'Aucune commune attachee au compte administrateur.' });
86:  req.communeScope = scope;
90:router.use(ensureConfigured, requireFirebaseAuth, requireCommuneAdmin);
97:    if (scope) query = query.where('communeId', '==', scope);
106:router.post('/', requireMatchingCommune, async (req, res, next) => {
126:    const communeId = req.communeScope || sanitizeString(req.body?.communeId, 64);
127:    const communeName = sanitizeString(req.body?.communeName, 200);
136:      targetPopulation: sanitizeString(req.body?.targetPopulation, 300),
141:      communeId,
142:      communeName,
152:    await notifyCommunePollPublished({ db, poll: responsePoll });
168:  if (!isSuperAdmin(req.user) && communeScopeFromUser(req.user) && data.communeId !== communeScopeFromUser(req.user)) {
169:    res.status(403).json({ message: 'Cette consultation appartient a une autre commune.' });
185:    if (typeof req.body?.targetPopulation === 'string') update.targetPopulation = sanitizeString(req.body.targetPopulation, 300);
216:      await notifyCommunePollPublished({
```

### ./app/backend/src/routes/support.js
```text
5:  communeScopeFromUser,
6:  isCommuneAdmin,
8:  requireCommuneAdmin,
69:    communeId: data.communeId || '',
70:    communeName: data.communeName || '',
116:const requireAdminCommuneScope = (req, res) => {
117:  const scope = communeScopeFromUser(req.user);
119:    res.status(403).json({ message: 'Aucune commune attachée au compte administrateur.' });
127:  if (!isCommuneAdmin(user)) return false;
128:  const scope = communeScopeFromUser(user);
129:  return Boolean(scope && ticket.communeId === scope);
162:router.use(ensureConfigured, requireFirebaseAuth, requireCommuneAdmin);
169:      const scope = requireAdminCommuneScope(req, res);
171:      query = query.where('communeId', '==', scope);
185:    const communeId = requireAdminCommuneScope(req, res);
186:    if (!communeId) return undefined;
192:    const communeName = sanitize(req.body?.communeName, 200) || communeId;
209:      communeId,
210:      communeName,
253:        communeName,
272:    const platform = sanitize(req.body?.platform, 40) || 'web';
282:      platform,
```

### ./app/backend/src/routes/voteAccess.js
```text
38:export const buildParticipationRecord = ({ pollId, participationHash, communeId }) => ({
41:  communeId,
45:export const buildAnonymousBallotRecord = ({ pollId, optionId, communeId }) => ({
48:  communeId,
80:export const signPollAccessToken = ({ pollId, communeId, participationHash }) => signAccessToken({
82:  communeId,
110:export const optionBelongsToPoll = (poll, optionId) => Array.isArray(poll.options)
119:    communeId: data.communeId || '',
120:    communeName: data.communeName || '',
142:    : await db.collection(POLL_COLLECTION).where('communeId', '==', access.communeId).limit(50).get();
155:      const sameCommune = !access.communeId || !poll.communeId || poll.communeId === access.communeId;
156:      if (!sameCommune || !isPollOpen(poll)) return null;
219:      return res.status(409).json({ ok: false, errorCode: 'POLL_CLOSED', message: 'Cette consultation n’est pas ouverte pour ce code.', communeId: access.communeId, communeName: access.communeName });
222:      return res.status(409).json({ ok: false, errorCode: 'NO_OPEN_POLL', message: 'Aucune consultation ouverte pour votre commune actuellement.', communeId: access.communeId, communeName: access.communeName });
231:          communeId: access.communeId,
241:      communeId: access.communeId,
242:      communeName: access.communeName,
269:    if (token.communeId && poll.communeId && token.communeId !== poll.communeId) {
270:      return { status: 403, errorCode: 'INVALID_CODE', message: 'Ce code n’est pas rattache a cette commune.' };
272:    if (!optionBelongsToPoll(poll, optionId)) {
288:      communeId: token.communeId || poll.communeId || '',
293:      communeId: token.communeId || poll.communeId || '',
```

### ./app/backend/src/scripts/loadSmokeTest.js
```text
111:  throw new Error(`P95 latency too high: ${p95.toFixed(2)}ms > ${P95_MAX_MS}ms`);
```

### ./app/backend/src/scripts/migrateRegistrationCodesToCitizenAccessCodes.js
```text
31:  communeId: data.communeId || '',
32:  communeName: data.communeName || '',
```

### ./app/backend/src/services/notificationService.js
```text
45:  const communeId = sanitizeString(poll?.communeId, 128);
51:      body: `${title} est ouverte dans votre commune.`,
56:      communeId,
74:  platform = 'web',
90:    communeId: sanitizeString(access.communeId, 128),
91:    communeName: sanitizeString(access.communeName, 200),
92:    platform: sanitizeString(platform, 40) || 'web',
104:  const communeId = sanitizeString(poll?.communeId, 128);
105:  const communeName = sanitizeString(poll?.communeName, 200);
106:  if (!communeId && !communeName) return [];
109:  const snapshot = communeId
110:    ? await collection.where('communeId', '==', communeId).limit(500).get()
111:    : await collection.where('communeName', '==', communeName).limit(500).get();
144:  platform = 'web',
160:    platform: sanitizeString(platform, 40) || 'web',
173:  const communeName = sanitizeString(ticket?.communeName, 200) || 'une commune';
181:      body: `${communeName} : ${subject}`,
246:export const notifyCommunePollPublished = async ({ db, poll }) => {
275:      communeId: poll.communeId,
```

### ./app/backend/test/citizenAccessSecurity.test.js
```text
66:test('commune admin generated controller code hashes to the login lookup value', () => {
146:      this.remoteAddress = '127.0.0.1';
```

### ./app/backend/test/migrateRegistrationCodesToCitizenAccessCodes.test.js
```text
16:    communeId: 'commune-1',
17:    communeName: 'Fort-de-France',
38:      data: () => ({ code: 'AB12CD34', status: 'validated', communeId: 'commune-1', communeName: 'Fort-de-France' }),
```

### ./app/backend/test/notificationService.test.js
```text
54:    communeId: 'commune-1',
```

### ./app/backend/test/retireLegacyPollVotes.test.js
```text
38:        communeId: 'commune-1',
```

### ./app/backend/test/support.test.js
```text
16:const adminA = { uid: 'admin:a', role: 'commune_admin', admin: true, communeId: '97101' };
17:const adminB = { uid: 'admin:b', role: 'commune_admin', admin: true, communeId: '97102' };
25:      communeId: '97101',
46:test('canAccessTicket lets the super admin reach every commune ticket', () => {
47:  assert.equal(support.canAccessTicket(superAdmin, { communeId: '97101' }), true);
48:  assert.equal(support.canAccessTicket(superAdmin, { communeId: '97102' }), true);
51:test('canAccessTicket restricts a commune admin to their own commune', () => {
52:  assert.equal(support.canAccessTicket(adminA, { communeId: '97101' }), true);
53:  assert.equal(support.canAccessTicket(adminA, { communeId: '97102' }), false);
54:  assert.equal(support.canAccessTicket(adminB, { communeId: '97102' }), true);
58:  assert.equal(support.canAccessTicket(controller, { communeId: '97101' }), false);
80:    communeName: 'Les Abymes',
97:    communeName: 'Le Gosier',
```

### ./app/backend/test/voteAccess.test.js
```text
16:const clone = (value) => JSON.parse(JSON.stringify(value));
22:    this._data = data === undefined ? undefined : clone(data);
26:    return clone(this._data || {});
49:    this.writes.push({ ref, data: clone(data), merge: options.merge === true });
55:    this.store = clone(seed);
97:      communeId: 'commune-1',
112:  communeId: 'commune-1',
151:    communeId: 'commune-1',
156:  assert.deepEqual(Object.keys(payload).sort(), ['communeId', 'exp', 'participationHash', 'pollId']);
158:  assert.equal(payload.communeId, 'commune-1');
169:    communeId: 'commune-1',
176:test('optionBelongsToPoll validates option ownership', () => {
178:  assert.equal(voteAccess.optionBelongsToPoll(poll, 'opt-2'), true);
179:  assert.equal(voteAccess.optionBelongsToPoll(poll, 'opt-3'), false);
186:    communeId: 'commune-1',
191:    communeId: 'commune-1',
202:  assert.deepEqual(Object.keys(ballot).sort(), ['castAt', 'communeId', 'optionId', 'pollId']);
240:  assert.deepEqual(Object.keys(ballotDocs[0]).sort(), ['castAt', 'communeId', 'optionId', 'pollId']);
```

### ./audits/audit_geo_api_gouv_20260612_214514.md
```text
1:# Audit Geo API Gouv - iliprestō
20:8:  "commune": {
21:10:    "name": "Commune QA Citoyen Peyi"
26:1:(()=>{var _={blink:!0,gecko:!1,webkit:!1,unknown:!1},K=()=>navigator.vendor==="Google Inc."||navigator.userAgent.includes("Edg/")?"blink":navigator.vendor==="Apple Computer, Inc."?"webkit":navigator.vendor===""&&navigator.userAgent.includes("Firefox")?"gecko":"unknown",C=K(),R=()=>typeof ImageDecoder>"u"?!1:C==="blink",B=()=>typeof Intl.v8BreakIterator<"u"&&typeof Intl.Segmenter<"u",z=()=>{let i=[0,97,115,109,1,0,0,0,1,5,1,95,1,120,0];return WebAssembly.validate(new Uint8Array(i))},M=()=>{let i=document.createElement("canvas");return i.width=1,i.height=1,i.getContext("webgl2")!=null?2:i.getContext("webgl")!=null?1:-1},D=()=>window.chrome&&chrome.runtime&&chrome.runtime.id,w={browserEngine:C,hasImageCodecs:R(),hasChromiumBreakIterators:B(),supportsWasmGC:z(),crossOriginIsolated:window.crossOriginIsolated,webGLVersion:M(),isChromeExtension:D()};function c(...i){return new URL(I(...i),document.baseURI).toString()}function I(...i){return i.filter(e=>!!e).map((e,n)=>n===0?S(e):F(S(e))).filter(e=>e.length).join("/")}function F(i){let e=0;for(;e<i.length&&i.charAt(e)==="/";)e++;return i.substring(e)}function S(i){let e=i.length;for(;e>0&&i.charAt(e-1)==="/";)e--;return i.substring(0,e)}function E(i,e){return i.canvasKitBaseUrl?i.canvasKitBaseUrl:e.engineRevision&&!e.useLocalCanvasKit?I("https://www.gstatic.com/flutter-canvaskit",e.engineRevision):"canvaskit"}var v=class{constructor(){this._scriptLoaded=!1}setTrustedTypesPolicy(e){this._ttPolicy=e}async loadEntrypoint(e){let{entrypointUrl:n=c("main.dart.js"),onEntrypointLoaded:t,nonce:r}=e||{};return this._loadJSEntrypoint(n,t,r)}async load(e,n,t,r,a){a??=l=>{l.initializeEngine(t).then(u=>u.runApp())};let{entrypointBaseUrl:s}=t,{entryPointBaseUrl:o}=t;if(!s&&o&&(console.warn("[deprecated] `entryPointBaseUrl` is deprecated and will be removed in a future release. Use `entrypointBaseUrl` instead."),s=o),e.compileTarget==="dart2wasm")return this._loadWasmEntrypoint(e,n,s,a);{let l=e.mainJsPath??"main.dart.js",u=c(s,l);return this._loadJSEntrypoint(u,a,r)}}didCreateEngineInitializer(e){typeof this._didCreateEngineInitializerResolve=="function"&&(this._didCreateEngineInitializerResolve(e),this._didCreateEngineInitializerResolve=null,delete _flutter.loader.didCreateEngineInitializer),typeof this._onEntrypointLoaded=="function"&&this._onEntrypointLoaded(e)}_loadJSEntrypoint(e,n,t){let r=typeof n=="function";if(!this._scriptLoaded){this._scriptLoaded=!0;let a=this._createScriptTag(e,t);if(r)console.debug("Injecting <script> tag. Using callback."),this._onEntrypointLoaded=n,document.head.append(a);else return new Promise((s,o)=>{console.debug("Injecting <script> tag. Using Promises. Use the callback approach instead!"),this._didCreateEngineInitializerResolve=s,a.addEventListener("error",o),document.head.append(a)})}}async _loadWasmEntrypoint(e,n,t,r){if(!this._scriptLoaded){this._scriptLoaded=!0,this._onEntrypointLoaded=r;let{mainWasmPath:a,jsSupportRuntimePath:s}=e,o=c(t,a),l=c(t,s);this._ttPolicy!=null&&(l=this._ttPolicy.createScriptURL(l));let d=(await import(l)).compileStreaming(fetch(o)),p;e.renderer==="skwasm"?p=(async()=>{let h=await n.skwasm;return window._flutter_skwasmInstance=h,{skwasm:h.wasmExports,skwasmWrapper:h,ffi:{memory:h.wasmMemory}}})():p=Promise.resolve({}),await(await(await d).instantiate(await p,{loadDynamicModule:async(h,j)=>{let A=fetch(c(t,h)),L=c(t,j);this._ttPolicy!=null&&(L=this._ttPolicy.createScriptURL(L));let x=import(L);return[await A,await x]}})).invokeMain()}}_createScriptTag(e,n){let t=document.createElement("script");t.type="application/javascript",n&&(t.nonce=n);let r=e;return this._ttPolicy!=null&&(r=this._ttPolicy.createScriptURL(e)),t.src=r,t}};async function T(i,e,n){if(e<0)return i;let t,r=new Promise((a,s)=>{t=setTimeout(()=>{s(new Error(`${n} took more than ${e}ms to resolve. Moving on.`,{cause:T}))},e)});return Promise.race([i,r]).finally(()=>{clearTimeout(t)})}var g=class{setTrustedTypesPolicy(e){this._ttPolicy=e}loadServiceWorker(e){if(!e||!("serviceWorker"in navigator))return Promise.resolve();let n=()=>{console.warn(`Loading the service worker using Flutter bootstrap is deprecated and will stop working in a future release.
27:2:For more details, see: https://github.com/flutter/flutter/issues/156910`)},t=()=>{let{serviceWorkerVersion:r,serviceWorkerUrl:a=c(`flutter_service_worker.js?v=${r}`),timeoutMillis:s=4e3}=e,o=a;this._ttPolicy!=null&&(o=this._ttPolicy.createScriptURL(o));let l=navigator.serviceWorker.register(o).then(u=>this._getNewServiceWorker(u,r)).then(this._waitForServiceWorkerActivation);return T(l,s,"prepareServiceWorker")};return e.serviceWorkerUrl!=null?(n(),t()):navigator.serviceWorker.getRegistration().then(r=>r?t():Promise.resolve())}async _getNewServiceWorker(e,n){if(!e.active&&(e.installing||e.waiting))return console.debug("Installing/Activating first service worker."),e.installing||e.waiting;if(e.active.scriptURL.endsWith(n))return console.debug("Loading from existing service worker."),e.active;{let t=await e.update();return console.debug("Updating service worker."),t.installing||t.waiting||t.active}}async _waitForServiceWorkerActivation(e){if(!e||e.state==="activated")if(e){console.debug("Service worker already active.");return}else throw new Error("Cannot activate a null service worker!");return new Promise((n,t)=>{e.addEventListener("statechange",()=>{e.state==="activated"&&(console.debug("Activated new service worker."),n())})})}};var y=class{constructor(e,n="flutter-js"){let t=e||[/\.js$/,/\.mjs$/];window.trustedTypes&&(this.policy=trustedTypes.createPolicy(n,{createScriptURL:function(r){if(r.startsWith("blob:"))return r;let a=new URL(r,window.location),s=a.pathname.split("/").pop();if(t.some(l=>l.test(s)))return a.toString();console.error("URL rejected by TrustedTypes policy",n,":",r,"(download prevented)")}}))}};var k=i=>{let e=WebAssembly.compileStreaming(fetch(i));return(n,t)=>((async()=>{let r=await e,a=await WebAssembly.instantiate(r,n);t(a,r)})(),{})};var U=(i,e,n,t)=>(window.flutterCanvasKitLoaded=(async()=>{if(window.flutterCanvasKit)return window.flutterCanvasKit;let r=n.hasChromiumBreakIterators&&n.hasImageCodecs;if(!r&&e.canvasKitVariant=="chromium")throw"Chromium CanvasKit variant specifically requested, but unsupported in this browser";let a=r&&e.canvasKitVariant!=="full",s=t;e.canvasKitVariant=="experimentalWebParagraph"?s=c(s,"experimental_webparagraph"):a&&(s=c(s,"chromium"));let o=c(s,"canvaskit.js");i.flutterTT.policy&&(o=i.flutterTT.policy.createScriptURL(o));let l=k(c(s,"canvaskit.wasm")),u=await import(o);return window.flutterCanvasKit=await u.default({instantiateWasm:l}),window.flutterCanvasKit})(),window.flutterCanvasKitLoaded);var W=async(i,e,n,t)=>{let a=!n.hasImageCodecs||!n.hasChromiumBreakIterators?"skwasm_heavy":e.enableWimp?"wimp":"skwasm",s=c(t,`${a}.js`),o=s;i.flutterTT.policy&&(o=i.flutterTT.policy.createScriptURL(o));let l=k(c(t,`${a}.wasm`));return await(await import(o)).default({skwasmSingleThreaded:e.enableWimp||!n.crossOriginIsolated||n.isChromeExtension||e.forceSingleThreadedSkwasm,instantiateWasm:l,locateFile:(d,p)=>d.endsWith(".ww.js")?URL.createObjectURL(new Blob([`
32:5:  "display": "standalone",
33:10:  "prefer_related_applications": false,
38:11:    runs-on: ubuntu-latest
39:81:    runs-on: ubuntu-latest
40:96:    name: Firestore rules (emulator)
41:97:    runs-on: ubuntu-latest
42:112:      - name: Run rules unit tests against emulator
43:114:        run: firebase emulators:exec --only firestore --project demo-citoyen-peyi "npm test"
48:2:# NB: le secret GCP_RUNTIME_SERVICE_ACCOUNT doit pointer vers un SA existant que
49:3:# GCP_DEPLOY_SERVICE_ACCOUNT peut "actAs" (roles/iam.serviceAccountUser), sinon
50:8:# Les secrets sont montes en ":latest" : une rotation (nouvelle version) n'est prise
51:28:    runs-on: ubuntu-latest
52:41:    runs-on: ubuntu-latest
53:44:      GCP_PROJECT_ID: ${{ vars.GCP_PROJECT_ID }}
54:45:      GCP_REGION: ${{ vars.GCP_REGION }}
55:49:      GCP_WORKLOAD_IDENTITY_PROVIDER: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
56:50:      GCP_DEPLOY_SERVICE_ACCOUNT: ${{ secrets.GCP_DEPLOY_SERVICE_ACCOUNT }}
57:51:      GCP_RUNTIME_SERVICE_ACCOUNT: ${{ secrets.GCP_RUNTIME_SERVICE_ACCOUNT }}
58:58:          for name in GCP_PROJECT_ID GCP_REGION CORS_ORIGIN GCP_WORKLOAD_IDENTITY_PROVIDER GCP_DEPLOY_SERVICE_ACCOUNT GCP_RUNTIME_SERVICE_ACCOUNT; do
59:72:          workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
60:73:          service_account: ${{ secrets.GCP_DEPLOY_SERVICE_ACCOUNT }}
61:78:          project_id: ${{ vars.GCP_PROJECT_ID }}
62:82:          # Defense contre un secret GCP_RUNTIME_SERVICE_ACCOUNT contenant un
63:86:          clean="$(printf '%s' "$GCP_RUNTIME_SERVICE_ACCOUNT" | tr -d '[:space:]')"
64:88:            echo "::error::GCP_RUNTIME_SERVICE_ACCOUNT est vide apres nettoyage." >&2
65:91:          echo "GCP_RUNTIME_SERVICE_ACCOUNT=$clean" >> "$GITHUB_ENV"
66:113:          fix_cmd="gcloud iam service-accounts add-iam-policy-binding $GCP_RUNTIME_SERVICE_ACCOUNT --member=\"serviceAccount:$GCP_DEPLOY_SERVICE_ACCOUNT\" --role=\"roles/iam.serviceAccountUser\" --project=$GCP_PROJECT_ID"
67:114:          if ! policy="$(gcloud iam service-accounts get-iam-policy "$GCP_RUNTIME_SERVICE_ACCOUNT" --format=json 2>/dev/null)"; then
68:119:             echo "$policy" | grep -q "serviceAccount:$GCP_DEPLOY_SERVICE_ACCOUNT"; then
69:135:        run: gcloud auth configure-docker "$GCP_REGION-docker.pkg.dev" --quiet
70:140:            --location="$GCP_REGION" >/dev/null 2>&1 || \
71:143:            --location="$GCP_REGION" \
72:149:          IMAGE="$GCP_REGION-docker.pkg.dev/$GCP_PROJECT_ID/citoyen-peyi/backend:${{ github.sha }}"
73:160:          ENV_VARS="^@^NODE_ENV=production@CORS_ORIGIN=$CORS_ORIGIN@LOG_LEVEL=info@GOOGLE_CLOUD_PROJECT=$GCP_PROJECT_ID"
74:168:          SECRET_BINDINGS="SUPER_ADMIN_KEY=SUPER_ADMIN_KEY:latest,VOTE_ACCESS_TOKEN_SECRET=VOTE_ACCESS_TOKEN_SECRET:latest,ACCESS_CODE_PEPPER=ACCESS_CODE_PEPPER:latest,CITIZEN_FINGERPRINT_PEPPER=CITIZEN_FINGERPRINT_PEPPER:latest,PARTICIPATION_PEPPER=PARTICIPATION_PEPPER:latest"
75:171:              SECRET_BINDINGS="$SECRET_BINDINGS,$optional_secret=$optional_secret:latest"
76:178:            --region="$GCP_REGION" \
77:179:            --platform=managed \
78:181:            --service-account="$GCP_RUNTIME_SERVICE_ACCOUNT" \
79:187:            --cpu=1 \
80:194:              echo "  gcloud iam service-accounts add-iam-policy-binding $GCP_RUNTIME_SERVICE_ACCOUNT --member=\"serviceAccount:$GCP_DEPLOY_SERVICE_ACCOUNT\" --role=\"roles/iam.serviceAccountUser\" --project=$GCP_PROJECT_ID" >&2
81:201:          SERVICE_URL="$(gcloud run services describe citoyen-peyi-backend --region="$GCP_REGION" --format='value(status.url)')"
86:22:    runs-on: ubuntu-latest
87:37:          workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
88:38:          service_account: ${{ secrets.GCP_DEPLOY_SERVICE_ACCOUNT }}
93:16:    runs-on: ubuntu-latest
94:35:          workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
95:36:          service_account: ${{ secrets.GCP_DEPLOY_SERVICE_ACCOUNT }}
100:20:    runs-on: ubuntu-latest
101:69:          cp build/web/index.html build/web/404.html
102:81:    runs-on: ubuntu-latest
107:117:        "export PATH=\"$HOME/flutter/bin:$PATH\"; cd flutter_app && flutter create . --platforms=web"
108:125:      "detail": "Genere les fichiers plateforme Flutter Web autour du squelette existant."
109:346:        "cd /workspaces/citoyen-peyi/tests/firestore-rules && npm install --no-package-lock && npx --yes firebase-tools@13 emulators:exec --only firestore --project demo-citoyen-peyi \"npm test\"; status=$?; rm -rf node_modules; exit $status"
110:354:      "detail": "Lance les tests unitaires des regles Firestore via emulateur."
115:6:- **Projet GCP** : `citoyen-peyi`
116:7:- **Région** : `europe-west1`
117:50:| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Fournisseur WIF pour l'auth CI |
118:51:| `GCP_DEPLOY_SERVICE_ACCOUNT` | `github-deploy@…` (sans espace/retour parasite !) |
119:52:| `GCP_RUNTIME_SERVICE_ACCOUNT` | `1087566305566-compute@…` (sans espace/retour parasite !) |
120:57:| `GCP_PROJECT_ID` | `citoyen-peyi` |
121:58:| `GCP_REGION` | `europe-west1` |
122:87:Les secrets sont montés en `:latest` → **une rotation n'est prise en compte qu'au
123:100:gcloud secrets versions access latest --secret=SUPER_ADMIN_KEY --project=citoyen-peyi
124:102:# 3. Redéployer pour activer :latest (Run workflow ou push backend)
125:143:# Option A — Memorystore (Redis géré GCP, même région)
126:145:  --size=1 --region=europe-west1 --redis-version=redis_7_0 \
127:161:Le `HEALTHCHECK` du Dockerfile est **ignoré** par Cloud Run (qui fait un probe TCP par
128:165:gcloud run deploy citoyen-peyi-backend --region=europe-west1 --project=citoyen-peyi \
133:8:- script pour generer un ZIP complet du projet
134:13:- `app/scripts/`: utilitaires (zip)
135:16:- `tests/firestore-rules/`: tests unitaires des regles Firestore (emulateur)
136:25:## Installation
137:33:	cp .env.example .env
138:53:- `SUPER_ADMIN_KEY`: cle longue et aleatoire exigee dans le header `x-super-admin-key` pour les routes super administrateur.
```

### ./docs/ANONYMITY_THREAT_MODEL.md
```text
14:- Identite operationnelle du controleur et de la commune.
```

### ./docs/AUDIT_CORRECTIONS_REPORT.md
```text
15:- Demandes de doublon rattachees a des identifiants techniques, sans code existant en clair dans les reponses standard.
25:- Modeles de doublon Flutter nettoyes: affichage par identifiant de dossier, commune, controleur, statut et motif uniquement.
26:- Ecrans de doublon super administrateur sans affichage de code existant ni fragments personnels.
33:- Lecture des journaux controleur limitee par role, commune et controleur rattache.
55:- Le code citoyen clair reste volontairement visible uniquement au controleur au moment de creation pour remise physique au citoyen.
```

### ./docs/CITOYEN_PEYI_FLOW_QA.md
```text
17:  - `citizen_fingerprints` (detection doublon)
30:- [ ] Le tableau de bord liste les communes / controleurs / activites.
31:- [ ] Creer un profil administrateur communal (commune + nom + code) :
33:- [ ] Voir l'activite globale puis filtrer sur une commune ou un controleur.
58:  - Pas de doublon -> code + QR retournes par le backend.
59:  - Doublon detecte -> demande automatique transmise au super admin.
75:- [ ] Consulter `/results` : les totaux par option et par commune sont visibles,
89:      verification token + commune + sondage ouvert + option valide + non
```

### ./docs/PRD_PAGE_ACCUEIL.md
```text
5:Citoyen Peyi est une plateforme de participation citoyenne. La page d'accueil
47:  - Commune
78:   - Commune -> /admin-communal
111:- Acces administration ouvre une modale puis redirige selon le choix.
154:- home_click_admin_choice_commune
185:- Test manuel accessibilite clavier (tabulation) et lecteur d'ecran.
191:- Risque: perte de lisibilite selon l'image de fond.
```

### ./docs/PROD_CHECKLIST.md
```text
9:- [ ] Variables GitHub Actions definies: `GCP_PROJECT_ID`, `GCP_REGION`, `API_BASE_URL`, `CORS_ORIGIN`, `FIREBASE_PROJECT_ID`.
10:- [ ] Secrets GitHub Actions definis: `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_DEPLOY_SERVICE_ACCOUNT`, `GCP_RUNTIME_SERVICE_ACCOUNT`, `FIREBASE_*` (x6).
13:- [ ] CI vert sur la branche cible (backend tests, Flutter analyze + test, Firestore rules emulator).
18:- [ ] Cloud Run service `citoyen-peyi-api` cree en `eu-west1` (ou region la plus proche).
28:- [ ] Premiers profils `communeAdmins` et `controleurCodes` crees via les nouveaux endpoints backend.
64:      le jeton court transporte uniquement `pollId`, `communeId`,
69:      `pollId`, `optionId`, `communeId` et `castAt`.
85:et tests de non-correlation.
```

### ./docs/RUNBOOK_PROD.md
```text
8:       (HTTPS)                   (HTTPS, region eu)        + Admin SDK
26:| Cloud Run secret | `SUPER_ADMIN_KEY` | Secret Manager | `SUPER_ADMIN_KEY:latest` |
27:| Cloud Run secret | `ADMIN_ACCESS_KEY` | Secret Manager | `ADMIN_ACCESS_KEY:latest` |
29:| Cloud Run identity | service account avec Firestore User | IAM | `GCP_RUNTIME_SERVICE_ACCOUNT` |
30:| GitHub Actions | `GCP_PROJECT_ID`, `GCP_REGION`, `FIREBASE_PROJECT_ID`, `CORS_ORIGIN`, `API_BASE_URL` | repo `vars` |  |
31:| GitHub Actions | `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_DEPLOY_SERVICE_ACCOUNT`, `GCP_RUNTIME_SERVICE_ACCOUNT` | repo `secrets` |  |
40:3. `gcloud run services update citoyen-peyi-api --region=eu-west1 --update-secrets=SUPER_ADMIN_KEY=SUPER_ADMIN_KEY:latest`
80:  --project=$GCP_PROJECT_ID
121:2. Verifier les regles Firestore via `firebase emulators:exec` en local.
```

### ./docs/SECURITY_HARDENING.md
```text
12:- Les demandes de doublon exposent des identifiants de dossier, pas les fragments d'identite.
21:- `SUPER_ADMIN_KEY`: secret long et aleatoire.
23:- `ACCESS_CODE_PEPPER`: secret long, aleatoire, distinct des autres secrets.
24:- `CITIZEN_FINGERPRINT_PEPPER`: secret long, aleatoire, distinct des autres secrets.
25:- `PARTICIPATION_PEPPER`: secret long, aleatoire, distinct des autres secrets, utilise pour empecher le lien durable entre code citoyen et bulletin.
26:- `VOTE_ACCESS_TOKEN_SECRET`: secret long et aleatoire pour les jetons courts de vote.
27:- Identifiants Firebase Admin: `GOOGLE_APPLICATION_CREDENTIALS` ou variables projet/client/private key selon l'environnement.
38:3. Le backend calcule l'empreinte citoyenne HMAC et detecte un doublon.
39:4. Si aucun doublon n'existe, le backend cree un code aleatoire, stocke uniquement son HMAC et retourne le code une seule fois a l'ecran controleur.
40:5. Si un doublon existe, le backend cree une demande de validation sans exposer de code existant en clair.
41:6. Le vote public valide le code via le backend et recoit un jeton court dedie a une consultation precise, contenant uniquement `pollId`, `communeId`, `participationHash` et `exp`.
43:8. Le bulletin anonyme ne conserve que `pollId`, `optionId`, `communeId` et `castAt`.
88:tests de non-correlation avant implementation production.
98:Les journaux `controller_activity_logs` sont lisibles uniquement selon le role et le rattachement commune/controleur.
```

### ./firebase.json
```text
78:  "emulators": {
```

### ./firestore.indexes.json
```text
8:          "fieldPath": "communeId",
22:          "fieldPath": "communeId",
54:          "fieldPath": "communeId",
68:          "fieldPath": "communeId",
82:          "fieldPath": "communeId",
100:          "fieldPath": "communeId",
132:          "fieldPath": "communeId",
160:          "fieldPath": "communeId",
224:          "fieldPath": "communeId",
```

### ./firestore.rules
```text
27:    function isAdminCommune() {
28:      return hasRole('adminCommune') || hasRole('commune_admin') || isAdmin();
72:    function userCommuneId() {
73:      return request.auth.token.communeId != null
74:        ? request.auth.token.communeId
75:        : request.auth.token.communeCode;
104:      return hasOnlyKeys(['commune', 'updatedAt']);
112:      return hasOnlyKeys(['id', 'code', 'pollId', 'createdAt', 'usedBy', 'status', 'documentType', 'validatedAt', 'expiresAt', 'communeName', 'qrPayload', 'activatedAt', 'votedAt', 'verifiedByControleurCode', 'verifiedByControleurLabel', 'updatedAt']);
116:      return hasOnlyKeys(['id', 'code', 'label', 'commune', 'createdAt', 'usedAt', 'updatedAt']);
125:        'id', 'accessCodeHash', 'displayCodeMasked', 'citizenFingerprintHash', 'communeId',
126:        'communeName', 'createdByControllerId', 'createdByControllerName', 'createdAt',
138:        'citizenFingerprintHash', 'firstAccessCodeId', 'latestAccessCodeId', 'communeId',
148:        'requestedByControllerName', 'communeId', 'communeName', 'requestedAt', 'status',
159:        'id', 'communeId', 'communeName', 'controllerId', 'controllerName', 'actionType',
167:        'ticketId', 'communeId', 'communeName', 'createdByUserId', 'createdByName',
174:      request.resource.data.communeId is string &&
175:      request.resource.data.communeName is string &&
206:      return isAdminCommune() && resource.data.communeId == userCommuneId();
210:      return isAdminCommune() &&
213:        request.resource.data.communeId == userCommuneId() &&
227:        request.resource.data.communeId == resource.data.communeId &&
228:        request.resource.data.communeName == resource.data.communeName &&
262:        (isAdminCommune() && get(/databases/$(database)/documents/support_tickets/$(ticketId)).data.communeId == userCommuneId());
266:      return isAdminCommune() &&
269:        getAfter(/databases/$(database)/documents/support_tickets/$(ticketId)).data.communeId == userCommuneId();
285:    // communeAdmins is fully backend-managed. Clients never read the
288:    match /communeAdmins/{adminId} {
293:    // the backend can scope updates to the right commune and audit
340:        || (isAdminCommune() && resource.data.communeId == request.auth.token.communeId)
367:      allow read: if isAdminCommune() || isSuperAdmin();
371:    // Abonnements push FCM: associes par le backend a une commune apres
```

### ./flutter_app/firebase.json
```text
1:{"flutter":{"platforms":{"dart":{"lib/firebase_options.dart":{"projectId":"citoyen-peyi","configurations":{"web":"1:1087566305566:web:a199ae799558f6a324d10f"}}}}}}
```

### ./flutter_app/lib/app.dart
```text
13:      debugShowCheckedModeBanner: false,
```

### ./flutter_app/lib/firebase_options.dart
```text
5:    show defaultTargetPlatform, kIsWeb, TargetPlatform;
14:///   options: DefaultFirebaseOptions.currentPlatform,
18:  static FirebaseOptions get currentPlatform {
22:    switch (defaultTargetPlatform) {
23:      case TargetPlatform.android:
28:      case TargetPlatform.iOS:
33:      case TargetPlatform.macOS:
38:      case TargetPlatform.windows:
43:      case TargetPlatform.linux:
50:          'DefaultFirebaseOptions are not supported for this platform.',
56:    apiKey: 'AIzaSyCPbwCjZivExVMV6iJQvQLcnjAfr1m3CMA',
```

### ./flutter_app/lib/models/poll_models.dart
```text
69:    this.targetPopulation = '',
70:    this.communeId = '',
71:    this.communeName = '',
88:  final String targetPopulation;
89:  final String communeId;
90:  final String communeName;
107:    String? targetPopulation,
108:    String? communeId,
109:    String? communeName,
126:      targetPopulation: targetPopulation ?? this.targetPopulation,
127:      communeId: communeId ?? this.communeId,
128:      communeName: communeName ?? this.communeName,
148:        'targetPopulation': targetPopulation,
149:        'communeId': communeId,
150:        'communeName': communeName,
181:      targetPopulation: json['targetPopulation'] as String? ?? '',
182:      communeId: json['communeId'] as String? ?? '',
183:      communeName: json['communeName'] as String? ?? '',
209:    required this.communeName,
227:  final String? communeName;
243:    String? communeName,
260:      communeName: communeName ?? this.communeName,
282:        'communeName': communeName,
308:      communeName: json['communeName'] as String?,
```

### ./flutter_app/lib/models/support_ticket.dart
```text
30:    required this.communeId,
31:    required this.communeName,
53:  final String communeId;
54:  final String communeName;
90:      communeId: communeId,
91:      communeName: communeName,
115:        'communeId': communeId,
116:        'communeName': communeName,
154:      communeId: _readString(data['communeId']),
155:      communeName: _readString(data['communeName']),
```

### ./flutter_app/lib/pages/access_citizen_page.dart
```text
6:import '../services/citizen_commune_store.dart';
129:      await CitizenCommuneStore.instance.save(
130:        communeId: session.communeId,
131:        communeName: session.communeName,
136:      unawaited(PushNotificationService.instance.registerForCitizenCommune(
138:        communeId: session.communeId,
139:        communeName: session.communeName,
232:                    'Plateforme de consultation citoyenne anonyme.',
```

### ./flutter_app/lib/pages/admin_analytics_page.dart
```text
130:                                  _ChartLegendItem(color: const Color(0xFF0B6FA4), label: 'Brouillons', value: _summary.draftCount),
279:              title: 'Brouillons\n$draft',
558:                'Pouls de la commune',
585:                  label: 'Brouillons',
587:                  color: AnalyticsPalette.slateMuted),
627:              '${summary.completedCount} clôturées · ${summary.draftCount} brouillons',
754:            color: AnalyticsPalette.slateMuted,
```

### ./flutter_app/lib/pages/admin_create_poll_page.dart
```text
17:  final _targetPopulationController = TextEditingController();
33:    _targetPopulationController.dispose();
122:        targetPopulation: _targetPopulationController.text,
188:            controller: _targetPopulationController,
190:              labelText: 'Population cible',
191:              hintText: 'Ex : habitants majeurs de la commune',
243:                          hintText: 'Ex : Reamenagement du centre-ville',
```

### ./flutter_app/lib/pages/admin_dashboard_page.dart
```text
9:import '../services/commune_lookup_service.dart';
12:import '../widgets/commune_autocomplete_field.dart';
275:      AdminDashboardSection.overview => 'Tableau de bord commune',
301:                  Text('Tableau de bord commune'),
418:                        label: 'Brouillons',
438:                              : 'Role UX: commune_admin\nRole technique: ${session.role}\nCommune: ${session.commune?.name ?? 'mode global/fallback'}\nProfil: ${session.label ?? 'Administrateur communal'}\nMode: ${session.modeLabel}',
499:                    communeId: session?.commune?.code?.trim().isNotEmpty == true
500:                        ? session!.commune!.code!.trim()
501:                        : session?.commune?.name.trim() ?? '',
787:    required this.communeId,
794:  final String communeId;
803:      stream: SupportTicketService.instance.watchAdminTickets(communeId),
807:        final latestTickets = tickets.take(3).toList(growable: false);
878:                      tickets: latestTickets,
1396:                  '${profile.communeName}${profile.codePostal != null ? " (${profile.codePostal})" : ""}',
1493:  final _communeCtrl = TextEditingController();
1494:  final _postalCtrl = TextEditingController();
1501:    _communeCtrl.dispose();
1502:    _postalCtrl.dispose();
1507:  void _selectCommune(CommuneSuggestion commune) {
1509:      _communeCtrl.text = commune.nom;
1510:      _postalCtrl.text = commune.firstPostal;
1511:      _codeCtrl.text = commune.code;
1519:    final communeCode = CommuneLookupService.normalizeInsee(_codeCtrl.text);
1520:    final codePostal = CommuneLookupService.normalizePostal(_postalCtrl.text);
1524:        communeName: CommuneLookupService.normalizeCommuneName(_communeCtrl.text),
1525:        communeCode: communeCode.isEmpty ? null : communeCode,
1526:        codePostal: codePostal.isEmpty ? null : codePostal,
1570:              CommuneAutocompleteField(
1571:                controller: _communeCtrl,
1574:                onSelected: _selectCommune,
1583:                      controller: _postalCtrl,
1587:                        labelText: 'Code postal',
1599:                        labelText: 'Code INSEE',
```

### ./flutter_app/lib/pages/admin_edit_poll_page.dart
```text
20:  final _targetPopulationController = TextEditingController();
43:    _targetPopulationController.dispose();
67:    _targetPopulationController.text = poll.targetPopulation;
159:        targetPopulation: _targetPopulationController.text,
336:                            controller: _targetPopulationController,
337:                            decoration: const InputDecoration(labelText: 'Population cible'),
```

### ./flutter_app/lib/pages/admin_settings_page.dart
```text
37:    final commune = session?.commune;
43:        title: const Text('Parametres de la commune'),
54:                  commune?.name ?? 'Commune non renseignee',
84:                      _SettingRow(label: 'Nom', value: commune?.name ?? 'Non renseigne'),
85:                      _SettingRow(label: 'Code commune', value: commune?.code ?? 'Non renseigne'),
86:                      _SettingRow(label: 'Code postal', value: commune?.codePostal ?? 'Non renseigne'),
```

### ./flutter_app/lib/pages/citizen_dashboard_page.dart
```text
42:                        'Votre code citoyen vous permet d\'acceder aux consultations ouvertes de votre commune. Votre vote est enregistre anonymement.',
63:                          'Saisissez un code citoyen valide pour consulter les consultations ouvertes de votre commune.',
82:                        Text('Commune: ${session.communeName}', style: Theme.of(context).textTheme.titleLarge),
```

### ./flutter_app/lib/pages/commune_controller_activity_page.dart
```text
5:class CommuneControllerActivityPage extends StatefulWidget {
6:  const CommuneControllerActivityPage({required this.communeId, super.key});
8:  final String communeId;
11:  State<CommuneControllerActivityPage> createState() => _CommuneControllerActivityPageState();
14:class _CommuneControllerActivityPageState extends State<CommuneControllerActivityPage> {
37:      filters: ControllerActivityFilters(communeId: widget.communeId),
54:      appBar: AppBar(title: const Text('Agents de mobilisation citoyenne de la commune')),
66:                      const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Aucun agent de mobilisation citoyenne actif pour cette commune.')))
98:          'Identifiant: $controllerId\nCodes generes: $generated · Doublons: $duplicates · Demandes en attente: ${pending < 0 ? 0 : pending}\nDerniere activite: $last',
```

### ./flutter_app/lib/pages/controller_activity_dashboard_page.dart
```text
27:  List<CommuneAnalyticsModel> _communes = const [];
28:  String? _communeId;
44:    // ex: Navigator.pushNamed('/super/activity', arguments: {'controllerId': '...', 'communeId': '...'}).
48:      final initialCommune = args['communeId'];
56:      if (initialCommune is String &&
57:          initialCommune.isNotEmpty &&
58:          _communeId != initialCommune) {
59:        _communeId = initialCommune;
73:        communeId: _communeId,
80:    final communes = await CitizenAccessCodeService.instance
81:        .getCommuneAnalyticsForSuperAdmin();
85:      _communes = communes
143:                        initialValue: _communeId,
144:                        decoration: const InputDecoration(labelText: 'Commune'),
148:                          for (final commune in _communes)
150:                                value: commune.communeId,
151:                                child: Text(commune.communeName)),
154:                          setState(() => _communeId = value);
193:                              child: Text('Doublon detecte')),
250:                          'Doublons detectes', _analytics.duplicatesDetected),
292:                  Text('Communes',
295:                  for (final commune in _communes)
298:                        title: Text(commune.communeName),
300:                          'Agents actifs: ${commune.activeControllers} · Codes: ${commune.codesGenerated} · '
301:                          'Doublons: ${commune.duplicatesDetected} · Pending: ${commune.pendingRequests} · '
302:                          'Taux doublons: ${(commune.duplicateRate * 100).round()}% · '
303:                          'Dernier code: ${commune.lastCodeGeneratedAt ?? '-'}',
307:                              '/super/activity/commune/${commune.communeId}'),
308:                          child: const Text('Voir commune'),
328:                              '${log.communeName} · ${log.createdAt}\nDossier: ${log.metadata['accessCodeId'] ?? log.metadata['duplicateRequestId'] ?? '-'}'),
```

### ./flutter_app/lib/pages/controller_citizen_access_page.dart
```text
35:  bool _addressChecked = false;
70:    // message sur la carte resultat au chargement (sinon faux "Doublon detecte"
121:        _addressChecked &&
151:        addressProofChecked: _addressChecked,
152:        communeEligibilityChecked: _residencyChecked,
246:                'Telechargement indisponible sur cette plateforme.')),
287:    final communeName = session?.commune?.name ?? 'Commune non rattachee';
327:                                'Commune de rattachement : $communeName\nL\'agent de mobilisation citoyenne verifie l\'eligibilite sans enregistrer l\'identite complete.',
344:                                      label: 'Doublons en attente',
366:                                      'Commune determinee automatiquement depuis le profil agent de mobilisation citoyenne'),
386:                                      'En cas de doublon, demande de regeneration transmise au super administrateur'),
402:                                'Votre code citoyen vous permet d\'acceder aux consultations ouvertes de votre commune.',
408:                                  labelText: 'Commune',
411:                                child: Text(communeName),
425:                                        'Toutes les consultations ouvertes de la commune'),
446:                                value: _addressChecked,
448:                                    () => _addressChecked = value ?? false),
564:                                      'Motif a utiliser si un doublon est detecte',
606:                                'Une demande de regeneration doit etre validee par le super administrateur en cas de doublon.',
755:    // comme un doublon. Titre/couleur selon l'etat reel.
759:            ? 'Doublon detecte'
809:                            'Le code citoyen permet d\'acceder aux consultations ouvertes de ${createdCode.communeName}.',
853:                      Text('Commune: ${duplicateRequest.communeName}'),
888:        subtitle: Text('${code.communeName} · ${code.createdAt}'),
```

### ./flutter_app/lib/pages/controller_dashboard_page.dart
```text
101:                              Text('Commune : ${session?.commune?.name ?? 'Non renseignee'}${session?.commune?.codePostal == null ? '' : ' · CP ${session!.commune!.codePostal}'}'),
118:                    _MetricCard(label: 'Doublons en attente', value: '$pendingDuplicates', icon: Icons.content_copy_rounded),
134:                        const _StepLine(index: 5, text: 'Doublon eventuel : demande de regeneration'),
169:                        subtitle: Text('${code.communeName} · ${code.createdAt}\nStatut : ${code.status}${code.usedForLogin ? ' · vote public utilise' : ''}'),
```

### ./flutter_app/lib/pages/controller_history_page.dart
```text
116:                        Text('Suivi des doublons detectes et des decisions super administrateur.'),
188:        subtitle: Text('${code.communeName} · ${code.createdAt}'),
```

### ./flutter_app/lib/pages/controller_login_page.dart
```text
50:      final commune = result.session.commune?.name;
51:      final message = commune == null || commune.isEmpty
53:          : 'Bienvenue, ${result.session.label ?? 'Agent de mobilisation citoyenne'} · $commune';
```

### ./flutter_app/lib/pages/duplicate_request_detail_page.dart
```text
84:      appBar: AppBar(title: const Text('Détail doublon')),
103:                                _Line('Commune', request.communeName),
```

### ./flutter_app/lib/pages/duplicate_request_list_page.dart
```text
38:      appBar: AppBar(title: const Text('Doublons à vérifier')),
66:                  const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Aucune demande de doublon.')))
97:        title: Text('${request.communeName} · dossier ${request.id}'),
```

### ./flutter_app/lib/pages/home_page.dart
```text
304:      title: 'Plateforme de consultation citoyenne anonyme',
658:                label: 'Commune',
```

### ./flutter_app/lib/pages/legal_page.dart
```text
380:    'Citoyen Peyi est une plateforme numérique de consultation citoyenne destinée à faciliter l’expression des habitants sur des sujets d’intérêt général proposés par une collectivité, une commune, un établissement public, une association ou tout organisme autorisé.',
381:    'La plateforme permet aux citoyens de participer à des consultations, sondages, questionnaires ou démarches de concertation locale dans un cadre sécurisé, confidentiel et respectueux de la vie privée.',
383:    'L’utilisation de la plateforme implique l’acceptation des présentes conditions générales d’utilisation, de la politique de confidentialité et des informations légales présentées sur cette page.',
391:      'Les présentes conditions générales d’utilisation ont pour objet de définir les règles d’accès, de participation et d’utilisation de la plateforme Citoyen Peyi.',
398:      'les règles relatives à la confidentialité des réponses ;',
401:      'les informations légales obligatoires relatives à la plateforme.',
439:      'protéger la consultation contre les abus, robots ou tentatives de manipulation.',
454:      'le fonctionnement de la plateforme ;',
485:      'Toutefois, lorsqu’un code citoyen, un identifiant technique ou un mécanisme de contrôle est utilisé pour vérifier l’éligibilité, éviter les doublons ou sécuriser la consultation, certaines informations techniques peuvent être traitées séparément des réponses.',
486:      'La plateforme doit donc distinguer :',
507:      'ne pas perturber le fonctionnement de la plateforme ;',
509:      'ne pas utiliser la plateforme à des fins commerciales, politiques illicites, frauduleuses ou malveillantes ;',
559:      'Citoyen Peyi est conçu selon un principe de minimisation des données.',
560:      'Selon la configuration choisie par la collectivité ou l’organisateur, les données susceptibles d’être traitées peuvent notamment comprendre :',
575:      'La plateforme n’a pas vocation à publier publiquement le nom, le prénom, l’adresse ou l’identité complète d’un participant avec ses réponses.',
588:      'éviter les doublons ;',
589:      'sécuriser la plateforme ;',
604:      'Selon le cadre de la consultation et l’identité de l’organisateur, les traitements de données peuvent reposer sur différentes bases légales, notamment :',
621:      '[Nom de la collectivité / commune / organisme responsable]',
622:      '[Adresse complète]',
636:      'les administrateurs autorisés de la plateforme ;',
649:      'La plateforme peut faire appel à des prestataires techniques pour assurer son hébergement, sa maintenance, sa sécurité, son stockage ou son fonctionnement.',
653:      'Adresse : [Adresse de l’hébergeur]',
667:      'les résultats agrégés peuvent être conservés plus longtemps lorsqu’ils ne permettent pas d’identifier les participants ;',
669:      'les codes citoyens peuvent être conservés uniquement le temps nécessaire à la vérification de l’accès et à la prévention des doublons ;',
683:      'L’éditeur met en œuvre des mesures techniques et organisationnelles destinées à protéger la plateforme et les données traitées.',
688:      'limitation des droits selon les rôles ;',
721:      '[Adresse postale]',
729:      'Citoyen Peyi peut utiliser des cookies ou traceurs strictement nécessaires au fonctionnement de la plateforme.',
740:      'Lorsque des cookies ou traceurs non strictement nécessaires sont utilisés, notamment à des fins de mesure d’audience, d’analyse ou d’amélioration du service, l’utilisateur doit être informé et son consentement peut être demandé selon la réglementation applicable.',
748:      'Toutefois, l’accès à la plateforme peut être interrompu ou limité notamment en cas :',
767:      'L’éditeur met en œuvre les moyens raisonnables pour assurer le bon fonctionnement, la sécurité et la fiabilité de la plateforme.',
771:      'd’une mauvaise utilisation de la plateforme par l’utilisateur ;',
800:      'L’utilisateur ne dispose d’aucun droit de propriété sur la plateforme du seul fait de son utilisation.',
817:      'de l’évolution de la plateforme ;',
832:      'Pour toute question relative à Citoyen Peyi, à une consultation, à l’exercice des droits ou à la protection des données, l’utilisateur peut contacter :',
834:      'Adresse : [à compléter]',
845:    title: 'Éditeur de la plateforme',
848:      'Adresse : [Adresse complète]',
866:      'Adresse : [à compléter]',
875:      'Adresse : [à compléter]',
```

### ./flutter_app/lib/pages/poll_detail_page.dart
```text
69:            .loadAccessCodesForCurrentCommune()
73:            '[PollDetail] loadAccessCodesForCurrentCommune failed: $error');
323:      return 'Brouillon';
415:              'Publiez, cloturez ou archivez la consultation selon son etat courant. La suppression n\'est autorisee que sans vote enregistre.',
641:                label: 'Commune',
642:                value: poll.communeName.isEmpty
644:                    : poll.communeName),
```

### ./flutter_app/lib/pages/public_news_page.dart
```text
7:/// Page actualités / projets de la commune.
9:/// Lit la collection Firestore `public_news` (champs: title, body, communeName,
89:                            'Les communes peuvent publier ici leurs actualités et projets soumis à consultation. Revenez bientôt.',
124:              if (item.communeName.isNotEmpty)
125:                Text(item.communeName.toUpperCase(),
152:    required this.communeName,
158:  final String communeName;
172:      communeName: (data['communeName'] as String? ?? '').trim(),
```

### ./flutter_app/lib/pages/public_results_page.dart
```text
9:/// Affiche les sondages ouverts, clotures ou archives rattaches a une commune.
11:/// option, le total et la commune sont restitues.
22:  String? _communeFilter;
43:      if (_communeFilter != null && _communeFilter!.isNotEmpty) {
44:        final matchById = poll.communeId == _communeFilter;
45:        final matchByName = poll.communeName.toLowerCase() == _communeFilter!.toLowerCase();
55:  Set<String> get _communes {
58:      if (poll.communeName.isNotEmpty) values.add(poll.communeName);
95:                  initialValue: _communeFilter,
96:                  decoration: const InputDecoration(labelText: 'Commune'),
99:                    for (final commune in _communes)
100:                      DropdownMenuItem(value: commune, child: Text(commune)),
102:                  onChanged: (value) => setState(() => _communeFilter = value),
179:              if (poll.communeName.isNotEmpty) ...[
181:                Text(poll.communeName, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF5A6573))),
```

### ./flutter_app/lib/pages/super_admin_communes_page.dart
```text
5:class SuperAdminCommunesPage extends StatefulWidget {
6:  const SuperAdminCommunesPage({super.key});
9:  State<SuperAdminCommunesPage> createState() => _SuperAdminCommunesPageState();
12:class _SuperAdminCommunesPageState extends State<SuperAdminCommunesPage> {
14:  List<CommuneAnalyticsModel> _communes = const [];
24:    final communes = await CitizenAccessCodeService.instance.getCommuneAnalyticsForSuperAdmin();
27:      _communes = communes;
37:      appBar: AppBar(title: const Text('Communes')),
46:                Text('Pilotage multi-communes', style: theme.textTheme.headlineSmall),
49:                  'Vue consolidee des communes actives, basee sur les logs des agents de mobilisation citoyenne et les demandes de doublons deja disponibles dans la plateforme.',
58:                else if (_communes.isEmpty)
71:                        label: 'Communes suivies',
72:                        value: _communes.length.toString(),
76:                        value: _communes.fold<int>(0, (sum, item) => sum + item.activeControllers).toString(),
80:                        value: _communes.fold<int>(0, (sum, item) => sum + item.codesGenerated).toString(),
84:                        value: _communes.fold<int>(0, (sum, item) => sum + item.pendingRequests).toString(),
89:                  for (final commune in _communes)
101:                                    child: Text(commune.communeName, style: theme.textTheme.titleLarge),
103:                                  Chip(label: Text(commune.communeId.isEmpty ? 'Commune non codee' : commune.communeId)),
111:                                  _MetricChip(label: 'Agents actifs', value: commune.activeControllers.toString()),
112:                                  _MetricChip(label: 'Codes generes', value: commune.codesGenerated.toString()),
113:                                  _MetricChip(label: 'Doublons detectes', value: commune.duplicatesDetected.toString()),
114:                                  _MetricChip(label: 'Demandes pending', value: commune.pendingRequests.toString()),
115:                                  _MetricChip(label: 'Taux doublons', value: '${(commune.duplicateRate * 100).round()}%'),
120:                                'Dernier code genere: ${commune.lastCodeGeneratedAt ?? 'Aucune activite recente'}',
130:                                      '/super/activity/commune/${commune.communeId}',
138:                                      arguments: {'communeId': commune.communeId},
```

### ./flutter_app/lib/pages/super_admin_dashboard_page.dart
```text
10:import '../services/commune_lookup_service.dart';
15:import '../widgets/commune_autocomplete_field.dart';
185:              'Copiez cette clé maintenant pour l\'administrateur de "${profile.communeName}". Elle ne sera plus visible en clair après fermeture.',
367:                    'Vue globale des doublons citoyens, regenerations et activites des agents de mobilisation citoyenne par commune.',
378:                            Navigator.of(context).pushNamed('/super/communes'),
379:                        child: const Text('Communes'),
394:                        child: const Text('Doublons'),
421:                        latestRequests: _duplicateRequests,
474:                  'Chaque profil est rattache a une commune et possede une cle de connexion unique.',
706:                        '${profile.communeName}${profile.codePostal != null ? " (${profile.codePostal})" : ""}',
801:  final _communeCtrl = TextEditingController();
803:  final _postalCtrl = TextEditingController();
815:    _communeCtrl.dispose();
817:    _postalCtrl.dispose();
821:  void _selectCommune(CommuneSuggestion commune) {
823:      _communeCtrl.text = commune.nom;
824:      _postalCtrl.text = commune.firstPostal;
825:      _codeCtrl.text = commune.code;
829:        _labelCtrl.text = 'Mairie de ${commune.nom}';
870:        communeName: CommuneLookupService.normalizeCommuneName(_communeCtrl.text),
871:        communeCode: CommuneLookupService.normalizeInsee(_codeCtrl.text),
872:        codePostal: CommuneLookupService.normalizePostal(_postalCtrl.text),
907:              // ---------- Commune avec autocomplétion ----------
908:              CommuneAutocompleteField(
909:                controller: _communeCtrl,
911:                onSelected: _selectCommune,
916:              // ---------- Code postal + INSEE (auto-remplis, modifiables) ----------
921:                      controller: _postalCtrl,
925:                        labelText: 'Code postal *',
940:                        labelText: 'Code INSEE *',
```

### ./flutter_app/lib/pages/super_admin_login_page.dart
```text
106:                        'Ce profil peut creer des comptes administrateurs rattaches a une commune et generer leurs cles de connexion.',
```

### ./flutter_app/lib/pages/super_communes_page.dart
```text
6:class SuperCommunesPage extends StatefulWidget {
7:  const SuperCommunesPage({super.key});
10:  State<SuperCommunesPage> createState() => _SuperCommunesPageState();
13:class _SuperCommunesPageState extends State<SuperCommunesPage> {
15:  List<CommuneAnalyticsModel> _communes = const [];
27:      CitizenAccessCodeService.instance.getCommuneAnalyticsForSuperAdmin(),
32:      _communes = results[0] as List<CommuneAnalyticsModel>;
43:      appBar: AppBar(title: const Text('Communes')),
52:                Text('Vue globale par commune', style: theme.textTheme.headlineSmall),
55:                  'Suivi des agents de mobilisation citoyenne, codes generes, doublons et admins communaux rattaches.',
64:                else if (_communes.isEmpty)
68:                      child: Text('Aucune activite de commune disponible pour le moment.'),
72:                  for (final commune in _communes)
75:                      child: _CommuneCard(
76:                        commune: commune,
77:                        adminCount: _adminCountFor(commune),
88:  int _adminCountFor(CommuneAnalyticsModel commune) {
90:      final byCode = admin.communeCode != null && admin.communeCode == commune.communeId;
91:      final byName = admin.communeName.toLowerCase() == commune.communeName.toLowerCase();
97:class _CommuneCard extends StatelessWidget {
98:  const _CommuneCard({required this.commune, required this.adminCount});
100:  final CommuneAnalyticsModel commune;
105:    final duplicateRate = (commune.duplicateRate * 100).toStringAsFixed(1);
117:                    commune.communeName,
121:                if (commune.communeId.isNotEmpty)
122:                  Chip(label: Text(commune.communeId)),
131:                _MetricChip(label: 'Agents actifs', value: '${commune.activeControllers}'),
132:                _MetricChip(label: 'Codes generes', value: '${commune.codesGenerated}'),
133:                _MetricChip(label: 'Doublons', value: '${commune.duplicatesDetected}'),
134:                _MetricChip(label: 'Demandes pending', value: '${commune.pendingRequests}'),
135:                _MetricChip(label: 'Taux doublons', value: '$duplicateRate%'),
138:            if (commune.lastCodeGeneratedAt != null) ...[
140:              Text('Derniere activite: ${commune.lastCodeGeneratedAt}'),
148:                  onPressed: () => Navigator.of(context).pushNamed('/super/activity/commune/${commune.communeId}'),
154:                    arguments: {'communeId': commune.communeId},
```

### ./flutter_app/lib/pages/vote_confirmation_page.dart
```text
6:    this.communeName,
11:  final String? communeName;
41:                    if (pollTitle != null || communeName != null) ...[
54:                              if (communeName != null) ...[
56:                                Text('Commune: $communeName', textAlign: TextAlign.center),
```

### ./flutter_app/lib/pages/vote_page.dart
```text
131:          'communeName': validation.communeName,
183:                'Aucune consultation n\'est ouverte pour votre commune actuellement.',
193:          communeName: validation.communeName,
479:    required this.communeName,
484:  final String communeName;
500:            Text('Commune: $communeName', style: theme.textTheme.bodyMedium),
```

### ./flutter_app/lib/routes/app_router.dart
```text
10:import '../pages/commune_controller_activity_page.dart';
25:import '../pages/super_admin_communes_page.dart';
74:      case '/super/communes':
76:            settings, const SuperAdminCommunesPage(), const ['super_admin']);
86:            settings, const AdminDashboardPage(), const ['commune_admin']);
101:          const ['commune_admin'],
107:          const ['commune_admin'],
111:            settings, const AdminCreatePollPage(), const ['commune_admin']);
114:            settings, const AdminAnalyticsPage(), const ['commune_admin']);
117:            settings, const AdminSupportListScreen(), const ['commune_admin']);
120:            settings, const AdminCreateTicketScreen(), const ['commune_admin']);
123:            settings, const AdminSettingsPage(), const ['commune_admin']);
182:            communeName: _readStringArgument(settings.arguments, 'communeName'),
215:            uri.pathSegments[2] == 'commune') {
218:            CommuneControllerActivityPage(communeId: uri.pathSegments[3]),
229:            const ['commune_admin'],
249:            const ['commune_admin', 'super_admin'],
260:            const ['commune_admin', 'super_admin'],
```

### ./flutter_app/lib/screens/admin/support/admin_support_list_screen.dart
```text
26:    final communeId = session?.commune?.code?.trim().isNotEmpty == true
27:        ? session!.commune!.code!.trim()
28:        : session?.commune?.name.trim() ?? '';
57:            stream: SupportTicketService.instance.watchAdminTickets(communeId),
```

### ./flutter_app/lib/screens/super_admin/support/super_admin_support_list_screen.dart
```text
62:                      labelText: 'Recherche par commune, sujet, catégorie ou email admin',
102:                        showCommune: true,
129:      return ticket.communeName.toLowerCase().contains(search) ||
```

### ./flutter_app/lib/screens/super_admin/support/super_admin_ticket_detail_screen.dart
```text
175:            Text('${ticket.communeName} · ${ticket.createdByName}${ticket.createdByEmail.isEmpty ? '' : ' · ${ticket.createdByEmail}'}'),
```

### ./flutter_app/lib/services/admin_analytics_service.dart
```text
125:          .loadAccessCodesForCurrentCommune();
134:          .loadVoteDatesForCurrentCommune();
148:          pollId: 'commune_access',
149:          pollName: 'Acces citoyens commune',
```

### ./flutter_app/lib/services/admin_auth_service.dart
```text
40:    late http.Response response;
70:      role: claims['role'] as String? ?? 'commune_admin',
77:      commune: profile['communeName'] is String && (profile['communeName'] as String).isNotEmpty
78:          ? AuthSessionCommune(
79:              name: profile['communeName'] as String,
80:              code: profile['communeId'] as String?,
```

### ./flutter_app/lib/services/auth_session_store.dart
```text
5:class AuthSessionCommune {
6:  const AuthSessionCommune({
9:    this.codePostal,
14:  final String? codePostal;
19:        'codePostal': codePostal,
22:  static AuthSessionCommune? fromJson(Object? raw) {
32:    return AuthSessionCommune(
35:      codePostal: raw['codePostal'] as String?,
50:    this.commune,
61:  final AuthSessionCommune? commune;
64:  bool get isCommuneAdmin => role == 'commune_admin' || role == 'admin' || (admin && !isSuperAdmin);
65:  bool get isAdmin => isCommuneAdmin;
74:      if ((roleName == 'admin' || roleName == 'commune_admin') && isCommuneAdmin) return true;
89:        'commune': commune?.toJson(),
102:      commune: AuthSessionCommune.fromJson(json['commune']),
```

### ./flutter_app/lib/services/backend_diagnostics.dart
```text
18:  static String? describeConfigIssue({Uri? pageOrigin, String? apiBaseUrl}) {
29:    final origin = pageOrigin ?? Uri.base;
```

### ./flutter_app/lib/services/citizen_access_code_service.dart
```text
67:    required this.communeId,
68:    required this.communeName,
78:    required this.addressProofChecked,
79:    required this.communeEligibilityChecked,
86:  final String communeId;
87:  final String communeName;
98:  final bool addressProofChecked;
99:  final bool communeEligibilityChecked;
111:    bool? addressProofChecked,
112:    bool? communeEligibilityChecked,
116:      communeId: communeId,
117:      communeName: communeName,
129:      addressProofChecked: addressProofChecked ?? this.addressProofChecked,
130:      communeEligibilityChecked:
131:          communeEligibilityChecked ?? this.communeEligibilityChecked,
140:        'communeId': communeId,
141:        'communeName': communeName,
151:        'addressProofChecked': addressProofChecked,
152:        'communeEligibilityChecked': communeEligibilityChecked,
158:        'communeId': communeId,
159:        'communeName': communeName,
169:        'addressProofChecked': addressProofChecked,
170:        'communeEligibilityChecked': communeEligibilityChecked,
189:      communeId: json['communeId'] as String? ?? '',
190:      communeName: json['communeName'] as String? ?? '',
208:      addressProofChecked: json['addressProofChecked'] as bool? ??
211:      communeEligibilityChecked: json['communeEligibilityChecked'] as bool? ??
212:          verification['communeEligibilityChecked'] as bool? ??
226:    required this.communeId,
227:    required this.communeName,
240:  final String communeId;
241:  final String communeName;
254:        'communeId': communeId,
255:        'communeName': communeName,
269:        'communeId': communeId,
270:        'communeName': communeName,
291:      communeId: communeId,
292:      communeName: communeName,
311:      communeId: json['communeId'] as String? ?? '',
312:      communeName: json['communeName'] as String? ?? '',
329:    required this.communeId,
330:    required this.communeName,
339:  final String communeId;
340:  final String communeName;
349:        'communeId': communeId,
350:        'communeName': communeName,
360:        'communeId': communeId,
361:        'communeName': communeName,
373:      communeId: json['communeId'] as String? ?? '',
374:      communeName: json['communeName'] as String? ?? '',
404:    this.communeId,
411:  final String? communeId;
444:class CommuneAnalyticsModel {
445:  const CommuneAnalyticsModel({
446:    required this.communeId,
447:    required this.communeName,
456:  final String communeId;
457:  final String communeName;
481:    required bool addressProofChecked,
482:    required bool communeEligibilityChecked,
494:      addressProofChecked: addressProofChecked,
495:      communeEligibilityChecked: communeEligibilityChecked,
515:    String? communeId,
525:        if (communeId?.isNotEmpty == true) {
526:          query = query.where('communeId', isEqualTo: communeId);
546:      if (communeId?.isNotEmpty == true && item.communeId != communeId) {
573:      loadAccessCodesForCurrentCommune() async {
575:    final communeId = _sessionCommuneId(session);
582:        if (communeId.isNotEmpty && communeId != 'unknown-commune') {
583:          query = query.where('communeId', isEqualTo: communeId);
597:    if (communeId.isEmpty ||
598:        communeId == 'unknown-commune' ||
604:    return records.where((item) => item.communeId == communeId).toList()
660:    ({String id, String name})? communeOverride,
680:      if (filters.communeId?.isNotEmpty == true) {
681:        query = query.where('communeId', isEqualTo: filters.communeId);
704:    String? communeId,
709:      communeId: communeId,
721:      if (communeId?.isNotEmpty == true) {
722:        query = query.where('communeId', isEqualTo: communeId);
```

### ./flutter_app/lib/services/citizen_commune_store.dart
```text
3:class CitizenCommuneContext {
4:  const CitizenCommuneContext({
5:    required this.communeId,
6:    required this.communeName,
9:  final String communeId;
10:  final String communeName;
12:  bool get hasScope => communeId.isNotEmpty || communeName.isNotEmpty;
15:        'communeId': communeId,
16:        'communeName': communeName,
19:  static CitizenCommuneContext? fromJson(Map<String, dynamic>? json) {
21:    final communeId = (json['communeId'] as String? ?? '').trim();
22:    final communeName = (json['communeName'] as String? ?? '').trim();
23:    if (communeId.isEmpty && communeName.isEmpty) return null;
24:    return CitizenCommuneContext(
25:      communeId: communeId,
26:      communeName: communeName,
31:class CitizenCommuneStore {
32:  CitizenCommuneStore._();
34:  static final CitizenCommuneStore instance = CitizenCommuneStore._();
36:  static const _storageKey = 'citizen_commune_context_v1';
38:  CitizenCommuneContext? _cachedContext;
40:  CitizenCommuneContext? get cachedContext => _cachedContext;
42:  Future<CitizenCommuneContext?> currentContext() async {
44:    _cachedContext = CitizenCommuneContext.fromJson(
51:    required String communeId,
52:    required String communeName,
54:    final context = CitizenCommuneContext(
55:      communeId: communeId.trim(),
56:      communeName: communeName.trim(),
```

### ./flutter_app/lib/services/citizen_public_access_service.dart
```text
17:    required this.communeId,
18:    required this.communeName,
24:  final String communeId;
25:  final String communeName;
38:    this.communeId = '',
45:  final String communeId;
54:      communeId: json['communeId'] as String? ?? '',
106:      communeId: validation.communeId,
107:      communeName: validation.communeName,
118:  Future<List<DateTime>> loadVoteDatesForCurrentCommune() async {
120:    final communeId = session?.commune?.code ?? session?.commune?.name ?? '';
127:        if (communeId.isNotEmpty) {
128:          query = query.where('communeId', isEqualTo: communeId);
151:    String? communeId,
164:        if (communeId?.isNotEmpty == true) {
165:          query = query.where('communeId', isEqualTo: communeId);
184:      if (communeId?.isNotEmpty == true &&
185:          item.communeId.isNotEmpty &&
186:          item.communeId != communeId) {
```

### ./flutter_app/lib/services/commune_lookup_service.dart
```text
5:/// Une commune normalisee issue du referentiel officiel (geo.api.gouv.fr) :
6:/// nom, code INSEE et codes postaux. Sert de source unique pour rendre le
7:/// remplissage ville / CP / INSEE predictif et coherent dans toute l'app.
8:class CommuneSuggestion {
9:  const CommuneSuggestion({
15:  /// Nom officiel de la commune (ex. "Les Abymes").
18:  /// Code INSEE (ex. "97101"). Peut contenir 2A/2B pour la Corse.
21:  /// Codes postaux rattaches a la commune.
24:  String get firstPostal => codesPostaux.isNotEmpty ? codesPostaux.first : '';
29:  static CommuneSuggestion? fromApi(Object? raw) {
31:    final nom = CommuneLookupService.normalizeCommuneName(raw['nom'] as String?);
32:    final code = CommuneLookupService.normalizeInsee(raw['code'] as String?);
35:            ?.map((c) => CommuneLookupService.normalizePostal('$c'))
39:    return CommuneSuggestion(nom: nom, code: code, codesPostaux: codesPostaux);
43:/// Recherche et normalise les communes via le referentiel officiel
44:/// geo.api.gouv.fr. Centralise la logique autrefois dupliquee dans les
46:class CommuneLookupService {
47:  CommuneLookupService({http.Client? client})
50:  static final CommuneLookupService instance = CommuneLookupService();
54:  static const _fields = 'nom,code,codesPostaux,population';
56:  /// Nom de commune : trim + espaces multiples reduits.
57:  static String normalizeCommuneName(String? value) =>
60:  /// Code INSEE : majuscules, sans espaces (gere 2A/2B Corse).
61:  static String normalizeInsee(String? value) =>
64:  /// Code postal : chiffres uniquement, tronque a 5.
65:  static String normalizePostal(String? value) {
70:  /// Recherche par nom (texte) ou par code postal (2 a 5 chiffres).
72:  Future<List<CommuneSuggestion>> search(String query) async {
76:    final isPostal = RegExp(r'^\d{2,5}$').hasMatch(q);
77:    final url = isPostal
78:        ? 'https://geo.api.gouv.fr/communes?codePostal=$q&fields=$_fields&limit=10'
79:        : 'https://geo.api.gouv.fr/communes?nom=${Uri.encodeComponent(q)}&fields=$_fields&boost=population&limit=10';
87:        .map(CommuneSuggestion.fromApi)
88:        .whereType<CommuneSuggestion>()
```

### ./flutter_app/lib/services/controleur_profile_service.dart
```text
14:    required this.communeName,
15:    this.communeCode,
16:    this.codePostal,
25:  final String communeName;
26:  final String? communeCode;
27:  final String? codePostal;
39:        'commune': {
40:          'name': communeName,
41:          'code': communeCode,
42:          'codePostal': codePostal,
61:    final commune = raw['commune'] as Map<String, dynamic>?;
71:      communeName: commune?['name'] as String? ?? '',
72:      communeCode: commune?['code'] as String?,
73:      codePostal: commune?['codePostal'] as String?,
108:    required String communeName,
109:    String? communeCode,
110:    String? codePostal,
115:    if (communeName.trim().isEmpty) {
116:      throw const ControleurProfileException('La commune est requise.');
122:      'communeName': communeName.trim(),
123:      if (communeCode != null && communeCode.trim().isNotEmpty)
124:        'communeCode': communeCode.trim(),
125:      if (codePostal != null && codePostal.trim().isNotEmpty)
126:        'codePostal': codePostal.trim(),
166:    late http.Response response;
```

### ./flutter_app/lib/services/controller_auth_service.dart
```text
43:    late http.Response response;
79:      commune: AuthSessionCommune.fromJson(profile['commune']),
```

### ./flutter_app/lib/services/firebase_auth_service.dart
```text
24:        options: DefaultFirebaseOptions.currentPlatform,
45:      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
194:  /// long-lived sessions do not silently drift past the 1h expiry.
```

### ./flutter_app/lib/services/new_poll_badge_service.dart
```text
8:import 'citizen_commune_store.dart';
11:/// Tracks published polls not yet seen by the current citizen commune.
26:  _CommuneScope? _lastScope;
30:  Future<_CommuneScope?> _communeScope() async {
32:    final sessionCommuneId = session?.commune?.code?.trim() ?? '';
33:    final sessionCommuneName = session?.commune?.name.trim() ?? '';
34:    if (sessionCommuneId.isNotEmpty || sessionCommuneName.isNotEmpty) {
35:      return _CommuneScope(
36:        communeId: sessionCommuneId,
37:        communeName: sessionCommuneName,
41:    final citizenContext = await CitizenCommuneStore.instance.currentContext();
43:    return _CommuneScope(
44:      communeId: citizenContext.communeId,
45:      communeName: citizenContext.communeName,
56:    _CommuneScope scope,
59:    if (scope.communeId.isNotEmpty) {
60:      return collection.where('communeId', isEqualTo: scope.communeId);
62:    return collection.where('communeName', isEqualTo: scope.communeName);
108:    _CommuneScope scope,
129:    final scope = await _communeScope();
153:  /// Queries Firestore for published polls of the user's commune.
161:    final scope = await _communeScope();
184:    final scope = _lastScope ?? await _communeScope();
200:class _CommuneScope {
201:  const _CommuneScope({
202:    required this.communeId,
203:    required this.communeName,
206:  final String communeId;
207:  final String communeName;
209:  bool get hasScope => communeId.isNotEmpty || communeName.isNotEmpty;
212:      communeId.isNotEmpty ? 'id:$communeId' : 'name:$communeName';
```

### ./flutter_app/lib/services/poll_service.dart
```text
45:        session?.isCommuneAdmin == true || session?.isController == true;
46:    final communeScope = isAuthenticated
47:        ? (session?.commune?.code ?? session?.commune?.name ?? '')
68:            return _filterByCommuneScope(polls, communeScope);
79:      return _filterByCommuneScope(polls, communeScope);
86:        return _filterByCommuneScope(polls, communeScope);
94:      return _filterByCommuneScope(polls, communeScope);
97:      return _filterByCommuneScope(polls, communeScope);
116:    String targetPopulation = '',
131:      'targetPopulation': targetPopulation.trim(),
135:      'communeId': session?.commune?.code,
136:      'communeName': session?.commune?.name,
176:    String targetPopulation = '',
189:      'targetPopulation': targetPopulation.trim(),
251:    late http.Response response;
298:  List<PollModel> _filterByCommuneScope(
299:      List<PollModel> polls, String communeScope) {
300:    if (communeScope.isEmpty) {
305:      if (poll.communeId.isNotEmpty) {
306:        return poll.communeId == communeScope;
308:      if (poll.communeName.isNotEmpty) {
309:        return poll.communeName.toLowerCase() == communeScope.toLowerCase();
```

### ./flutter_app/lib/services/push_notification_service.dart
```text
70:              'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
82:  Future<void> registerForCitizenCommune({
84:    required String communeId,
85:    required String communeName,
88:    if (communeId.trim().isEmpty && communeName.trim().isEmpty) return;
121:              'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
122:              'communeId': communeId.trim(),
123:              'communeName': communeName.trim(),
```

### ./flutter_app/lib/services/super_admin_service.dart
```text
25:    required this.communeName,
26:    this.communeCode,
27:    this.codePostal,
34:  final String communeName;
35:  final String? communeCode;
36:  final String? codePostal;
43:        'communeName': communeName,
44:        'communeCode': communeCode,
45:        'codePostal': codePostal,
52:        communeName: communeName,
53:        communeCode: communeCode,
54:        codePostal: codePostal,
63:    final communeName = raw['communeName'] as String?;
67:        communeName == null ||
74:      communeName: communeName,
75:      communeCode: raw['communeCode'] as String?,
76:      codePostal: raw['codePostal'] as String?,
110:    late http.Response response;
200:    late http.Response response;
272:                    communeName: item['communeName'] as String? ?? '',
273:                    communeCode: item['communeCode'] as String?,
274:                    codePostal: item['codePostal'] as String?,
307:  /// Crée un profil admin rattaché à une commune via l'API backend (la clé
311:    required String communeName,
312:    String? communeCode,
313:    String? codePostal,
316:    final trimmedCommuneName = communeName.trim();
317:    final trimmedCommuneCode = communeCode?.trim() ?? '';
318:    final trimmedCodePostal = codePostal?.trim() ?? '';
320:    if (trimmedCommuneName.isEmpty) {
321:      throw const SuperAdminAuthException('Le nom de la commune est requis.');
323:    if (trimmedCodePostal.isEmpty) {
324:      throw const SuperAdminAuthException('Le code postal est requis.');
326:    if (trimmedCommuneCode.isEmpty) {
327:      throw const SuperAdminAuthException('Le code INSEE est requis.');
337:      'communeName': trimmedCommuneName,
338:      'communeCode': trimmedCommuneCode,
339:      'codePostal': trimmedCodePostal,
346:      communeName: payload['communeName'] as String? ?? trimmedCommuneName,
347:      communeCode: payload['communeCode'] as String?,
348:      codePostal: payload['codePostal'] as String?,
383:    late String token;
400:    late http.Response response;
```

### ./flutter_app/lib/services/support_ticket_service.dart
```text
26:  Stream<List<SupportTicket>> watchAdminTickets(String communeId) {
42:  Stream<List<SupportTicket>> watchUnreadTicketsForAdmin(String communeId) {
43:    return watchAdminTickets(communeId).map(
82:    if (session?.isCommuneAdmin != true || session?.isSuperAdmin == true) {
86:    final communeId = (session?.commune?.code?.trim().isNotEmpty == true
87:            ? session!.commune!.code
88:            : session?.commune?.name)
90:    final communeName = session?.commune?.name.trim() ?? communeId ?? '';
91:    if (communeId == null || communeId.isEmpty || communeName.isEmpty) {
92:      throw const SupportTicketException('Commune rattachée introuvable.');
104:        'communeName': communeName,
126:    final isAdmin = session?.isCommuneAdmin == true;
265:    late http.Response response;
```

### ./flutter_app/lib/services/vote_access_service.dart
```text
78:    required this.communeId,
79:    required this.communeName,
85:  final String communeId;
86:  final String communeName;
142:        communeId: payload['communeId'] as String? ?? '',
143:        communeName: payload['communeName'] as String? ?? '',
```

### ./flutter_app/lib/widgets/analytics_widgets.dart
```text
6:/// Palette commune aux widgets analytiques premium.
12:  static const Color slate = Color(0xFF334155);
13:  static const Color slateMuted = Color(0xFF64748B);
138:              color: AnalyticsPalette.slateMuted,
150:              color: AnalyticsPalette.slate,
160:                color: AnalyticsPalette.slateMuted,
294:                  color: AnalyticsPalette.slate,
302:                  color: AnalyticsPalette.slateMuted,
314:                    color: AnalyticsPalette.slateMuted,
446:                      color: AnalyticsPalette.slate,
455:                    color: AnalyticsPalette.slate,
515:                  color: AnalyticsPalette.slateMuted,
```

### ./flutter_app/lib/widgets/commune_autocomplete_field.dart
```text
6:import '../services/commune_lookup_service.dart';
8:/// Champ "Commune" avec autocompletion predictive (referentiel officiel).
11:/// [onSelected] est appele avec la commune complete (nom + code INSEE + CP) afin
12:/// que le parent remplisse les champs lies (code postal, INSEE).
13:class CommuneAutocompleteField extends StatefulWidget {
14:  const CommuneAutocompleteField({
19:    this.labelText = 'Commune *',
20:    this.hintText = 'Tapez le nom ou le code postal…',
27:  final ValueChanged<CommuneSuggestion> onSelected;
33:  final CommuneLookupService? lookupService;
36:  State<CommuneAutocompleteField> createState() =>
37:      _CommuneAutocompleteFieldState();
40:class _CommuneAutocompleteFieldState extends State<CommuneAutocompleteField> {
42:  List<CommuneSuggestion> _suggestions = const [];
45:  CommuneLookupService get _service =>
46:      widget.lookupService ?? CommuneLookupService.instance;
65:      List<CommuneSuggestion> results = const [];
70:          debugPrint('[CommuneAutocompleteField] recherche echouee: $error');
82:  void _select(CommuneSuggestion commune) {
84:      widget.controller.text = commune.nom;
88:    widget.onSelected(commune);
112:                : const Icon(Icons.location_on_outlined),
142:                  leading: const Icon(Icons.location_city_rounded,
147:                    '${c.codesPostaux.join(', ')}  •  INSEE ${c.code}',
```

### ./flutter_app/lib/widgets/super_admin_controller_activity_tile.dart
```text
41:                  _Metric(label: 'Doublons', value: analytics.duplicatesDetected),
```

### ./flutter_app/lib/widgets/super_admin_duplicate_tile.dart
```text
8:    required this.latestRequests,
14:  final List<DuplicateCodeRequestModel> latestRequests;
34:                  Expanded(child: Text('Doublons à vérifier', style: theme.textTheme.titleLarge)),
46:              for (final request in latestRequests.take(3))
50:                    '${request.communeName} · ${request.requestedByControllerName} · dossier ${request.id} · ${request.status}',
```

### ./flutter_app/lib/widgets/support/ticket_card.dart
```text
11:    this.showCommune = false,
20:  final bool showCommune;
47:                        if (showCommune && ticket.communeName.isNotEmpty) ...[
49:                            ticket.communeName,
```

### ./flutter_app/test/backend_diagnostics_test.dart
```text
11:        pageOrigin: Uri.parse('https://citoyen-peyi.web.app/'),
20:        pageOrigin: Uri.parse('https://citoyen-peyi.web.app/'),
31:        pageOrigin: Uri.parse('https://citoyen-peyi.web.app/'),
41:        pageOrigin: Uri.parse('https://citoyen-peyi.web.app/'),
51:        pageOrigin: Uri.parse('https://citoyen-peyi.web.app/'),
```

### ./flutter_app/test/commune_lookup_service_test.dart
```text
1:import 'package:citoyen_peyi_flutter/services/commune_lookup_service.dart';
5:  group('CommuneLookupService normalisation', () {
6:    test('normalizeCommuneName trims and collapses whitespace', () {
7:      expect(CommuneLookupService.normalizeCommuneName('  Les   Abymes '),
9:      expect(CommuneLookupService.normalizeCommuneName(null), '');
12:    test('normalizeInsee uppercases and strips spaces (handles 2A/2B)', () {
13:      expect(CommuneLookupService.normalizeInsee(' 97101 '), '97101');
14:      expect(CommuneLookupService.normalizeInsee('2a004'), '2A004');
15:      expect(CommuneLookupService.normalizeInsee(null), '');
18:    test('normalizePostal keeps digits only, max 5', () {
19:      expect(CommuneLookupService.normalizePostal('97 122'), '97122');
20:      expect(CommuneLookupService.normalizePostal('971225'), '97122');
21:      expect(CommuneLookupService.normalizePostal('abc'), '');
24:    test('CommuneSuggestion.fromApi normalises every field', () {
25:      final suggestion = CommuneSuggestion.fromApi({
34:      expect(suggestion.firstPostal, '97139');
38:    test('CommuneSuggestion.fromApi rejects entries without name or code', () {
39:      expect(CommuneSuggestion.fromApi({'nom': '', 'code': '97101'}), isNull);
40:      expect(CommuneSuggestion.fromApi({'nom': 'X', 'code': ''}), isNull);
41:      expect(CommuneSuggestion.fromApi('not-a-map'), isNull);
```

### ./flutter_app/test/vote_access_service_test.dart
```text
44:              'communeId': 'commune-1',
45:              'communeName': 'Fort-de-France',
68:      expect(result.communeName, 'Fort-de-France');
```

### ./flutter_app/test/vote_page_test.dart
```text
14:        communeId: 'commune-1',
15:        communeName: 'Fort-de-France',
43:        communeId: 'commune-1',
44:        communeName: 'Fort-de-France',
```

### ./flutter_app/test/widget_test.dart
```text
83:    await tester.enterText(find.byType(TextField), 'CP-2026-ABCD');
123:  testWidgets('commune admin dashboard renders assistance without grey screen',
129:        role: 'commune_admin',
135:        commune: AuthSessionCommune(name: 'Les Abymes', code: '97101'),
145:    expect(find.text('Tableau de bord commune'), findsWidgets);
157:  testWidgets('commune admin assistance page renders on mobile without grey screen',
168:        role: 'commune_admin',
174:        commune: AuthSessionCommune(name: 'Les Abymes', code: '97101'),
192:  testWidgets('commune admin assistance button opens support page',
198:        role: 'commune_admin',
204:        commune: AuthSessionCommune(name: 'Les Abymes', code: '97101'),
233:  testWidgets('commune admin assistance button opens support page on mobile',
244:        role: 'commune_admin',
250:        commune: AuthSessionCommune(name: 'Les Abymes', code: '97101'),
310:      communeId: '97101',
311:      communeName: 'Les Abymes',
```

### ./flutter_app/web/firebase-messaging-sw.js
```text
5:  apiKey: 'AIzaSyCPbwCjZivExVMV6iJQvQLcnjAfr1m3CMA',
20:    body: notification.body || 'Une consultation est ouverte dans votre commune.',
```

### ./flutter_app/web/manifest.json
```text
5:  "display": "standalone",
8:  "description": "Plateforme de consultation citoyenne anonyme",
10:  "prefer_related_applications": false,
```

### ./github-deploy-citoyen-peyi.json
```text
5:  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDKATMH0fvXuRlm\nq/o/aPgJmpUdApFF8l8K1pGNavrBCNultM5kWFcIQEzD9ZIo8mAxqP7SGtJMZPwy\nKmGZY85L+yr+naxMloer3hKCczj6iyYD9VKfp/8J4ea6toZPwjrcSCvCMPNF1+TS\n5cke04Zh26+2sdL9n4W3hTRdke8xhs9WN2Hw0CE0P1osq/9593M708l5WSSg/Ctf\nYVvRkjJHM3BCPcr3gEXgMRTeh83M+qFZLGKgNKV5RDkkZ27qMKEEaHHsfTe+0NTV\nh336lZUFQ0jnY0+2aRqXVKiCjizaOOZMTDziazj4T+DPzalIRDCtYs+053rO8GZu\n4aevN3B9AgMBAAECggEAF4MEOYjLU1SMDFNAEVlaZWPEr1e5KPcI8O4AiwFEpmst\nhaAB1dQibSdux/AxTurHH4CYCERu7c1jPUOJkJz5Sga1/mTDxTZQHEUAyoY2v5Kq\nnhNTxpl7Kd9NR7Yu8+GbkEAmN7gS2LJEQ/fS7O+Z2JIFZbJU6IhEvBOZALsXqB/f\nqXf3+VYtv96ReHXDhyJQL2yHoNuI94xPrnhTIN6nh7IYgoZbMgQQl+h3UBne41Ww\nz/wR02nCfQoXDOmnq9pVAL7y8kMTLYzIRlmxwwm+TFiz9ijF6ttUJQ7tGysfOHDv\nFp7aVxw++sSK2Z5CLUzVdIkr6UdA7biD6ExAxSF/gQKBgQD3hTBFVhJinI9rQoET\nLfkPsN1FSZtjO2aWlkZ8L7Y/ghnK4k+iX3pcUhhUMzsk66Y65MqLGf9LRx+a377Q\nZYbYbvJwpQRaxjGEqGhdiTE0ByiLR+sr1+YJMa9Zzqifh899EUiVlceHDyceI5kZ\n9vGncvNtPaCJjhGzl6Vh3xnriQKBgQDQ7NQNH28+Uoq0A9VpPwtu5SZWob2xuKMq\nX1JlboTPyb59FMrt6uAaSTHhztV8ii/hof612MgD6xwGEijvamsyqoniGCaomIGV\nm84sxMXtm70Hfo4nPNeskXCcoI7itvQ7vMLqn4Os17lI+gdTupn+pO9vztTDLPQf\nalwNYn9cVQKBgQCjlanGWVFDTPdYSxalR1/wp9JFRZVlqs9tPJoO3zWSmXhUZud8\nh5+FvlgH5efzya4OBEF8V00rQjE4GSGx9zd8eS7Pla/gElaNtwNqtg4HtadtDbX2\nPvTwJJ8gOn2lGYveu3p+KgQ5VaFjwOEhkNw677TEANPFtVgrmlCZ82ndCQKBgEd8\nQTIcR1vzsjHV/fd88tSG449Q2C8vFeUxqGe8YQUX6m2x551weC2GTeMNek6ambeC\nTjy6Z/WvRG9vV0JUD0nOwE70JIYbaHtgTDNVQMQEPbGKw+j5EHKjcPymkz1PjFHE\nTI0q90r0pRkrM8aaWoaeuK5w/qupff4hzk1mHl3hAoGBAKzbOSmLBLMwm9F/Of4g\n2zea3/cNU4Dgq37NmVlCO5TdECkyfB/bPMBttzPM3chLdwGdFoyJ6M//dxR2x8TK\n20HMLcLGKLS/NqzFuJJ4/1S5L3bCgFgXxyGdyB9ITTkxEUDRu78eLgIQgX9hBOER\na4Wvg2xFbdBBQMCBzIGHUZOk\n-----END PRIVATE KEY-----\n",
```

### ./package-lock.json
```text
39:      "integrity": "sha512-zz3i6e13B8BfWiLy8MABtTh8aGIACgKbf9UVnyHcWs+yQzJXgQcl8A46b0zfaiJHdQ+niF0ouAfcpuf+3LMPQg==",
218:    "node_modules/@google-cloud/storage/node_modules/gcp-metadata": {
220:      "resolved": "https://registry.npmjs.org/gcp-metadata/-/gcp-metadata-6.1.1.tgz",
243:        "gcp-metadata": "^6.1.0",
283:        "long": "^5.0.0",
302:        "long": "^5.0.0",
356:      "integrity": "sha512-j+gKExEuLmKwvz3OgROXtrJ2UG2x8Ch2YZUxahh+s1F2HZ+wAceUNLkvy6zKCPVRkU++ZWQrdxsUeQXmcg4uoQ==",
512:    "node_modules/@types/long": {
514:      "resolved": "https://registry.npmjs.org/@types/long/-/long-4.0.2.tgz",
515:      "integrity": "sha512-MqTGEo5bj5t157U6fA/BiDynNkn0YknVdh48CMPkTSpFTVmvao5UQmm7uEF6xBEo7qIMAlY/JSleYaE6VOdpaA==",
615:    "node_modules/array-flatten": {
617:      "resolved": "https://registry.npmjs.org/array-flatten/-/array-flatten-1.1.1.tgz",
785:      "integrity": "sha512-RRECPsj7iu/xb5oKYcsFHSppFNnsj/52OVTRKb4zP5onXwVF3zVmmToNcOfGC+CRDpfK/U584fMg38ZHCaElKQ==",
899:      "integrity": "sha512-2sJGJTaXIIaR1w4iJSNoN0hnMY7Gpc/n8D4qSCJw8QqFWXf7cuAgnEHxBpweaVcPevC2l3KpjYCx3NypQQgaJg==",
1051:      "integrity": "sha512-aIL5Fx7mawVa300al2BnEE4iNvo1qETxLrPI/o05L7z6go7fCw1J6EQmbK4FmJ2AS7kgVF/KEZWufBfdClMcPg==",
1074:        "array-flatten": "1.1.1",
1131:      "integrity": "sha512-fjquC59cD7CyW6urNXK0FBufkZcoiGG80wTuPujX590cB5Ttln20E2UB4S/WARVqhXffZl2LNgS+gQdPIIim/g==",
1192:      "integrity": "sha512-CzbClwlXAuiRQAlUyfqPgvPoNKTckTPGfwZV4ZdAhVcP2lh9KUxJg2b5GkE7XbjKQ3YJnQ9z6D9ntLAlB+tP8g==",
1281:      "integrity": "sha512-7XHNxH7qX9xG5mIwxkhumTox/MIRNcOgDrxWsMt2pAr23WHp6MrRlN7FBSFpCpr+oVO0F744iUgR82nJMfG2SA==",
1311:    "node_modules/gcp-metadata": {
1313:      "resolved": "https://registry.npmjs.org/gcp-metadata/-/gcp-metadata-8.1.2.tgz",
1325:    "node_modules/gcp-metadata/node_modules/gaxios": {
1360:      "integrity": "sha512-9fSjSaos/fRIVIp+xSJlE6lfwhES7LNtKaCBIamHsjr2na1BiABJPo0mOjjz8GJDURarmCPGqaiVg5mfjb98CQ==",
1403:        "gcp-metadata": "8.1.2",
1434:        "@types/long": "^4.0.0",
1449:    "node_modules/google-gax/node_modules/gcp-metadata": {
1451:      "resolved": "https://registry.npmjs.org/gcp-metadata/-/gcp-metadata-6.1.1.tgz",
1474:        "gcp-metadata": "^6.1.0",
1782:      "integrity": "sha512-MT/xP0CrubFRNLNKvxJ2BYfy53Zkm++5bX9dtuPbqAeQpTVe0MQTFhao8+Cp//EmJp244xt6Drw/GVEGCUj40g==",
1879:    "node_modules/lodash.clonedeep": {
1881:      "resolved": "https://registry.npmjs.org/lodash.clonedeep/-/lodash.clonedeep-4.5.0.tgz",
1927:    "node_modules/long": {
1929:      "resolved": "https://registry.npmjs.org/long/-/long-5.3.2.tgz",
1952:        "lodash.clonedeep": "^4.5.0",
2029:      "integrity": "sha512-Tpp60P6IUJDTuOq/5Z8cdskzJujfwqfOTkrwIwj7IRISpnkJnT6SyJ4PCPnGMoFjC9ddhal5KVIYtAt97ix05A==",
2238:      "integrity": "sha512-SAzp/O4Yh02jGdRc+uIrGoe87dkN/XtwxfZ4ZyafJHymd79ozp5VG5nyZ7ygqPM5+cpLDjjGnYFUkngonyDPOQ==",
2267:        "long": "^5.3.2"
2361:      "integrity": "sha512-57frrGM/OCTLqLOAh0mhVA9VBMHd+9U7Zb2THMGdBUoZVOtGbJzjxsYGDJ3A9AYYCP4hn6y1TVbaOfzWtm5GFg==",
2397:      "integrity": "sha512-XQBQ3I8W1Cge0Seh+6gjj03LbmRFWuoszgK9ooCpwYIrhhoO80pfq4cUkU5DkknwfOfFteRwlZ56PYOGYyFWdg==",
2585:      "integrity": "sha512-WPS/HvHQTYnHisLo9McqBHOJk2FkHO/tlpvldyrnem4aeQp4hai3gythswg6p01oSoTl58rcpiFAjF2br2Ak2A==",
2673:      "integrity": "sha512-Y38VPSHcqkFrCpFnQ9vuSXmquuv5oXOKpGeT6aGrr3o3Gc9AlVa6JBfUSOCnbxGGZF+/0ooI7KrPuUSztUdU5A==",
2872:      "integrity": "sha512-2JAn3z8AR6rjK8Sm8orRC0h/bcl/DqL7tRPdGZ4I1CjdF+EaMLmYxBHyXuKL849eucPFhvBoxMsflfOb8kxaeQ==",
2878:      "integrity": "sha512-b17KeDIQVjvb0ssuSDF2cYXSg2iztliJ4B9WdsuB6J952qCPKmnVq4DyW5motImXHDC1cBT/1UezrJVsKw5zjg==",
```

### ./package.json
```text
26:    "zip": "bash app/scripts/zip-app.sh"
```

### ./storage.rules
```text
6:    function isAdminCommune() { return hasRole('adminCommune') || hasRole('commune_admin') || hasRole('admin'); }
13:      allow read:   if isAdminCommune() || isSuperAdmin();
14:      allow create: if isAdminCommune() && (isImage() || isPDF()) && maxMB(10);
17:    match /poll_assets/{communeId}/{pollId}/{fileName} {
19:      allow create, update: if isAdminCommune() && (isImage() || isPDF()) && maxMB(20);
20:      allow delete: if isAdminCommune() || isSuperAdmin();
22:    match /news_assets/{communeId}/{newsId}/{fileName} {
24:      allow create, update: if isAdminCommune() && isImage() && maxMB(5);
25:      allow delete: if isAdminCommune() || isSuperAdmin();
```

### ./tests/firestore-rules/rules.test.js
```text
38:  communeId: '97101',
39:  communeName: 'Les Abymes',
41:  createdByName: 'Admin commune',
65:  senderName: 'Admin commune',
100:  const adminDb = userDb('admin-1', { role: 'commune_admin', admin: true });
128:test('communeAdmins is fully closed to clients', async () => {
130:  await assertFails(getDoc(doc(superDb, 'communeAdmins/admin-1')));
131:  await assertFails(setDoc(doc(superDb, 'communeAdmins/admin-1'), { label: 'x' }));
135:  const adminDb = userDb('admin-1', { role: 'commune_admin', admin: true });
145:  const adminDb = userDb('admin-1', { role: 'commune_admin', admin: true });
150:  const adminDb = userDb('admin-1', { role: 'commune_admin', admin: true });
154:    communeId: 'commune-1',
158:test('commune admin can create and read own support ticket with first message', async () => {
159:  const adminDb = userDb('admin-1', { role: 'commune_admin', admin: true, communeId: '97101' });
169:test('commune admin support list query must stay scoped to own commune', async () => {
174:      communeId: '97102',
175:      communeName: 'Baie-Mahault',
180:  const adminDb = userDb('admin-1', { role: 'commune_admin', admin: true, communeId: '97101' });
181:  await assertSucceeds(getDocs(query(collection(adminDb, 'support_tickets'), where('communeId', '==', '97101'))));
185:test('commune admin cannot access another commune support ticket', async () => {
191:  const otherAdminDb = userDb('admin-2', { role: 'commune_admin', admin: true, communeId: '97102' });
223:test('commune admin can reply to own support ticket', async () => {
228:  const adminDb = userDb('admin-1', { role: 'commune_admin', admin: true, communeId: '97101' });
315:  const adminDb = userDb('admin-1', { role: 'commune_admin', admin: true, communeId: '97101' });
322:test('commune admin cannot mutate immutable support ticket fields', async () => {
327:  const adminDb = userDb('admin-1', { role: 'commune_admin', admin: true, communeId: '97101' });
329:    communeId: '97102',
336:test('commune admin cannot change support status or create super admin message', async () => {
341:  const adminDb = userDb('admin-1', { role: 'commune_admin', admin: true, communeId: '97101' });
350:  const adminDb = userDb('admin-1', { role: 'commune_admin', admin: true });
```

### app/backend/src/index.js
```text
47:      res.status(503).json({ message: 'Requete trop longue, reessayez.' });
```

### app/backend/src/middlewares/rateLimit.js
```text
37:  // faible mais reste fonctionnelle (max-instances volontairement bas). On
```

### app/backend/src/middlewares/requireFirebaseAuth.js
```text
27:export const isCommuneAdmin = (user) => hasRole(user, 'admin') || hasRole(user, 'commune_admin') || isSuperAdmin(user);
43:export const communeScopeFromUser = (user) => {
44:  if (typeof user?.communeId === 'string' && user.communeId.trim()) return user.communeId.trim();
45:  if (typeof user?.communeCode === 'string' && user.communeCode.trim()) return user.communeCode.trim();
55:export const requireCommuneAdmin = requireRole(isCommuneAdmin, 'Reserve aux administrateurs communaux.');
```

### app/backend/src/routes/admins.js
```text
10:const COLLECTION = 'communeAdmins';
40:          communeName: data.communeName,
41:          communeCode: data.communeCode,
42:          codePostal: data.codePostal,
56:    const communeName = sanitize(req.body?.communeName, 200);
57:    const communeCode = sanitize(req.body?.communeCode, 64);
58:    const codePostal = sanitize(req.body?.codePostal, 16);
60:    if (!label || !communeName) {
61:      return res.status(400).json({ message: 'Libelle et commune sont requis.' });
71:      communeName,
72:      communeCode,
73:      codePostal,
82:      communeName,
83:      communeCode,
84:      codePostal,
```

### app/backend/src/routes/auth.js
```text
124:      communeCode: record.commune?.code || '',
125:      communeId: record.commune?.code || record.commune?.name || '',
134:        commune: record.commune ?? null,
167:    let snapshot = await db.collection('communeAdmins').where('accessKeyHash', '==', accessKeyHash).limit(1).get();
170:      const legacySnapshot = await db.collection('communeAdmins').where('accessKeyHash', '==', hashLegacySha256(providedAccessKey)).limit(1).get();
174:        snapshot = await db.collection('communeAdmins').where('accessKeyHash', '==', accessKeyHash).limit(1).get();
179:    let communeId = '';
180:    let communeName = '';
182:    let adminScope = 'commune';
191:      communeId = data.communeCode || data.communeName || '';
192:      communeName = data.communeName || '';
208:      role: 'commune_admin',
211:      communeId,
212:      communeCode: communeId,
218:      profile: { id: adminId, label, communeId, communeName },
```

### app/backend/src/routes/citizenAccess.js
```text
70:  // augmenter la finesse de l'empreinte et reduire les faux doublons.
139:  communeId: data.communeId,
140:  communeName: data.communeName,
157:  communeId: data.communeId,
158:  communeName: data.communeName,
186:  const communeId = data.commune?.code || data.commune?.name || user?.communeCode || '';
187:  const tokenCommune = user?.communeId || user?.communeCode || '';
188:  if (tokenCommune && communeId && tokenCommune !== communeId) return null;
193:    communeId: communeId || 'unknown-commune',
194:    communeName: data.commune?.name || user?.communeCode || 'Commune non renseignee',
220:    communeId: payload.communeId,
221:    communeName: payload.communeName,
252:    // "all_open_polls" (toutes les consultations ouvertes de la commune).
275:        const existingAccessCodeId = fingerprint.latestAccessCodeId || fingerprint.firstAccessCodeId || '';
290:          communeId: controller.communeId,
291:          communeName: controller.communeName,
327:        communeId: controller.communeId,
328:        communeName: controller.communeName,
353:        latestAccessCodeId: accessRef.id,
354:        communeId: controller.communeId,
398:      if (req.query.communeId) query = query.where('communeId', '==', String(req.query.communeId));
411:    return res.status(500).json({ message: 'Lecture des demandes doublon impossible.' });
447:      const previousCodeId = fingerprint.latestAccessCodeId || request.existingAccessCodeId;
464:        communeId: request.communeId,
465:        communeName: request.communeName,
492:        latestAccessCodeId: newAccessRef.id,
506:        communeId: request.communeId,
507:        communeName: request.communeName,
551:      communeId: request.communeId,
552:      communeName: request.communeName,
611:      if (req.query.communeId) query = query.where('communeId', '==', String(req.query.communeId));
```

### app/backend/src/routes/controllers.js
```text
6:  communeScopeFromUser,
8:  requireCommuneAdmin,
53:    commune: data.commune,
74:  const scope = communeScopeFromUser(req.user);
75:  if (data.commune?.code !== scope) {
76:    res.status(403).json({ message: 'Ce controleur appartient a une autre commune.' });
93:router.use(ensureConfigured, requireFirebaseAuth, requireCommuneAdmin);
95:const resolveCommuneScope = (req) => {
98:      communeName: sanitize(req.body?.communeName, 200),
99:      communeCode: sanitize(req.body?.communeCode, 64),
100:      codePostal: sanitize(req.body?.codePostal, 16),
104:    communeName: sanitize(req.body?.communeName, 200) || communeScopeFromUser(req.user),
105:    communeCode: communeScopeFromUser(req.user),
106:    codePostal: sanitize(req.body?.codePostal, 16),
115:      const scope = communeScopeFromUser(req.user);
116:      if (!scope) return res.status(403).json({ message: 'Aucune commune attachee au compte.' });
117:      query = query.where('commune.code', '==', scope);
135:    const scope = resolveCommuneScope(req);
136:    if (!scope.communeName) {
137:      return res.status(400).json({ message: 'Commune requise pour creer un controleur.' });
147:      commune: {
148:        name: scope.communeName,
149:        code: scope.communeCode,
150:        codePostal: scope.codePostal,
```

### app/backend/src/routes/news.js
```text
6:  communeScopeFromUser,
8:  requireCommuneAdmin,
24:router.use(ensureConfigured, requireFirebaseAuth, requireCommuneAdmin);
33:    const communeId = isSuperAdmin(req.user)
34:      ? sanitize(req.body?.communeId, 64)
35:      : communeScopeFromUser(req.user);
36:    const communeName = sanitize(req.body?.communeName, 200);
44:      communeId,
45:      communeName,
63:    if (!isSuperAdmin(req.user) && communeScopeFromUser(req.user) && data.communeId !== communeScopeFromUser(req.user)) {
83:    if (!isSuperAdmin(req.user) && communeScopeFromUser(req.user) && data.communeId !== communeScopeFromUser(req.user)) {
```

### app/backend/src/routes/notifications.js
```text
22:    communeId: data.communeId || '',
23:    communeName: data.communeName || '',
44:  const platform = typeof req.body?.platform === 'string' ? req.body.platform.trim() : 'web';
64:      platform,
70:      communeId: access.communeId,
71:      communeName: access.communeName,
```

### app/backend/src/routes/polls.js
```text
6:  communeScopeFromUser,
7:  isCommuneAdmin,
9:  requireCommuneAdmin,
12:import { notifyCommunePollPublished } from '../services/notificationService.js';
78:const scopeFromAdmin = (user) => (isSuperAdmin(user) ? '' : communeScopeFromUser(user));
80:const requireMatchingCommune = (req, res, next) => {
82:  const scope = communeScopeFromUser(req.user);
84:    return res.status(403).json({ message: 'Aucune commune attachee au compte administrateur.' });
86:  req.communeScope = scope;
90:router.use(ensureConfigured, requireFirebaseAuth, requireCommuneAdmin);
97:    if (scope) query = query.where('communeId', '==', scope);
106:router.post('/', requireMatchingCommune, async (req, res, next) => {
126:    const communeId = req.communeScope || sanitizeString(req.body?.communeId, 64);
127:    const communeName = sanitizeString(req.body?.communeName, 200);
136:      targetPopulation: sanitizeString(req.body?.targetPopulation, 300),
141:      communeId,
142:      communeName,
152:    await notifyCommunePollPublished({ db, poll: responsePoll });
168:  if (!isSuperAdmin(req.user) && communeScopeFromUser(req.user) && data.communeId !== communeScopeFromUser(req.user)) {
169:    res.status(403).json({ message: 'Cette consultation appartient a une autre commune.' });
185:    if (typeof req.body?.targetPopulation === 'string') update.targetPopulation = sanitizeString(req.body.targetPopulation, 300);
216:      await notifyCommunePollPublished({
```

### app/backend/src/routes/support.js
```text
5:  communeScopeFromUser,
6:  isCommuneAdmin,
8:  requireCommuneAdmin,
69:    communeId: data.communeId || '',
70:    communeName: data.communeName || '',
116:const requireAdminCommuneScope = (req, res) => {
117:  const scope = communeScopeFromUser(req.user);
119:    res.status(403).json({ message: 'Aucune commune attachée au compte administrateur.' });
127:  if (!isCommuneAdmin(user)) return false;
128:  const scope = communeScopeFromUser(user);
129:  return Boolean(scope && ticket.communeId === scope);
162:router.use(ensureConfigured, requireFirebaseAuth, requireCommuneAdmin);
169:      const scope = requireAdminCommuneScope(req, res);
171:      query = query.where('communeId', '==', scope);
185:    const communeId = requireAdminCommuneScope(req, res);
186:    if (!communeId) return undefined;
192:    const communeName = sanitize(req.body?.communeName, 200) || communeId;
209:      communeId,
210:      communeName,
253:        communeName,
272:    const platform = sanitize(req.body?.platform, 40) || 'web';
282:      platform,
```

### app/backend/src/routes/voteAccess.js
```text
38:export const buildParticipationRecord = ({ pollId, participationHash, communeId }) => ({
41:  communeId,
45:export const buildAnonymousBallotRecord = ({ pollId, optionId, communeId }) => ({
48:  communeId,
80:export const signPollAccessToken = ({ pollId, communeId, participationHash }) => signAccessToken({
82:  communeId,
110:export const optionBelongsToPoll = (poll, optionId) => Array.isArray(poll.options)
119:    communeId: data.communeId || '',
120:    communeName: data.communeName || '',
142:    : await db.collection(POLL_COLLECTION).where('communeId', '==', access.communeId).limit(50).get();
155:      const sameCommune = !access.communeId || !poll.communeId || poll.communeId === access.communeId;
156:      if (!sameCommune || !isPollOpen(poll)) return null;
219:      return res.status(409).json({ ok: false, errorCode: 'POLL_CLOSED', message: 'Cette consultation n’est pas ouverte pour ce code.', communeId: access.communeId, communeName: access.communeName });
222:      return res.status(409).json({ ok: false, errorCode: 'NO_OPEN_POLL', message: 'Aucune consultation ouverte pour votre commune actuellement.', communeId: access.communeId, communeName: access.communeName });
231:          communeId: access.communeId,
241:      communeId: access.communeId,
242:      communeName: access.communeName,
269:    if (token.communeId && poll.communeId && token.communeId !== poll.communeId) {
270:      return { status: 403, errorCode: 'INVALID_CODE', message: 'Ce code n’est pas rattache a cette commune.' };
272:    if (!optionBelongsToPoll(poll, optionId)) {
288:      communeId: token.communeId || poll.communeId || '',
293:      communeId: token.communeId || poll.communeId || '',
```

### app/backend/src/scripts/loadSmokeTest.js
```text
111:  throw new Error(`P95 latency too high: ${p95.toFixed(2)}ms > ${P95_MAX_MS}ms`);
```

### app/backend/src/scripts/migrateRegistrationCodesToCitizenAccessCodes.js
```text
31:  communeId: data.communeId || '',
32:  communeName: data.communeName || '',
```

### app/backend/src/services/notificationService.js
```text
45:  const communeId = sanitizeString(poll?.communeId, 128);
51:      body: `${title} est ouverte dans votre commune.`,
56:      communeId,
74:  platform = 'web',
90:    communeId: sanitizeString(access.communeId, 128),
91:    communeName: sanitizeString(access.communeName, 200),
92:    platform: sanitizeString(platform, 40) || 'web',
104:  const communeId = sanitizeString(poll?.communeId, 128);
105:  const communeName = sanitizeString(poll?.communeName, 200);
106:  if (!communeId && !communeName) return [];
109:  const snapshot = communeId
110:    ? await collection.where('communeId', '==', communeId).limit(500).get()
111:    : await collection.where('communeName', '==', communeName).limit(500).get();
144:  platform = 'web',
160:    platform: sanitizeString(platform, 40) || 'web',
173:  const communeName = sanitizeString(ticket?.communeName, 200) || 'une commune';
181:      body: `${communeName} : ${subject}`,
246:export const notifyCommunePollPublished = async ({ db, poll }) => {
275:      communeId: poll.communeId,
```

### app/backend/test/citizenAccessSecurity.test.js
```text
66:test('commune admin generated controller code hashes to the login lookup value', () => {
146:      this.remoteAddress = '127.0.0.1';
```

### app/backend/test/migrateRegistrationCodesToCitizenAccessCodes.test.js
```text
16:    communeId: 'commune-1',
17:    communeName: 'Fort-de-France',
38:      data: () => ({ code: 'AB12CD34', status: 'validated', communeId: 'commune-1', communeName: 'Fort-de-France' }),
```

### app/backend/test/notificationService.test.js
```text
54:    communeId: 'commune-1',
```

### app/backend/test/retireLegacyPollVotes.test.js
```text
38:        communeId: 'commune-1',
```

### app/backend/test/support.test.js
```text
16:const adminA = { uid: 'admin:a', role: 'commune_admin', admin: true, communeId: '97101' };
17:const adminB = { uid: 'admin:b', role: 'commune_admin', admin: true, communeId: '97102' };
25:      communeId: '97101',
46:test('canAccessTicket lets the super admin reach every commune ticket', () => {
47:  assert.equal(support.canAccessTicket(superAdmin, { communeId: '97101' }), true);
48:  assert.equal(support.canAccessTicket(superAdmin, { communeId: '97102' }), true);
51:test('canAccessTicket restricts a commune admin to their own commune', () => {
52:  assert.equal(support.canAccessTicket(adminA, { communeId: '97101' }), true);
53:  assert.equal(support.canAccessTicket(adminA, { communeId: '97102' }), false);
54:  assert.equal(support.canAccessTicket(adminB, { communeId: '97102' }), true);
58:  assert.equal(support.canAccessTicket(controller, { communeId: '97101' }), false);
80:    communeName: 'Les Abymes',
97:    communeName: 'Le Gosier',
```

### app/backend/test/voteAccess.test.js
```text
16:const clone = (value) => JSON.parse(JSON.stringify(value));
22:    this._data = data === undefined ? undefined : clone(data);
26:    return clone(this._data || {});
49:    this.writes.push({ ref, data: clone(data), merge: options.merge === true });
55:    this.store = clone(seed);
97:      communeId: 'commune-1',
112:  communeId: 'commune-1',
151:    communeId: 'commune-1',
156:  assert.deepEqual(Object.keys(payload).sort(), ['communeId', 'exp', 'participationHash', 'pollId']);
158:  assert.equal(payload.communeId, 'commune-1');
169:    communeId: 'commune-1',
176:test('optionBelongsToPoll validates option ownership', () => {
178:  assert.equal(voteAccess.optionBelongsToPoll(poll, 'opt-2'), true);
179:  assert.equal(voteAccess.optionBelongsToPoll(poll, 'opt-3'), false);
186:    communeId: 'commune-1',
191:    communeId: 'commune-1',
202:  assert.deepEqual(Object.keys(ballot).sort(), ['castAt', 'communeId', 'optionId', 'pollId']);
240:  assert.deepEqual(Object.keys(ballotDocs[0]).sort(), ['castAt', 'communeId', 'optionId', 'pollId']);
```

## 4. Points à vérifier avant remplacement
