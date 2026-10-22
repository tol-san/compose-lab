
# ======================================================================
# 01. CONFIGURATION — ពិនិត្យការបញ្ចូល Config និង Services
# ======================================================================
# docker compose config                         # Dev: base + override (auto-merge)
# docker compose -f compose.yaml config          # Prod: base only
# docker compose config --services               # បង្ហាញឈ្មោះ Services
# docker compose config --images                 # បង្ហាញ Images ដែលប្រើ
# # ពិនិត្យ target: dev/prod, bind mounts, env interpolation និង secrets path។

# ======================================================================
# 02. DEVELOPMENT — Build, Run, Logs និង Test
# ======================================================================
# docker compose up --build -d                   # Build និង Run Dev នៅ Background
# docker compose ps                              # ពិនិត្យ Status/Health/Ports
# docker compose logs -f --tail 20               # Follow Logs (Ctrl+C បញ្ឈប់ការមើល)
# docker compose logs api db                     # Logs របស់ API និង Database
# curl -s http://localhost:8000/health          # Health endpoint
# curl -s http://localhost:8000 | grep -i seen   # Hit counter (បើ app មាន)
# curl -s -o /dev/null -w '%{http_code}\n' -d 'text=hello from curl' http://localhost:8000/notes  # រំពឹង 302 បើ app redirect
# curl -s http://localhost:8000 | grep -i hello  # ពិនិត្យ Note
# docker compose exec db psql -U labuser -d labdb -c 'SELECT * FROM notes;' # ប្ដូរ user/db ឱ្យត្រូវ .env
# docker compose exec redis redis-cli GET hits   # ពិនិត្យ Redis Counter

# ======================================================================
# 03. LIVE RELOAD — Dev Bind Mount (កែ Source Code ដោយមិន Rebuild)
# ======================================================================
# sed -i 's/Hello from Docker Compose!/Hello, DevOps learner!/' web/app.py
# docker compose logs --tail 5 web               # រកមើល Flask reload log
# curl -s http://localhost:8000 | grep -i hello  # ពិនិត្យអត្ថបទថ្មី
# sed -i 's/Hello, DevOps learner!/Hello from Docker Compose!/' web/app.py # Restore
# # ចំណាំ: sed អាចមិនផ្លាស់ប្ដូរអ្វីទេ បើអត្ថបទដើមមិនដូចគ្នា។

# ======================================================================
# 04. PRODUCTION — Base Config Only
# ======================================================================
# docker compose down                            # Stop/remove Dev containers; keep volumes
# docker compose -f compose.yaml up --build -d   # Run Prod target
# docker compose -f compose.yaml ps              # ពិនិត្យ Status
# docker compose -f compose.yaml exec web sh -c 'cat /proc/1/cmdline | tr "\0" " "; echo' # PID 1 (រំពឹង gunicorn បើ Dockerfile កំណត់)
# time docker compose -f compose.yaml stop web   # សាកល្បង Graceful Shutdown
# docker compose -f compose.yaml start web       # ចាប់ផ្ដើម Web ឡើងវិញ

# ======================================================================
# 05. MULTI-STAGE BUILD — Builder / Dev / Prod
# ======================================================================
# docker build --target builder -t compose-lab/api:builder ./api
# docker build --target dev -t compose-lab/api:dev-test ./api
# docker build --target prod -t compose-lab/api:prod-test ./api
# docker images 'compose-lab/*'                  # ប្រៀបធៀបទំហំ Images
# docker history compose-lab/api:builder         # មើល Layers របស់ Builder
# docker history compose-lab/api:prod-test       # មើល Layers របស់ Prod
# docker run --rm compose-lab/api:builder gcc --version # រំពឹងមាន GCC បើ Builder បានដំឡើង
# docker compose -f compose.yaml exec api sh -c 'command -v gcc || echo "gcc: not found"' # រំពឹងមិនមាន GCC ក្នុង Prod

# ======================================================================
# 06. LAYER CACHE — ពិនិត្យ Build Cache
# ======================================================================
# echo '# touch' >> api/app.py                    # កែតែ Code
# docker compose -f compose.yaml build api       # Dependency Layer គួរតែ Cached បើ Dockerfile រៀបចំត្រឹមត្រូវ
# echo '# touch' >> api/requirements.txt          # កែ Dependency File
# docker compose -f compose.yaml build api       # Pip Install Layer អាច Rebuild
# # Restore ដោយប្រុងប្រយ័ត្ន៖ Run តែបើបន្ទាត់ចុងក្រោយជា '# touch' ពិតប្រាកដ
# sed -i '$d' api/app.py api/requirements.txt
# docker compose -f compose.yaml up -d --build

# ======================================================================
# 07. SECURITY — Run ក្នុង Prod Mode
# ======================================================================
# docker compose -f compose.yaml exec web id     # ពិនិត្យ Non-root User
# docker compose -f compose.yaml exec web touch /app/x # រំពឹង Fail: Read-only FS
# docker compose -f compose.yaml exec web touch /tmp/x # រំពឹង Success: tmpfs
# docker compose -f compose.yaml exec web sh -c 'grep Cap /proc/1/status' # CapEff គួរតែ 0
# docker inspect compose-lab-web-1 --format 'ReadOnly={{.HostConfig.ReadonlyRootfs}} CapDrop={{.HostConfig.CapDrop}} SecOpt={{.HostConfig.SecurityOpt}}'
# docker inspect compose-lab-api-1 --format '{{json .Config.Env}}' | tr ',' '\n' | grep -i pass # បង្ហាញ FILE path មិនមែន Secret value
# # ប្រយ័ត្ន: Command ខាងក្រោមបង្ហាញពាក្យសម្ងាត់ពិតក្នុង Terminal!
# docker compose -f compose.yaml exec api cat /run/secrets/db_password
# docker compose -f compose.yaml exec web ls /run/secrets # Web មិនគួរមាន Secret នេះ
# docker stats --no-stream                       # ពិនិត្យ Memory/CPU Limits

