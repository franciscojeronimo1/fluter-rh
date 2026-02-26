# Usar o backend no app Flutter

Este guia mostra como conectar seu app Flutter ao backend (API REST).

## 1. Base URL da API



- **Produção:** use a URL do seu servidor (: `backendrh-gamma.vercel.app`)

O backend roda na porta **3333** por padrão (ou `PORT` no `.env`).

---

## 2. Autenticação

### Login

- **Método:** `POST`
- **URL:** `{baseUrl}/auth/login`
- **Body (JSON):**
  ```json
  {
    "email": "usuario@email.com",
    "password": "senha123"
  }
  ```
- **Resposta 200:**
  ```json
  {
    "message": "Login realizado com sucesso",
    "user": {
      "id": "uuid",
      "name": "Nome",
      "email": "usuario@email.com",
      "role": "ADMIN",
      "organizationId": "uuid ou null"
    },
    "organization": { "id": "uuid", "name": "Nome da Org" } ou null,
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
  ```

### Rotas protegidas

Todas as rotas exceto `/health` e `/auth/login` e `POST /users` exigem o token:

- **Header:** `Authorization: Bearer {token}`

Guarde o `token` após o login (ex: `shared_preferences` ou `flutter_secure_storage`) e envie em toda requisição autenticada.

---

## 3. Organização (tenant)

Rotas de **organizações, categorias, produtos e estoque** exigem que o usuário tenha `organizationId`. O backend obtém isso pelo usuário logado; **não é necessário enviar header de organização**.  
Se o usuário não tiver organização, a API retorna 400 com a mensagem explicando para criar/entrar em uma organização.

---

## 4. Endpoints principais

| Método | Rota | Auth | Descrição |
|--------|------|------|-----------|
| GET | `/health` | Não | Health check |
| POST | `/auth/login` | Não | Login |
| POST | `/users` | Não | Criar primeiro admin |
| GET | `/users` | Sim | Listar usuários |
| GET | `/users/:id` | Sim | Usuário por ID |
| PUT | `/users/:id` | Sim | Atualizar usuário |
| POST | `/time-records/start` | Sim | Iniciar ponto |
| POST | `/time-records/stop` | Sim | Parar ponto |
| GET | `/time-records` | Sim | Listar registros |
| GET | `/time-records/summary` | Sim | Resumo |
| POST | `/organizations` | Sim | Criar organização |
| GET | `/organizations` | Sim | Obter organização |
| PUT | `/organizations` | Sim | Atualizar organização |
| GET | `/categories` | Sim + tenant | Listar categorias |
| POST | `/categories` | Sim + tenant | Criar categoria |
| GET | `/products` | Sim + tenant | Listar produtos |
| POST | `/products` | Sim + tenant | Criar produto |
| GET | `/products/:id` | Sim + tenant | Produto por ID |
| PUT | `/products/:id` | Sim + tenant | Atualizar produto |
| GET | `/stock/current` | Sim + tenant | Estoque atual |
| GET | `/stock/low-stock` | Sim + tenant | Produtos com estoque baixo |
| POST | `/stock/entries` | Sim + tenant | Entrada de estoque |
| POST | `/stock/exits` | Sim + tenant | Saída de estoque |

---

## 5. Dependências Flutter sugeridas

No `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.2.0          # ou dio: ^5.4.0
  shared_preferences: ^2.2.2   # guardar token (ou flutter_secure_storage)
```

---

## 6. Exemplo rápido de chamada (Dart)

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

final baseUrl = 'http://10.0.2.2:3333'; // emulador Android

// Login
Future<Map<String, dynamic>> login(String email, String password) async {
  final res = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );
  if (res.statusCode != 200) {
    final err = jsonDecode(res.body);
    throw Exception(err['error'] ?? 'Erro no login');
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}

// Requisição autenticada
Future<http.Response> getWithAuth(String path, String token) async {
  return http.get(
    Uri.parse('$baseUrl$path'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
}
```

Use o `token` retornado no login em todas as rotas protegidas via header `Authorization: Bearer {token}`.

---

## 7. CORS

O backend já usa `cors()` sem restrição de origem. Para produção, convém restringir em `server.ts` (ex: apenas seu domínio e app).

---

## 8. Erros comuns

- **401 "Token não fornecido"** → Enviar header `Authorization: Bearer {token}`.
- **401 "Token inválido ou expirado"** → Fazer login de novo e guardar o novo token.
- **400 "Usuário não está vinculado a uma organização"** → Usar `POST /organizations` para criar ou vincular a uma organização antes de usar categorias/produtos/estoque.
- **Conexão recusada no emulador** → Usar `10.0.2.2` (Android) ou `127.0.0.1` (iOS) em vez de `localhost`.

Se quiser, posso montar um módulo de **API client** em Dart (classe com login, token e métodos por recurso) para você colar no projeto Flutter.
