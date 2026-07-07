# Deploy

Como implantar o NNAdsorption App num servidor (ex.: servidor da UTFPR).
O guia assume um servidor **Linux (Ubuntu/Debian)** com acesso SSH; os
comandos mudam pouco em outras distros.

## Visão geral

```
Internet ──> Nginx (porta 80/443)
               ├── /            → arquivos estáticos do Flutter (build/web)
               └── /api/...     → proxy pra uvicorn (porta 8000)
```

Servir o frontend e a API sob o **mesmo domínio** simplifica o CORS e o
HTTPS.

## 1. Preparar o servidor

```bash
sudo apt update
sudo apt install -y python3.11 python3.11-venv nginx git
```

Clone os dois repositórios lado a lado:

```bash
cd /opt
sudo git clone <url-do-NNAdsorption_App> NNAdsorption_App
sudo git clone <url-da-NNAdsorption_Library> NNAdsorption_Library
```

## 2. Backend

```bash
cd /opt/NNAdsorption_App/backend
python3.11 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install -e /opt/NNAdsorption_Library
```

Crie o `.env` de produção:

```bash
cp .env.example .env
nano .env
```

```
JWT_SECRET=<string longa e aleatória — use: openssl rand -hex 32>
JWT_EXPIRES_DAYS=7
DATABASE_URL=sqlite:////opt/NNAdsorption_App/backend/app.db
ALLOWED_ORIGINS=https://nnadsorption.utfpr.edu.br
```

> ⚠️ `ALLOWED_ORIGINS` deve conter **só** o domínio real do frontend.
> Nunca `*` e nunca deixar os localhost de desenvolvimento em produção.

Crie um serviço systemd pra API subir sozinha com o servidor
(`/etc/systemd/system/nnadsorption.service`):

```ini
[Unit]
Description=NNAdsorption API
After=network.target

[Service]
User=www-data
WorkingDirectory=/opt/NNAdsorption_App/backend
ExecStart=/opt/NNAdsorption_App/backend/.venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now nnadsorption
sudo systemctl status nnadsorption   # deve mostrar "active (running)"
```

## 3. Frontend

No seu computador (ou no servidor, se tiver Flutter instalado):

```bash
cd frontend
```

Antes de compilar, aponte o app pro backend de produção em
`lib/config.dart`:

```dart
const String kBackendUrl = 'https://nnadsorption.utfpr.edu.br/api';
```

Compile e envie pro servidor:

```bash
flutter build web
scp -r build/web/* usuario@servidor:/var/www/nnadsorption/
```

## 4. Nginx

`/etc/nginx/sites-available/nnadsorption`:

```nginx
server {
    listen 80;
    server_name nnadsorption.utfpr.edu.br;

    # Frontend estático
    root /var/www/nnadsorption;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # API — repassa pro uvicorn
    location /api/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/nnadsorption /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

> O header `X-Real-IP` é importante: sem ele o rate limit veria todos os
> usuários com o IP do próprio Nginx.

## 5. HTTPS (Let's Encrypt)

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d nnadsorption.utfpr.edu.br
```

O certbot ajusta o Nginx e renova o certificado automaticamente.

## 6. Checklist final

- [ ] `curl https://nnadsorption.utfpr.edu.br/api/health` → `{"ok": true}`
- [ ] Site abre e o cadastro/login funciona
- [ ] Predição roda (a primeira demora ~30s — o TensorFlow carrega o modelo)
- [ ] `JWT_SECRET` trocado do valor de exemplo
- [ ] `ALLOWED_ORIGINS` só com o domínio real
- [ ] Backup periódico do `app.db` (é um arquivo único — basta copiá-lo)

## Atualizando o app

```bash
# Backend
cd /opt/NNAdsorption_App && sudo git pull
sudo systemctl restart nnadsorption

# Frontend: recompilar localmente e reenviar o build/web
```
