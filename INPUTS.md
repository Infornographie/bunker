# INPUTS — Projet Bunker
 
Source unique des bindings clavier/souris du jeu. À mettre à jour à chaque ajout ou modification de binding — un binding qui apparaît en code sans passer par ici, c'est un piège pour la prochaine session.
 
## Déplacement / caméra
 
- **ZQSD** — locomotion (avant/gauche/arrière/droite)
- **Shift (maintenu)** — course (sprint), bloquée quand les mains portent un objet lourd
- **Espace** — saut, bloqué quand les mains portent un objet lourd
- **Souris** — orientation caméra première personne
## Outil en main
 
- **Clic gauche** — utiliser l'outil équipé (swing hache, etc.)
## Interaction / portage
 
- **E** — interagir avec la cible visée : ramasser, déposer, activer
## Équipement (hotbar)
 
- **1-5** — sélection directe du slot (Physical Keycode)
- **Molette haut/bas** — cycler les slots (gauche/droite)
- **G** — déposer au sol l'item du slot actif
- **A** — sac à dos : dos ↔ main, ou ramasser un sac au sol
- **E** (sur sac posé) — ouvrir l'interface du sac
- **Échap / E** (UI ouverte) — fermer
## Mode construction
 
- **B** — ouvrir / fermer le mode construction
- **Molette (haut/bas)** — rotation du blueprint
- **Shift (maintenu)** — free placing (désactive le snap)
## Debug
 
- **F7** — bascule caméra joueur ↔ freecam noclip
## Collisions de touches assumées
 
- **Shift** : sprint en locomotion, free placing en mode construction. Contextes exclusifs (on ne pose pas un blueprint en courant), pas de conflit réel.
