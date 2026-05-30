# Modele de menace anonymat

Objectif: pour une consultation donnee, la base de donnees doit permettre de
savoir qu'un droit de vote a ete consomme et combien de voix chaque option a
recues, sans conserver de document durable reliant un code citoyen, une
empreinte citoyenne, un controleur ou un `accessCodeId` a l'option choisie.

## Actifs a proteger

- Code citoyen en clair, affiche une seule fois au controleur.
- HMAC de code citoyen et empreinte citoyenne.
- Droit de vote consomme pour une consultation.
- Option choisie par le citoyen.
- Identite operationnelle du controleur et de la commune.
- Logs applicatifs, journaux HTTP et exports Firestore.

## Adversaires consideres

- Client web public non authentifie.
- Utilisateur authentifie avec role limite.
- Operateur interne ayant acces a Firestore, aux logs ou aux sauvegardes.
- Attaquant capable de rejouer un jeton de vote expire ou deja consomme.

## Garanties attendues

- Les clients publics ne lisent ni n'ecrivent les collections sensibles.
- Les codes citoyens ne sont jamais stockes en clair.
- Les empreintes citoyennes et les codes sont separes par des HMAC distincts.
- Le jeton de vote est court, limite a une consultation et ne contient pas
  `accessCodeId` ni empreinte citoyenne.
- La consommation du droit de vote est stockee dans `poll_participations`, sans
  option choisie.
- Le bulletin est stocke dans `poll_ballots`, sans code, sans `accessCodeId`,
  sans empreinte citoyenne et sans `participationHash`.
- Les resultats publics viennent des agregats `polls.options[].votes`, pas des
  collections de bulletins.
- Les logs redigent les champs permettant de reconstruire le lien droit/choix.

## Limites connues

- Le backend voit encore la validation du droit de vote et la soumission du
  bulletin dans le meme systeme operationnel.
- Les sauvegardes et exports doivent respecter la meme politique de retention
  que Firestore production.
- Les anciennes donnees `poll_votes` restent pseudonymisees, pas pleinement
  anonymes, tant qu'elles n'ont pas ete retirees ou archivees en agregat seul.
- Un niveau cryptographique superieur exige un protocole de jeton aveugle ou de
  signature aveugle revu separement.

## Verification production

- Backend tests: cas vote unique, double vote, concurrence et absence de lien
  durable entre participation et bulletin.
- Firestore rules tests: collections sensibles fermees, resultats publics lisibles
  via `polls` uniquement.
- Audit logs: pas de `accessCode`, `accessCodeId`, `citizenFingerprintHash`,
  `participationHash`, `accessToken`, `Authorization` ou `optionId` en clair.
- Migration legacy: `poll_votes` retiree apres sauvegarde controlee, avec archive
  agregee uniquement.