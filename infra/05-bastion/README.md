# Bastion Host Infrastructure

Cette configuration Terraform crée une instance EC2 bastion qui peut être utilisée pour accéder de manière sécurisée aux ressources dans votre VPC.

## Fonctionnalités

- **Accès sécurisé** : Accès SSH avec votre paire de clés
- **Sous-réseau public** : Déployé dans un sous-réseau public avec IP élastique
- **Groupe de sécurité** : Configuré avec les règles d'entrée/sortie appropriées
- **Rôle IAM** : Rôle IAM de base pour l'accès AWS CLI
- **Stockage chiffré** : Volume racine chiffré
- **Mises à jour automatiques** : Script user data installe des outils utiles et met à jour le système

## Prérequis

1. AWS CLI configuré avec les bonnes credentials
2. Un VPC existant avec des sous-réseaux publics
3. Une paire de clés AWS pour l'accès SSH
4. Terraform installé

## Comprendre les paires de clés SSH (key_name)

### Qu'est-ce que `key_name` ?

`key_name` fait référence à une **paire de clés SSH** (SSH key pair) dans AWS. C'est un mécanisme de sécurité qui permet de vous connecter de manière sécurisée à votre instance EC2.

### Comment ça fonctionne ?

1. **Vous créez une paire de clés** dans AWS (ou vous en avez déjà une)
2. **AWS stocke la clé publique** sur l'instance EC2
3. **Vous gardez la clé privée** sur votre machine locale
4. **Vous utilisez la clé privée** pour vous connecter en SSH

### Comment créer une paire de clés ?

#### Option 1: Via AWS Console
1. Allez dans EC2 → Key Pairs
2. Cliquez sur "Create key pair"
3. Donnez un nom (ex: "mon-bastion-key")
4. Téléchargez le fichier `.pem`

#### Option 2: Via AWS CLI
```bash
aws ec2 create-key-pair --key-name mon-bastion-key --query 'KeyMaterial' --output text > mon-bastion-key.pem
chmod 400 mon-bastion-key.pem
```

### Vérifier vos paires de clés existantes

```bash
# Lister vos paires de clés existantes
aws ec2 describe-key-pairs --query 'KeyPairs[*].KeyName' --output table
```

## Utilisation

1. **Créer une paire de clés** (si vous n'en avez pas) :
   ```bash
   # Créer la paire de clés
   aws ec2 create-key-pair --key-name navigator-bastion-key --query 'KeyMaterial' --output text > navigator-bastion-key.pem
   
   # Sécuriser le fichier
   chmod 400 navigator-bastion-key.pem
   
   # Déplacer vers le dossier SSH
   mv navigator-bastion-key.pem ~/.ssh/
   ```

2. **Copier le fichier secrets** :
   ```bash
   cp secrets.tfvars.example secrets.tfvars
   ```

3. **Éditer `secrets.tfvars`** avec vos vraies valeurs :
   ```hcl
   key_name = "navigator-bastion-key"  # Le nom exact de votre paire de clés
   ```

4. **Initialiser Terraform** :
   ```bash
   terraform init
   ```

5. **Planifier le déploiement** :
   ```bash
   terraform plan -var-file="secrets.tfvars"
   ```

6. **Appliquer la configuration** :
   ```bash
   terraform apply -var-file="secrets.tfvars"
   ```

7. **Se connecter au bastion** :
   ```bash
   # Récupérer l'IP publique depuis les outputs
   terraform output bastion_public_ip
   
   # Se connecter
   ssh -i ~/.ssh/navigator-bastion-key.pem ec2-user@<IP-PUBLIQUE>
   ```

## Options de configuration

### Variables requises
- `key_name`: Nom de votre paire de clés AWS pour l'accès SSH

### Variables optionnelles
- `project_name`: Nom du projet (défaut: "navigator")
- `environment`: Nom de l'environnement (défaut: "dev")
- `vpc_name`: Nom du VPC où déployer (défaut: "navigator-vpc")
- `instance_type`: Type d'instance EC2 (défaut: "t3.micro")
- `volume_size`: Taille du volume racine en GB (défaut: 20)
- `allowed_cidr_blocks`: Blocs CIDR autorisés pour SSH (défaut: ["0.0.0.0/0"])

## Considérations de sécurité

1. **Restreindre l'accès SSH** : Considérez définir `allowed_cidr_blocks` à vos plages IP spécifiques au lieu d'autoriser l'accès depuis n'importe où
2. **Gestion des clés** : Assurez-vous que votre paire de clés SSH est correctement sécurisée
3. **Mises à jour régulières** : L'instance se mettra à jour automatiquement au premier démarrage, mais considérez configurer des mises à jour automatisées
4. **Monitoring** : Activez le monitoring CloudWatch pour l'instance

## Outputs

Après le déploiement, vous obtiendrez :
- `bastion_instance_id`: ID de l'instance EC2
- `bastion_public_ip`: Adresse IP publique
- `bastion_private_ip`: Adresse IP privée
- `bastion_public_dns`: Nom DNS public
- `bastion_security_group_id`: ID du groupe de sécurité
- `ssh_connection_command`: Commande SSH prête à utiliser

## Nettoyage

Pour détruire l'infrastructure :
```bash
terraform destroy -var-file="secrets.tfvars"
```

## Dépannage

1. **VPC introuvable** : Assurez-vous que votre VPC existe et a le bon tag de nom
2. **Pas de sous-réseaux publics** : Vérifiez que votre VPC a des sous-réseaux publics avec les bons tags
3. **Problèmes de paire de clés** : Assurez-vous que la paire de clés existe dans la même région
4. **Connexion SSH** : Vérifiez les règles du groupe de sécurité et les permissions de la paire de clés

## Exemple complet

Si vous avez déjà une paire de clés existante, utilisez simplement son nom :

```hcl
# secrets.tfvars
key_name = "ma-cle-existante"  # Remplacez par le nom de votre clé existante
```

## Résumé simple

1. **`key_name`** = le nom de votre paire de clés SSH dans AWS
2. **Vous devez avoir cette paire de clés** avant de créer l'instance
3. **Le fichier `.pem`** (clé privée) doit être sur votre machine
4. **AWS met automatiquement la clé publique** sur l'instance
5. **Vous vous connectez avec la clé privée**