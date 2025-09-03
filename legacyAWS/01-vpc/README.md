# AWS VPC Infrastructure

Ce dossier contient la configuration Terraform pour créer l'infrastructure réseau de base sur AWS.

## 🏗️ Ressources créées

### VPC (Virtual Private Cloud)
- **Ressource** : `aws_vpc.main`
- **CIDR** : `10.0.0.0/16`
- **Fonction** : Crée un réseau privé isolé pour toutes les ressources de l'application
- **Configuration** : DNS activé pour la résolution de noms

### Internet Gateway
- **Ressource** : `aws_internet_gateway.main`
- **Fonction** : Permet aux ressources du VPC d'accéder à Internet
- **Attachement** : Connecté au VPC principal

### Subnets
#### Subnet Public
- **Ressource** : `aws_subnet.public_a`
- **AZ** : `eu-west-3a`
- **CIDR** : `10.0.1.0/24`
- **Fonction** : Héberge les ressources qui doivent être accessibles depuis Internet
- **Configuration** : IP publique automatique activée

#### Subnets Privés
- **Ressource** : `aws_subnet.private_a` (AZ: `eu-west-3a`, CIDR: `10.0.10.0/24`)
- **Ressource** : `aws_subnet.private_b` (AZ: `eu-west-3b`, CIDR: `10.0.11.0/24`)
- **Fonction** : Hébergent les ressources qui ne doivent pas être accessibles directement depuis Internet
- **Sécurité** : Accès Internet via NAT Gateway uniquement

### NAT Gateway
- **Ressource** : `aws_nat_gateway.main`
- **Fonction** : Permet aux ressources des subnets privés d'accéder à Internet (pour les mises à jour, téléchargements, etc.)
- **Emplacement** : Subnet public `eu-west-3a`
- **Coût** : ~$45/mois + coût des données

### Route Tables
#### Route Table Publique
- **Ressource** : `aws_route_table.public`
- **Fonction** : Route le trafic Internet (0.0.0.0/0) vers l'Internet Gateway
- **Association** : Subnet public

#### Route Table Privée
- **Ressource** : `aws_route_table.private`
- **Fonction** : Route le trafic Internet vers le NAT Gateway
- **Association** : Subnets privés

## 🔄 Fonctionnement des ressources entre elles

### Flux de trafic réseau

#### 1. **Trafic entrant depuis Internet**
```
Internet → Internet Gateway → Route Table Publique → Subnet Public
```

**Détail du processus :**
- L'**Internet Gateway** est attaché au VPC et agit comme point d'entrée
- La **Route Table Publique** contient la route `0.0.0.0/0 → Internet Gateway`
- Le **Subnet Public** reçoit le trafic et peut héberger des ressources (Load Balancers, Bastion hosts)

#### 2. **Trafic sortant vers Internet depuis les subnets privés**
```
Subnets Privés → Route Table Privée → NAT Gateway → Subnet Public → Internet Gateway → Internet
```

**Détail du processus :**
- Les **Subnets Privés** n'ont pas de route directe vers Internet
- La **Route Table Privée** route `0.0.0.0/0 → NAT Gateway`
- Le **NAT Gateway** (dans le subnet public) fait la traduction d'adresse
- Le trafic sort via l'**Internet Gateway**

#### 3. **Communication interne entre subnets**
```
Subnet Privé A ↔ Subnet Privé B (via VPC interne)
```

**Détail du processus :**
- Tous les subnets du même VPC peuvent communiquer directement
- Pas besoin de route explicite pour la communication interne
- Le VPC gère automatiquement le routage interne

### Dépendances et ordre de création

#### **Ordre de création Terraform :**
1. **VPC** : Créé en premier car c'est le conteneur principal
2. **Internet Gateway** : Attaché au VPC
3. **Subnets** : Créés dans le VPC avec références aux AZ
4. **EIP pour NAT** : Allocation d'IP publique
5. **NAT Gateway** : Utilise l'EIP et est placé dans le subnet public
6. **Route Tables** : Configurées avec les routes appropriées
7. **Associations** : Subnets associés aux route tables

