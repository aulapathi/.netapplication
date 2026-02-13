
**complete end-to-end documentation** 

> .NET 8 → Docker → GitHub Actions → EC2 (Amazon Linux 2023)
> No ECR. No GHCR. No container registry.

You can copy this into a `README.md` if you want.

---

# 🚀 .NET 8 CI/CD Deployment to EC2 (Without Registry)

---

# 📌 Architecture Overview

```
Developer → Git Push → GitHub Actions
                    ↓
              Docker Image Build
                    ↓
              Save image as TAR
                    ↓
              SCP to EC2
                    ↓
              docker load
                    ↓
              docker compose up
                    ↓
              Application Running
```

---

# 1️⃣ Create .NET 8 Web API

```bash
dotnet new webapi -n dnmgithbuactionsdemo
cd dnmgithbuactionsdemo
```

Run locally:

```bash
dotnet run
```

---

# 2️⃣ Project Structure

```
dnmgithbuactionsdemo/
│
├── Pages/
├── Properties/
├── wwwroot/
├── Program.cs
├── appsettings.json
├── dnmgithbuactionsdemo.csproj
├── Dockerfile
├── docker-compose.yml
└── .github/workflows/deploy.yml
```

---

# 3️⃣ Dockerfile

Create `Dockerfile` in root:

```dockerfile
# Build Stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore
RUN dotnet publish -c Release -o /app

# Runtime Stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .

# IMPORTANT: Bind to correct port inside container
ENV ASPNETCORE_URLS=http://0.0.0.0:8080

EXPOSE 8080
ENTRYPOINT ["dotnet", "dnmgithbuactionsdemo.dll"]
```

---

# 4️⃣ docker-compose.yml

```yaml
version: "3.9"

services:
  app:
    image: dnmgithbuactionsdemo:latest
    container_name: dnmdemo
    restart: always
    ports:
      - "80:8080"
```

---

# 5️⃣ Launch EC2 Instance

Create EC2 with:

* OS: **Amazon Linux 2023**
* Open ports:

  * 22 (SSH)
  * 80 (HTTP)

---

# 6️⃣ Install Docker on EC2

SSH into EC2:

```bash
ssh ec2-user@YOUR_PUBLIC_IP
```

Install Docker:

```bash
sudo dnf update -y
sudo dnf install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
```

Logout and login again.

---

# 7️⃣ Install Docker Compose v2 (Manual Method)

```bash
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
```

Verify:

```bash
docker compose version
```

---

# 8️⃣ GitHub Secrets

In your repository on **GitHub**:

Settings → Secrets → Actions

Add:

```
EC2_HOST
EC2_USER = ec2-user
EC2_SSH_KEY = (private key content)
```

---

# 9️⃣ GitHub Actions Workflow

Create:

```
.github/workflows/deploy.yml
```

### deploy.yml

```yaml
name: Build and Deploy to EC2

on:
  push:
    branches:
      - main

jobs:
  build-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Build Docker image
        run: docker build -t dnmgithbuactionsdemo:latest .

      - name: Save Docker image
        run: docker save dnmgithbuactionsdemo:latest -o app.tar

      - name: Fix permissions
        run: chmod 644 app.tar

      - name: Create app directory on EC2
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.EC2_HOST }}
          username: ${{ secrets.EC2_USER }}
          key: ${{ secrets.EC2_SSH_KEY }}
          script: mkdir -p /home/ec2-user/app

      - name: Copy files to EC2
        uses: appleboy/scp-action@v0.1.7
        with:
          host: ${{ secrets.EC2_HOST }}
          username: ${{ secrets.EC2_USER }}
          key: ${{ secrets.EC2_SSH_KEY }}
          source: "app.tar,docker-compose.yml"
          target: "/home/ec2-user/app"
          overwrite: true

      - name: Deploy on EC2
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.EC2_HOST }}
          username: ${{ secrets.EC2_USER }}
          key: ${{ secrets.EC2_SSH_KEY }}
          script: |
            cd /home/ec2-user/app
            docker load -i app.tar
            docker compose down || true
            docker compose up -d
            docker image prune -f
```

---

# 🔟 Deployment Process

When you push to `main`:

1. GitHub builds Docker image
2. Saves it as `app.tar`
3. Transfers to EC2 via SCP
4. EC2 loads image
5. Docker Compose starts container
6. App becomes available on port 80

---

# 1️⃣1️⃣ Testing

Open browser:

```
http://EC2_PUBLIC_IP
```

You should see your API response.

---

# 1️⃣2️⃣ Useful Debug Commands

On EC2:

### Check images

```bash
docker images
```

### Check running containers

```bash
docker ps
```

### Check all containers

```bash
docker ps -a
```

### View logs

```bash
docker logs dnmdemo
```

### Restart

```bash
docker compose restart
```

---

# 🔒 Security Notes (Production Recommended)

* Use a reverse proxy (Nginx)
* Add HTTPS with Let's Encrypt
* Restrict SSH to your IP
* Use non-root containers
* Enable firewall (optional)

---

# 🎯 What You Achieved

✅ CI/CD without any container registry
✅ Fully automated deployment
✅ Dockerized .NET 8 app
✅ Production-capable EC2 setup
✅ Self-contained deployment pipeline

---

If you want, I can now give you:

* 📄 A professional README.md version
* 🔐 HTTPS + Nginx setup
* 🔄 Zero downtime deployment
* 🌍 Staging + production environments
* 📊 Monitoring & logging setup

Tell me what you want next.
