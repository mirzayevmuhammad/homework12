# Nginx Docker Compose Topshiriqlari

## Topshiriq 1: Nginx Web Server ishga tushirish

**Maqsad**: Nginx nima ekanligini tushunish va uni Docker orqali ishlatishni o'rganish

**Bajariladigan ishlar**:

1. Yangi papka yarating: `nginx-demo`
2. Papka ichida `docker-compose.yml` fayl yarating
3. Quyidagi kodni yozing:

```yaml
version: "3.8"
services:
  nginx:
    image: nginx:latest
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
```

4. `html` papkasini yarating
5. `html/index.html` fayl yarating va ichiga:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Mening birinchi Nginx sahifam</title>
  </head>
  <body>
    <h1>Salom Nginx!</h1>
    <p>Bu mening birinchi web sahifam Nginx server orqali.</p>
  </body>
</html>
```

6. Terminal orqali: `docker-compose up -d`
7. Brauzerda `http://localhost:8080` ochib ko'ring

**Natija**: Sizning HTML sahifangiz Nginx server orqali ko'rsatiladi

---

## Topshiriq 2: Nginx konfiguratsiyasini sozlash

**Maqsad**: Nginx konfiguratsiya fayli bilan ishlashni o'rganish

**Bajariladigan ishlar**:

1. `nginx.conf` fayl yarating
2. Ichiga quyidagi konfiguratsiyani yozing:

```nginx
server {
    listen 80;
    server_name localhost;

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }

    location /images/ {
        root /usr/share/nginx/html;
        expires 1d;
        add_header Cache-Control "public, immutable";
    }
}
```

3. `docker-compose.yml` faylni yangilang:

```yaml
version: "3.8"
services:
  nginx:
    image: nginx:latest
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
```

4. `html/images` papkasi yarating va biror rasm fayl qo'ying
5. `docker-compose restart`
6. `http://localhost:8080/images/rasm.jpg` orqali rasmni ochib ko'ring

**Natija**: Nginx o'z konfiguratsiyasi bilan ishlaydi

---

## Topshiriq 3: Load Balancer sifatida Nginx

**Maqsad**: Nginx Load Balancer vazifasini qanday bajarishini ko'rish

**Bajariladigan ishlar**:

1. `app.js` fayl yarating (oddiy Express.js dastur):

```javascript
const express = require("express");
const os = require("os");

const app = express();
const port = 3000;

app.get("/", (req, res) => {
  const hostname = os.hostname();
  res.send(`
        <h1>Server: ${hostname}</h1>
        <p>Bu server sizga javob bermoqda!</p>
        <p>Vaqt: ${new Date().toLocaleString()}</p>
    `);
});

app.listen(port, "0.0.0.0", () => {
  console.log(`Server ${hostname} da ${port} portda ishlamoqda`);
});
```

2. `package.json` yarating:

```json
{
  "name": "nginx-demo-app",
  "version": "1.0.0",
  "main": "app.js",
  "dependencies": {
    "express": "^4.18.0"
  },
  "scripts": {
    "start": "node app.js"
  }
}
```

3. `Dockerfile` yarating:

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY app.js .
EXPOSE 3000
CMD ["npm", "start"]
```

4. `nginx-lb.conf` yarating:

```nginx
upstream backend {
    server app1:3000;
    server app2:3000;
}

server {
    listen 80;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

5. `docker-compose.yml` ni yangilang:

```yaml
version: "3.8"
services:
  nginx:
    image: nginx:latest
    ports:
      - "8080:80"
    volumes:
      - ./nginx-lb.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - app1
      - app2

  app1:
    build: .

  app2:
    build: .
```

6. `docker-compose up --build`
7. Sahifani bir necha marta yangilang va server nomlarining o'zgarishini kuzating

**Natija**: Nginx 2 ta Express.js server o'rtasida yuklarni teng taqsimlaydi

---

## Topshiriq 4: SSL va Static fayllar bilan ishlash

**Maqsad**: Nginx bilan SSL va static fayllarni samarali berish

**Bajariladigan ishlar**:

2. `html/css` va `html/js` papkalarini yarating
3. `html/css/style.css`:

```css
body {
  font-family: Arial, sans-serif;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  text-align: center;
  padding: 50px;
}
```

4. `nginx-ssl.conf` yarating:

```nginx
server {
    listen 80;
    server_name localhost;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name localhost;

    ssl_certificate /etc/ssl/certs/localhost+2.pem;
    ssl_certificate_key /etc/ssl/private/localhost+2-key.pem;

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }

    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        root /usr/share/nginx/html;
        expires 1y;
        add_header Cache-Control "public, immutable";
        gzip on;
        gzip_types text/css application/javascript image/svg+xml;
    }
}
```

5. `docker-compose.yml`:

```yaml
version: "3.8"
services:
  nginx:
    image: nginx:latest
    ports:
      - "8080:80"
      - "8443:443"
    volumes:
      - ./html:/usr/share/nginx/html
      - ./nginx-ssl.conf:/etc/nginx/conf.d/default.conf
      - ./localhost+2.pem:/etc/ssl/certs/localhost+2.pem
      - ./localhost+2-key.pem:/etc/ssl/private/localhost+2-key.pem
```

6. `html/index.html` ni yangilang:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>SSL bilan Nginx</title>
    <link rel="stylesheet" href="/css/style.css" />
  </head>
  <body>
    <h1>SSL Nginx Server</h1>
    <p>Bu sahifa HTTPS orqali xavfsiz yuborilmoqda!</p>
  </body>
</html>
```

7. `docker-compose up`
8. `https://localhost:8443` ga kiring (mkcert ishlatganimiz uchun SSL ogohlantirish bo'lmaydi!)

**Natija**: Nginx HTTPS bilan xavfsiz ishlaydi va static fayllarni optimallashtiradi

---

## Qo'shimcha ma'lumotlar

**Nginx nima?**

- Web server (veb-server)
- Reverse proxy server
- Load balancer (yukni taqsimlovchi)
- Static fayllar uchun juda tez

**Docker Compose nima uchun?**

- Bir necha konteynerlarni oson boshqarish
- Konfiguratsiyani fayl orqali saqlash
- Ishlab chiqish muhitini tez sozlash

**Foydali buyruqlar**:

- `docker-compose up -d` - orqada ishlatish
- `docker-compose logs nginx` - loglarni ko'rish
- `docker-compose restart` - qayta ishga tushirish
- `docker-compose down` - to'xtatish va o'chirish
