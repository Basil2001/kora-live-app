# Kora Backend & Frontend — Production Deployment Guide

This document describes how to deploy the Kora Backend on a production VPS server and configure the GitHub Actions CI/CD pipelines.

---

## 🖥️ Server Setup (VPS)

### 1. Install Docker & Docker Compose
Run the following commands on your Ubuntu VPS (or similar Linux distro) to install Docker:

```bash
# Update package list and install prerequisites
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add repository to Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine and Compose
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Verify installation:
```bash
docker --version
docker compose version
```

### 2. Create the Application Directory & Clone
Create the folder where your application will reside and set permissions:

```bash
sudo mkdir -p /var/www/kora
sudo chown -R $USER:$USER /var/www/kora
cd /var/www/kora

# Clone the repository
git clone <YOUR_REPOSITORY_GIT_URL> .
```

### 3. Deploy the Production Environment file (.env)
You do not need to create `.env` manually if you use the CI/CD pipeline, but if you want to run it manually:
1. Copy `backend/.env.production` to `backend/.env`.
2. Populate the required values, including:
   - `APP_KEY` (Generate locally using `php artisan key:generate` and paste it).
   - `DB_PASSWORD` (Use a strong password).
   - `FOOTBALL_API_KEY` (Your API-Football subscription key).
   - Firebase configurations (`FIREBASE_CREDENTIALS`, `FIREBASE_PROJECT_ID`).

### 4. Run the Docker Stack Manually for the First Time
```bash
cd /var/www/kora/backend
docker compose up -d --build
```
This starts:
- **MySQL Container** (`kora-mysql` on port 3306)
- **Redis Container** (`kora-redis` on port 6379)
- **Laravel App Container** (`kora-app` on port 9000 with supervisord running php-fpm + queue workers)
- **Nginx Container** (`kora-nginx` on port 8000 redirecting to `kora-app`)

---

## 🔒 Domain, Nginx Host Proxy, & SSL (HTTPS)

To expose the API to the internet on `api.kora.app` with SSL, install Nginx on the host VPS system to act as a reverse proxy:

```bash
sudo apt-get install -y nginx certbot python3-certbot-nginx
```

Create a virtual host configuration at `/etc/nginx/sites-available/kora-api`:
```nginx
server {
    listen 80;
    server_name api.kora.app; # Replace with your actual sub-domain

    location / {
        proxy_pass http://127.0.0.1:8000; # Forward requests to Laravel docker container
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the site and restart Nginx:
```bash
sudo ln -s /etc/nginx/sites-available/kora-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

Obtain the SSL Certificate via Certbot:
```bash
sudo certbot --nginx -d api.kora.app
```
Follow the prompts, and choose to redirect all HTTP traffic to HTTPS.

---

## ⚙️ Cron Scheduler Job

Laravel needs a system cron job to run every minute to sync match standings, live scores, and fire notifications:

```bash
# Open the crontab editor on the VPS host
crontab -e
```

Add the following line to the bottom:
```cron
* * * * * cd /var/www/kora/backend && docker compose exec -T app php artisan schedule:run >> /dev/null 2>&1
```
This triggers Laravel's internal task scheduling mechanism (`App\Console\Kernel`) inside the docker container once per minute.

---

## 📦 Setting Up GitHub Actions CI/CD Secrets

To enable automated testing and deployment, go to your repository on GitHub -> **Settings** -> **Secrets and variables** -> **Actions** and add these Secrets:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `SSH_HOST` | The public IP address of your VPS server | `123.45.67.89` |
| `SSH_USER` | The user with SSH access (e.g. `root` or `ubuntu`) | `ubuntu` |
| `SSH_PRIVATE_KEY` | The private SSH key matching the public key added to `~/.ssh/authorized_keys` on the VPS | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `ENV_PRODUCTION_FILE` | The complete, exact content of your production `.env` file | *Check backend/.env.production structure* |

Once these secrets are set:
* Every commit/PR to `main` runs backend tests, frontend analysis, and frontend tests.
* On merge to `main`, the code is automatically deployed to the server, and the production Android release APK is built and uploaded as a GitHub Actions build artifact.
