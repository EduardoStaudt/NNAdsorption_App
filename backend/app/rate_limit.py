# rate_limit.py — limitador de requisições por IP (proteção contra força bruta)
from slowapi import Limiter
from slowapi.util import get_remote_address

# Limite mais rígido pra login/register (evita força bruta de senhas)
LIMITE_AUTH = "5/minute"

# 60 req/min por IP em todos os endpoints por padrão.
# headers_enabled=True adiciona o header Retry-After nas respostas 429.
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=["60/minute"],
    headers_enabled=True,
)
