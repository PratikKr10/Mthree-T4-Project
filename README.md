# Frontend

``` bash
npm install
npm run dev
```

# Backend
``` bash
# Enter virtual Env
python3 -m venv venv
source venv/bin/activate

# run backend

flask --app server.py run --debug # devmode
flask --app server.py run # normal
```
- Backend runs on `http://localhost:5000/`
- Frontend runs on `http://localhost:5173/`

## .env for frontend

``` 
VITE_BASE_URL=http://127.0.0.1:5000
VITE_API_URL=http://127.0.0.1:5000
```

## .env for backend
```
DB_CONNECT='mysql+mysqlconnector://username:password@localhost:port/database'
JWT_SECRET_KEY='your_secret_key'
```

# Containerization & Orchestration

- Run the application on kubernetes via.. run.sh

```
chmod +x run.sh
./run.sh

```
