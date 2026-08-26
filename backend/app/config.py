# config.py — lê variáveis de ambiente do arquivo .env
import os
from dotenv import load_dotenv

load_dotenv()

# Origins permitidos pra CORS (separados por vírgula).
# Em produção, colocar só o domínio real no .env — nunca usar "*".
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:8080").split(",")
