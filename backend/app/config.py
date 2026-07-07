# config.py — lê variáveis de ambiente do arquivo .env
import os
from dotenv import load_dotenv

load_dotenv()

# Chave secreta pra assinar os tokens JWT
JWT_SECRET = os.getenv("JWT_SECRET", "mude-isso-em-producao")

# Quantos dias o token JWT dura
JWT_EXPIRES_DAYS = int(os.getenv("JWT_EXPIRES_DAYS", "7"))

# URL do banco de dados SQLite
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./app.db")

# Origins permitidos pra CORS (separados por vírgula).
# Em produção, colocar só o domínio real no .env — nunca usar "*".
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:8080").split(",")
