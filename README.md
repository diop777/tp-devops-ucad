# TP DevOps – Automatisation
**UCAD – Département Informatique – 2025-2026**

---

## Structure du projet

```
tp_devops/
├── auto_deploy.sh              # Partie 1 – Script Bash
├── app.js                      # Application Express (API ping/pong)
├── package.json
├── Dockerfile                  # Bonus – Image Docker
├── main.tf                     # Partie 3 – Infrastructure as Code (Terraform)
├── test/
│   └── app.test.js             # Tests unitaires Jest
└── .github/
    └── workflows/
        └── ci.yml              # Partie 2 – Pipeline GitHub Actions
```

---

## Partie 1 – Script Bash (`auto_deploy.sh`)

### Comment exécuter

```bash
# Rendre le script exécutable
chmod +x auto_deploy.sh

# Lancer avec l'URL du dépôt (paramètre obligatoire)
./auto_deploy.sh https://github.com/mon-user/mon-app.git

# Avec un nom de dossier personnalisé
./auto_deploy.sh https://github.com/mon-user/mon-app.git mon_projet
```

### Ce que fait le script
1. Vérifie que `git`, `node` et `npm` sont installés.
2. Clone le dépôt ou fait un `git pull` si le dossier existe déjà.
3. Lance `npm install`.
4. Lance `npm test` – le déploiement s'arrête si les tests échouent.
5. Démarre l'application **en arrière-plan** et sauvegarde le PID dans `app.pid`.

### Arrêter l'application
```bash
kill $(cat app.pid)
```

### Consulter les logs
```bash
cat deploy_YYYYMMDD_HHMMSS.log
```

---

## Partie 2 – Pipeline GitHub Actions

### Prérequis
Configurer les secrets dans **Settings → Secrets and variables → Actions** :

| Secret            | Description                    |
|-------------------|--------------------------------|
| `DOCKER_USERNAME` | Nom d'utilisateur Docker Hub   |
| `DOCKER_PASSWORD` | Mot de passe / token Docker Hub|
| `SSH_HOST`        | IP ou domaine du serveur SSH   |
| `SSH_USER`        | Utilisateur SSH (ex: `ubuntu`) |
| `SSH_PRIVATE_KEY` | Clé privée SSH (contenu complet)|

### Déclenchement du pipeline
Le pipeline se lance automatiquement à chaque `push` ou `pull_request` sur `main`.

### Jobs du pipeline
| Job            | Condition                          | Actions                          |
|----------------|------------------------------------|----------------------------------|
| build-and-test | Toujours                           | Install → Tests → Build          |
| docker-push    | Tests OK + push sur main           | Build Docker + Push Docker Hub   |
| deploy-ssh     | Docker push OK                     | Pull image + Redémarrage serveur |

### Tester localement avant de pousser
```bash
npm install
npm test
```

---

## Partie 3 – Infrastructure as Code (Terraform)

### Prérequis
- Terraform installé : https://developer.hashicorp.com/terraform/install
- AWS CLI configuré : `aws configure`

### Déployer l'infrastructure
```bash
terraform init        # Télécharge les providers
terraform plan        # Aperçu des ressources à créer
terraform apply -auto-approve   # Crée les ressources
```

### Détruire l'infrastructure
```bash
terraform destroy     # IMPORTANT : évite les coûts inutiles
```

---

## Réponses aux questions

### Partie 1 – Questions

**Q1 : Modifier le script pour accepter l'URL en paramètre**
→ Fait. Le script utilise `$1` pour l'URL et `$2` pour le nom du dossier.
```bash
./auto_deploy.sh https://github.com/user/repo.git [nom_dossier]
```

**Q2 : Ajouter une fonction de log avec horodatage**
→ Fait. La fonction `log()` ajoute automatiquement la date et l'heure :
```
[2025-10-01 14:32:10] [INFO] Tests passés avec succès.
```

**Q3 : Lancer l'application en arrière-plan et sauvegarder le PID**
→ Fait. `npm start &` lance le processus en arrière-plan. `$!` récupère son PID
et l'écrit dans `app.pid`. On peut ensuite faire `kill $(cat app.pid)`.

---

### Partie 2 – Travail demandé

**Q3 : Déployer seulement si les tests passent**
→ Le job `docker-push` a `needs: build-and-test`. Si `npm test` échoue dans
`build-and-test`, GitHub Actions marque ce job comme failed, et tous les jobs
qui en dépendent (`docker-push`, `deploy-ssh`) sont automatiquement annulés.

**Q4 (Avancé) : Job de déploiement SSH**
→ Ajouté dans `ci.yml` sous le job `deploy-ssh`. Il utilise `appleboy/ssh-action`
pour se connecter au serveur, télécharger la nouvelle image Docker et redémarrer
le conteneur.

---

### Partie 3 – Questions de réflexion

**Avantages de l'IaC par rapport à une configuration manuelle**

L'Infrastructure as Code présente plusieurs avantages majeurs :
- **Reproductibilité** : la même configuration produit exactement le même
  environnement à chaque fois, éliminant les erreurs humaines.
- **Versioning** : les fichiers Terraform sont dans Git, on peut voir l'historique
  des changements et revenir en arrière facilement.
- **Automatisation** : l'infrastructure peut être créée et détruite en quelques
  secondes, utile pour des environnements temporaires (tests, staging).
- **Documentation vivante** : le code décrit exactement ce qui est déployé.

**Comment intégrer Terraform dans un pipeline CI/CD ?**

On peut ajouter un job Terraform dans GitHub Actions :
```yaml
- name: Terraform Apply
  run: |
    terraform init
    terraform apply -auto-approve
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```
Bonnes pratiques : exécuter `terraform plan` sur les PR pour voir les changements
avant de les approuver, et `terraform apply` uniquement sur la branche main.

**Précautions avec les fichiers `.tfstate`**

- **Ne jamais commiter `.tfstate` dans Git** : il contient des informations
  sensibles (IPs, mots de passe, clés). L'ajouter dans `.gitignore`.
- **Utiliser un backend distant** (S3 + DynamoDB pour AWS) pour partager l'état
  entre membres de l'équipe et éviter les conflits.
- **Activer le verrouillage** (`state locking`) pour empêcher deux personnes
  d'appliquer des changements simultanément.

---

## Barème récapitulatif

| Critère                                    | Points |
|--------------------------------------------|--------|
| Script bash fonctionnel et bien commenté   | 4 pts  |
| Pipeline CI/CD opérationnel                | 4 pts  |
| Bonnes pratiques (erreurs, logs, sécurité) | 3 pts  |
| Rapport / réponses aux questions           | 3 pts  |
| Bonus (Docker, déploiement SSH, Terraform) | 2 pts  |
| **Total**                                  | **16 pts** |