#### **Dépendances critiques :**
- **NAT Gateway** → **Internet Gateway** : Le NAT Gateway doit être dans un subnet avec accès Internet
- **Route Tables** → **NAT Gateway** : Les routes privées pointent vers le NAT Gateway
- **Subnets** → **VPC** : Tous les subnets sont créés dans le VPC

### Gestion des adresses IP

#### **Plage d'adresses :**
- **VPC** : `10.0.0.0/16` (65,536 adresses)
- **Subnet Public** : `10.0.1.0/24` (256 adresses, 251 utilisables)
- **Subnet Privé A** : `10.0.10.0/24` (256 adresses, 251 utilisables)
- **Subnet Privé B** : `10.0.11.0/24` (256 adresses, 251 utilisables)

#### **Attribution automatique d'IP :**
- **Subnet Public** : `map_public_ip_on_launch = true` → IP publique automatique
- **Subnets Privés** : Pas d'IP publique automatique → Sécurité renforcée

### Haute disponibilité et résilience

#### **Distribution sur 2 AZ :**
- **eu-west-3a** : Subnet public + Subnet privé A
- **eu-west-3b** : Subnet privé B uniquement

#### **Avantages :**
- **Résilience** : Si une AZ tombe, l'autre continue de fonctionner
- **Performance** : Répartition de la charge sur plusieurs AZ
- **Conformité** : Certains standards exigent plusieurs AZ

#### **Limitations actuelles :**
- **NAT Gateway** : Seulement dans eu-west-3a (point de défaillance unique)
- **Internet Gateway** : Régional, pas d'impact sur la disponibilité

## 🚀 Déploiement

```bash
# Initialiser Terraform
terraform init

# Voir le plan de déploiement
terraform plan -var-file="secrets.tfvars"

# Déployer l'infrastructure
terraform apply -var-file="secrets.tfvars"

# Détruire l'infrastructure
terraform destroy -var-file="secrets.tfvars"
```

## 📋 Variables requises

Créez un fichier `secrets.tfvars` avec :
```hcl
aws_access_key = "VOTRE_ACCESS_KEY"
aws_secret_key = "VOTRE_SECRET_KEY"
aws_region     = "eu-west-3"  # Optionnel, défaut: eu-west-3
```

## 🔒 Sécurité

- **Subnets privés** : Aucun accès direct depuis Internet
- **NAT Gateway** : Trafic sortant uniquement, pas d'accès entrant
- **Isolation** : Chaque AZ a ses propres subnets pour la haute disponibilité

## 💰 Coûts estimés

- **NAT Gateway** : ~$45/mois
- **EIP** : ~$3.65/mois
- **VPC/Subnets** : Gratuits
- **Data transfer** : Selon utilisation

## 📊 Architecture

```
Internet
    ↓
Internet Gateway
    ↓
Subnet Public (eu-west-3a)
    ↓
NAT Gateway
    ↓
Subnets Privés (eu-west-3a, eu-west-3b)
```

## 🔍 Monitoring et surveillance

### **Métriques CloudWatch disponibles :**
- **NAT Gateway** : Bytes in/out, packets in/out, errors
- **VPC** : Bytes in/out, packets in/out
- **Subnets** : Utilisation des adresses IP

### **Logs et événements :**
- **VPC Flow Logs** : Trafic réseau détaillé (optionnel)
- **CloudTrail** : Actions API sur les ressources VPC
- **CloudWatch Events** : Notifications sur les changements

## 🚨 Points d'attention

### **Limitations actuelles :**
1. **NAT Gateway unique** : Point de défaillance potentiel
2. **Subnet public unique** : Toutes les ressources publiques dans une AZ
3. **Route tables statiques** : Pas de routage dynamique

### **Améliorations possibles :**
1. **NAT Gateway par AZ** : Pour la haute disponibilité (coût supplémentaire)
2. **Subnets publics multiples** : Distribution sur plusieurs AZ
3. **VPC Flow Logs** : Pour le monitoring avancé du trafic
4. **Network ACLs** : Contrôle d'accès supplémentaire au niveau subnet
