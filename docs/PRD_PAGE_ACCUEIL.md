# PRD - Page d'accueil Citoyen Peyi

## 1. Contexte

Citoyen Peyi est une plateforme de participation citoyenne. La page d'accueil
est la porte d'entree principale vers les parcours citoyen, agent de
mobilisation citoyenne et administration.

Ce document definit les objectifs produit, le perimetre fonctionnel,
les exigences UX/accessibilite et les criteres de validation de la page
d'accueil.

## 2. Objectifs Produit

- Faciliter l'acces au parcours citoyen en 1 clic.
- Rendre explicite l'entree agent de mobilisation citoyenne.
- Donner un acces clair aux espaces d'administration sans surcharger la page.
- Maintenir une experience lisible et fluide sur mobile, tablette et desktop.

## 3. Utilisateurs Cibles

- Citoyen: souhaite participer rapidement a une consultation.
- Agent de mobilisation citoyenne (controleur): souhaite acceder a son accueil.
- Administrateur communal et super administrateur: accedent via l'entree
  administration.

## 4. Problemes a Resoudre

- Eviter la confusion entre parcours public et parcours internes.
- Reduire le nombre d'etapes pour commencer a participer.
- Conserver une navigation publique evidente vers avis, resultats et actualites.

## 5. Portee

### 5.1 In Scope

- Hero visuel avec identite Citoyen Peyi (fond, logo, promesse).
- Deux CTA principaux:
  - Je participe
  - Agent de mobilisation citoyenne / accueil
- Navigation publique secondaire:
  - Accueil
  - Avis
  - Resultats
  - Actualites
- Bouton Acces administration ouvrant une feuille modale avec options:
  - Commune
  - Agent de mobilisation citoyenne
  - Super administration
- Adaptation responsive mobile/tablette/desktop.
- Semantics minimales pour lecteurs d'ecran sur les actions importantes.

### 5.2 Out of Scope

- Refonte des pages cibles (QR access, login, dashboards).
- Gestion de compte utilisateur public.
- Changement du systeme de roles/authentification.

## 6. Parcours Utilisateur

### 6.1 Parcours Citoyen

1. Arrivee sur / ou /accueil.
2. Clic sur Je participe.
3. Redirection vers /participer (parcours QR/code citoyen).

### 6.2 Parcours Agent de Mobilisation Citoyenne

1. Arrivee sur la page d'accueil.
2. Clic sur Agent de mobilisation citoyenne / accueil.
3. Redirection vers /controleur-accueil.

### 6.3 Parcours Administration

1. Clic sur Acces administration.
2. Ouverture d'une feuille modale.
3. Choix d'une entree:
   - Commune -> /admin-communal
   - Agent de mobilisation citoyenne -> /controleur-accueil
   - Super administration -> /super-admin

## 7. Exigences Fonctionnelles

### 7.1 Structure Ecran

- Fond plein ecran avec image de marque.
- Couche d'assombrissement legere pour renforcer la lisibilite.
- Contenu centre dans une largeur contrainte.
- Scroll vertical autorise si hauteur ecran reduite.

### 7.2 Composants

- Logo principal visible en haut du contenu.
- Pill de message institutionnel visible sous le logo.
- Bloc CTA principaux:
  - Empilement vertical en mobile/tablette.
  - Affichage horizontal en desktop.
- Bloc navigation publique sur fond clair.
- Lien texte-bouton Acces administration en bas de l'ecran principal.

### 7.3 Comportements et Routes

- / et /accueil affichent la page d'accueil.
- Je participe ouvre /participer.
- Agent de mobilisation citoyenne / accueil ouvre /controleur-accueil.
- Nav publique:
  - Accueil -> /accueil
  - Avis -> /avis
  - Resultats -> /resultats
  - Actualites -> /actualites
- Acces administration ouvre une modale puis redirige selon le choix.

### 7.4 Fallback Visuel

- Si l'image de fond est indisponible, afficher un degrade bleu de secours.

## 8. Exigences UX/UI

- Lisibilite elevee sur fond photo (overlay sombre).
- CTA principal Je participe visuellement prioritaire.
- Design coherent avec la charte actuelle (bleu/blanc, bords arrondis).
- Cibles tactiles minimum 44px de hauteur.

## 9. Exigences Accessibilite

- Tous les CTA et boutons de navigation exposes via Semantics label.
- Contrastes conformes au minimum WCAG AA pour textes cliquables.
- Navigation clavier possible sur tous les boutons.
- Ordre de focus logique: logo -> promesse -> CTA -> nav -> administration.

## 10. Exigences Techniques

- Framework: Flutter Web.
- Arbre principal base sur Stack + SafeArea + SingleChildScrollView.
- Responsive via LayoutBuilder:
  - Mobile: largeur < 600
  - Tablette: 600 <= largeur < 1024
  - Desktop: largeur >= 1024
- Asset de fond: assets/citoyen_peyi/home_background.webp
- Asset logo: assets/citoyen_peyi/logo_citoyen_peyi_transparent.webp

## 11. Instrumentation et KPIs

### 11.1 Evenements a Instrumenter

- home_view
- home_click_participer
- home_click_controller
- home_click_nav_accueil
- home_click_nav_avis
- home_click_nav_resultats
- home_click_nav_actualites
- home_click_admin_access
- home_click_admin_choice_commune
- home_click_admin_choice_controller
- home_click_admin_choice_super

### 11.2 KPIs Cibles

- CTR Je participe >= 45% des sessions home.
- CTR Agent de mobilisation citoyenne / accueil >= 8% des sessions home.
- Taux de rebond home (aucun clic) <= 30%.
- Temps median vers premiere action <= 10 secondes.

## 12. Critieres d'Acceptation

- La route / affiche la page d'accueil sans erreur.
- La route /accueil affiche la meme page.
- Les 2 CTA principaux redirigent vers les bonnes routes.
- Les 4 boutons de navigation publique redirigent vers les bonnes routes.
- Le bouton Acces administration ouvre la modale avec 3 options.
- Chaque option de la modale redirige vers la bonne route.
- Le layout mobile/tablette/desktop suit les regles de responsive definies.
- En absence d'image de fond, le degrade de fallback est visible.
- Les labels Semantics principaux sont presents.

## 13. Plan de Test

- Test widget Flutter pour verifier:
  - Presence des CTA et labels.
  - Navigation vers /participer et /controleur-accueil.
  - Ouverture de la modale administration.
  - Presence des 3 choix administration.
- Test manuel responsive sur largeurs 375, 768, 1280.
- Test manuel accessibilite clavier (tabulation) et lecteur d'ecran.

## 14. Risques et Mitigations

- Risque: surcharge cognitive avec trop d'entrees.
  - Mitigation: garder 2 CTA principaux, releguer administration en secondaire.
- Risque: perte de lisibilite selon l'image de fond.
  - Mitigation: overlay sombre constant + fallback degrade.
- Risque: confusion entre Agent et Administration.
  - Mitigation: wording explicite et segmentation dans la modale.

## 15. Dependances

- Disponibilite des assets WebP dans le bundle web.
- Cohesion des routes dans le routeur applicatif.
- Eventuelle couche analytics pour mesurer les KPIs.

## 16. Livrables

- Page d'accueil implementee conforme a ce PRD.
- Suite minimale de tests widget associes.
- Checklist QA de validation pre-deploiement.
