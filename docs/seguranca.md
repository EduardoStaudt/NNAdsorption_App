# Segurança

Medidas de segurança implementadas no backend, com o raciocínio por trás de
cada uma. Todas são testadas em `backend/tests/test_security.py`.

## 1. Senhas com hash bcrypt

A senha nunca é guardada em texto puro. No cadastro, `security.py` gera um
hash **bcrypt** (com salt automático) e só ele vai pro banco. No login, a
senha digitada é comparada com o hash via `verificar_senha()`.

Mesmo que alguém obtenha o banco de dados, não consegue recuperar as senhas.

## 2. Autenticação por JWT

Após login/cadastro, o backend devolve um **JSON Web Token** assinado com a
chave `JWT_SECRET` do `.env`, com validade de 7 dias. Endpoints protegidos
verificam a assinatura e a expiração a cada requisição — não há sessão no
servidor.

> ⚠️ Em produção, `JWT_SECRET` deve ser uma string longa e aleatória,
> nunca o valor de exemplo do `.env.example`.

## 3. Rate limit (slowapi)

Proteção contra força bruta e abuso, por IP:

| Endpoints | Limite |
|-----------|--------|
| `/auth/login` e `/auth/register` | **5 requisições/minuto** |
| Todos os demais | **60 requisições/minuto** |

Ao ultrapassar, a API responde **429 Too Many Requests** com o header
`Retry-After` indicando quando tentar de novo. O limite baixo nos endpoints
de autenticação torna inviável adivinhar senhas por tentativa e erro.

Implementação: `app/rate_limit.py` (limiter) + decorators em
`routers/auth.py` + `SlowAPIMiddleware` no `main.py`.

## 4. Headers de segurança

Um middleware em `main.py` adiciona em **toda** resposta:

| Header | Contra o quê protege |
|--------|----------------------|
| `X-Content-Type-Options: nosniff` | navegador "adivinhar" tipo de arquivo (MIME sniffing) |
| `X-Frame-Options: DENY` | clickjacking (site embutido em iframe malicioso) |
| `Referrer-Policy: strict-origin-when-cross-origin` | vazar URLs internas pra outros sites |
| `Strict-Transport-Security` | downgrade de HTTPS pra HTTP |
| `Content-Security-Policy: default-src 'self'` | injeção de scripts externos (XSS) |

## 5. CORS estrito

Só podem chamar a API pelo navegador:

- as origens listadas em `ALLOWED_ORIGINS` (no `.env`);
- qualquer porta de `http://localhost` (regex `http://localhost:\d+`),
  porque o `flutter run` sorteia uma porta nova a cada execução.

```
ALLOWED_ORIGINS=http://localhost:8080,http://localhost:3000
```

Em produção, trocar pelas URLs reais do frontend. O regex de localhost não
representa risco em produção — sites externos nunca têm origem `localhost`.
**Nunca usar `*`** — isso permitiria que qualquer site fizesse requisições
autenticadas em nome do usuário.

## 6. Validação de entrada

- **Email**: formato validado pelo Pydantic (`EmailStr`).
- **Senha**: mínimo de 8 caracteres, com pelo menos 1 letra e 1 número
  (validado no backend e também no formulário do frontend).
- **Inputs da predição**: cada valor passa por checagem de faixa física
  plausível (`L > 0`, `eps` entre 0 e 1, sem NaN/infinito etc.) antes de
  chegar na rede neural. Valores absurdos retornam **422** com mensagem
  clara em vez de produzir resultados sem sentido.

## 7. Isolamento por usuário

Todas as consultas de histórico e exportação filtram por
`user_id == usuário do token`. Um usuário não consegue ver, exportar ou
apagar predições de outro — tentar acessar um id alheio retorna **404**.

## Limitações conhecidas (fora do escopo atual)

- Sem verificação de email (endpoint `/auth/verify-email` é placeholder).
- Sem refresh token — expirado o JWT, o usuário loga de novo.
- Rate limit em memória — zera quando o servidor reinicia (aceitável aqui;
  em escala usaria Redis).
