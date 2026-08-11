\# Projet : Jeu RNG Pet Collector (Roblox)



\## Contexte technique

\- Projet Roblox synchronisé via Rojo (rojo serve). Ne jamais éditer de fichier .rbxl directement.

\- Scripts dans src/, mapping fichiers → arborescence Roblox dans default.project.json.

\- Langage : Luau (typage strict --!strict quand possible).

\- Structure : src/server (logique), src/client (UI, effets), src/shared (Config, types, utilitaires).



\## Règles non négociables

\- SERVEUR AUTORITAIRE : rolls, gains, XP, combat, fusion — tout se calcule côté serveur.

&#x20; Le client envoie des requêtes via RemoteEvents/RemoteFunctions, le serveur valide TOUT.

\- Persistance : ProfileStore (loleris). Jamais de DataStore brut.

\- Toutes les données de jeu (pets, raretés, zones, monstres, arbres) dans src/shared/Config/

&#x20; sous forme de tables Luau. Ajouter du contenu = ajouter une entrée, zéro code.

\- Une feature = un module. Pas de script monolithique.



\## Game design (résumé)

\- Le joueur roll des pets (œufs par zone), les équipe (3 max au départ), ils attaquent

&#x20; les monstres → XP (niveaux) + golds.

\- Raretés : Common → Secret (1/50M), variante Shiny 1/40 (stats x2). Voir game\_design\_rng.xlsx.

\- Fusion : 5 pets identiques → 1 étoile (x1.5 stats), refusionnable jusqu'à 5★.

\- Arbre n°1 payé en golds (reset au prestige), arbre n°2 payé en points de prestige (permanent).

\- Prestige au niveau 50 (+25 par prestige) : perd golds/niveaux/arbre 1, garde pets/index/arbre 2.

\- Plus tard : zones (3 en V1), index/collection, guilds + leaderboards, quêtes journalières.



\## UI — règles non négociables

\- Toujours en Scale (UDim2.new(scale, 0, scale, 0)) pour les conteneurs principaux. Jamais de tailles fixes en pixels pour les panels, boutons ou fenêtres.

\- Penser mobile-first : la majorité des joueurs Roblox sont sur téléphone. Tester mentalement sur 667×375 (iPhone paysage).

\- UISizeConstraint (MaxSize) sur chaque conteneur Scale pour éviter un scaling excessif sur desktop.

\- TextScaled = true sur tous les TextLabels. Jamais de TextSize fixe dans les conteneurs principaux.

\- UIScale piloté par résolution uniquement pour les éléments internes (icônes, padding, lignes de liste) quand la taille du conteneur peut varier — le poser dans un sous-Frame, jamais directement sur le ScreenGui si les tailles sont déjà en Scale (double-scaling).

\- AnchorPoint obligatoire pour le centrage et l'alignement (évite les offsets en pixels pour positionner).



\## Méthode de travail

\- On avance étape par étape. Ne code QUE ce qui est demandé dans le prompt courant.

\- Après chaque étape, je teste dans Roblox Studio avant de continuer.