# ======================================================================
# 08. NETWORK ISOLATION — frontend vs backend
# ======================================================================
# docker compose -f compose.yaml exec web python -c "import socket; print(socket.gethostbyname('db'))" # រំពឹង Fail: មិន share Network
# docker compose -f compose.yaml exec web python -c "import socket; print(socket.gethostbyname('api'))" # រំពឹង Success
# docker compose -f compose.yaml exec web python -c "import urllib.request; print(urllib.request.urlopen('http://api:5000/notes').read().decode())"
# # postgres:16.4-alpine អាចមិនមាន wget; ការបរាជ័យមិនចាំបាច់មានន័យថា Network blocked ទេ។
# docker compose -f compose.yaml exec db wget -T 3 -qO- http://example.com || echo 'no outbound access (or wget unavailable)'
# curl -s --max-time 3 http://localhost:5000 || echo 'API port not published'
# docker compose -f compose.yaml port web 5000  # រំពឹង 127.0.0.1:8000 បើប្រើ default
# docker network ls | grep compose-lab
# docker network inspect compose-lab_backend --format '{{.Internal}} {{range .Containers}}{{.Name}} {{end}}' # true, api, db

# ======================================================================
# 09. PERSISTENCE — Volumes រក្សាទុក Data
# ======================================================================
# curl -s -o /dev/null -d 'text=persist me' http://localhost:8000/notes
# docker compose -f compose.yaml down            # Keep named volumes
# docker compose -f compose.yaml up -d           # Recreate containers
# curl -s http://localhost:8000 | grep -E 'seen|persist' # Data គួរនៅសល់
# docker volume ls | grep compose-lab
# # DANGER: លុប pgdata និង redis-data (Data បាត់!) — Backup មុន
# docker compose -f compose.yaml down -v
# docker compose -f compose.yaml up -d           # init.sql Run ថ្មីនៅពេល pgdata ទទេ

# ======================================================================
# 10. FAILURE / RECOVERY — ពិនិត្យ Health និង Restart
# ======================================================================
# docker compose -f compose.yaml stop db         # បញ្ឈប់ DB
# docker compose -f compose.yaml ps              # API អាចនៅ Healthy បើ /health មិនពិនិត្យ DB
# curl -s http://localhost:8000 | grep -i error # Notes អាចមាន Error
# docker compose -f compose.yaml start db        # Restore DB
# docker compose -f compose.yaml kill api        # Kill API; restart policy អាចចាប់ផ្ដើមវិញ
# docker compose -f compose.yaml ps
# docker compose -f compose.yaml stop api        # depends_on មិនបញ្ឈប់ Web ដោយស្វ័យប្រវត្តិ
# docker compose -f compose.yaml start api
# # Challenge: បង្កើត /ready endpoint ដែល Query SELECT 1 ហើយកែ Healthcheck។

# ======================================================================
# 11. SCALING — API Replicas និង Web Port Conflict
# ======================================================================
# docker compose -f compose.yaml up -d --scale api=3 # API គ្មាន Published Port
# docker compose -f compose.yaml ps
# docker compose -f compose.yaml logs api        # DNS/Connection reuse មិនធានា Load Balance ស្មើៗគ្នា
# docker compose -f compose.yaml up -d --scale api=1 # Restore 1 replica
# # រំពឹង Fail: Web Replicas ប៉ះទង្គិច Fixed Host Port 8000
# docker compose -f compose.yaml up -d --scale web=2
# docker compose -f compose.yaml up -d --scale web=1 # Restore

# ======================================================================
# 12. CLEANUP — DANGEROUS: លុប Data / Images / Cache
# ======================================================================
# docker compose -f compose.yaml down            # Safe: Keep volumes
# # DANGER: Named Volumes និង Service Images នឹងត្រូវលុប
# docker compose -f compose.yaml down -v --rmi all
# docker rmi compose-lab/api:builder compose-lab/api:dev-test compose-lab/api:prod-test
# docker builder prune -f                        # លុប Build Cache ដែលមិនប្រើ (អាចប៉ះពាល់ Projects ផ្សេង)
# docker system df                               # ពិនិត្យ Disk Usage

# ======================================================================
# TROUBLESHOOTING — ពិនិត្យបញ្ហា
# ======================================================================
# docker compose config                         # YAML / Variables / Secret paths
# docker compose ps                             # Running / Exited / Unhealthy
# docker compose logs --tail 100 api db         # DB Connection / Python Errors
# docker compose build --no-cache api           # Rebuild ពេលសង្ស័យ Cache
# # Port already allocated: ប្ដូរ WEB_PORT ក្នុង .env
# # Secret permission denied: ពិនិត្យ owner/mode និង UID មុនកែ Permission
# # Missing env: cp .env.example .env ហើយបំពេញតម្លៃ
# # DB password changed: កែតាមវិធី Database Password Rotation; កុំ down -v ដើម្បីជួសជុលដោយមិន Backup
