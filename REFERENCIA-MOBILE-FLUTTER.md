# Referência do Front (Web) para o App Mobile Flutter

Este documento descreve como estão implementadas no front web as funcionalidades que você vai replicar no app Flutter: **tela de bem-vindo**, **bater ponto** e **estoque**. Use como base para implementar as mesmas telas e chamadas de API no mobile.

---

## 1. Configuração base

### URL da API
- **Base:** `process.env.NEXT_PUBLIC_API_URL` ou `http://localhost:3333`
- No Flutter: use uma constante ou variável de ambiente (ex.: `ApiConfig.baseUrl`).

### Autenticação
- Todas as rotas (exceto login e health) exigem o header:
  - `Authorization: Bearer <token>`
  - `Content-Type: application/json`
- O **token** e o **usuário** vêm do login e são guardados no **localStorage** (web). No Flutter use **SharedPreferences** ou **flutter_secure_storage** para persistir:
  - `token` (string)
  - `user` (objeto JSON: `id`, `name`, `email`, `role`)

### Login (para contexto)
- **POST** `/auth/login`
- **Body:** `{ "email": string, "password": string }`
- **Resposta:** `{ "message": string, "user": { "id", "name", "email", "role": "ADMIN" | "STAFF" }, "token": string }`
- Após sucesso: salvar `token` e `user` (JSON) e ir para a tela de bem-vindo (dashboard).

### Health (opcional)
- **GET** `/health` — rota pública, usada para “aquecer” o backend; não é obrigatória no mobile.

---

## 2. Tela de bem-vindo (Dashboard)

**Arquivo no front:** `src/app/dashboard/page.tsx`

### Dados exibidos
- **Título:** `Bem-vindo, {user.name}!` (fallback: "Usuário")
- **Subtítulo:** "Sistema de gestão empresarial"
- **Botão:** "Sair" — limpa `token` e `user` e redireciona para login

### Cards de atalho (para o mobile, por enquanto)
1. **Bater Ponto** — navega para tela de ponto (sempre visível)
2. **Estoque** — navega para tela de estoque (sempre visível)
3. **Colaboradores** — no web só ADMIN vê ativo; no mobile pode esconder ou deixar “em breve”
4. **Administração** — no web está “Em breve”; no mobile pode omitir ou igual

### Card “Informações da Conta”
- **Nome:** `user.name`
- **Email:** `user.email`
- **Perfil:** "Administrador" se `user.role === "ADMIN"`, senão "Colaborador"

### De onde vêm os dados
- **user:** lido do **localStorage** (chave `"user"`), parseado de JSON. No Flutter: ler do mesmo lugar onde você salvou no login (ex.: SharedPreferences / secure storage).

### Proteção da tela
- Se não houver `token`, redirecionar para a tela de login.

---

## 3. Bater ponto

**Arquivo no front:** `src/app/ponto/page.tsx`  
**API:** `src/lib/api.ts` (funções de ponto)

### Endpoints

| Ação            | Método | Rota                    | Body | Observação                    |
|-----------------|--------|-------------------------|------|-------------------------------|
| Iniciar trabalho| POST   | `/time-records/start`   | -    | Retorna registro START         |
| Encerrar trabalho | POST | `/time-records/stop`    | -    | Retorna registro STOP + summary |
| Resumo do dia   | GET    | `/time-records/summary` | -    | Query: `?date=YYYY-MM-DD` (opcional) |
| Listar registros| GET    | `/time-records`         | -    | Query: `?date=YYYY-MM-DD` (opcional) |

Todas as rotas são autenticadas (Bearer token).

### Tipos (para o Flutter)

```dart
// Registro de ponto
class TimeRecord {
  String id;
  String type;      // "START" | "STOP"
  String timestamp; // ISO 8601
  User user;        // id, name, email
}

// Período (entrada–saída)
class TimePeriod {
  String start;   // "HH:mm"
  String stop;    // "HH:mm"
  int minutes;
}

// Resumo do dia
class TimeSummary {
  String date;           // "YYYY-MM-DD"
  List<TimePeriod> periods;
  int totalMinutes;
  String totalHours;    // ex.: "4:30"
  String status;        // "started" | "stopped"
}
```

### Respostas das APIs

- **POST /time-records/start**  
  `{ "id", "type": "START", "timestamp", "user": { "id", "name", "email" }, "message" }`

- **POST /time-records/stop**  
  `{ "id", "type": "STOP", "timestamp", "user", "summary": TimeSummary, "message" }`

- **GET /time-records/summary?date=YYYY-MM-DD**  
  `{ "summary": TimeSummary }`

- **GET /time-records?date=YYYY-MM-DD**  
  `{ "records": TimeRecord[], "summary": TimeSummary }`

### Fluxo na tela de ponto (como no front)

1. Ao abrir a tela:
   - Chamar `getTimeSummary()` (hoje) e `getTimeRecords(undefined, undefined)` (hoje).
   - Exibir data de hoje (ex.: dd/MM/yyyy).

2. Status atual:
   - **Trabalhando:** `summary.status == "started"` → mostrar estado “Trabalhando” e **desabilitar** “Iniciar”, **habilitar** “Encerrar”.
   - **Parado:** `summary.status == "stopped"` → mostrar “Parado”, **habilitar** “Iniciar”, **desabilitar** “Encerrar”.

3. Botões:
   - **Iniciar Trabalho:** POST `/time-records/start` → mensagem de sucesso e recarregar resumo + lista.
   - **Encerrar Trabalho:** POST `/time-records/stop` → mensagem de sucesso, atualizar `summary` com a resposta e recarregar lista.

4. Resumo do dia:
   - `summary.totalHours` (destaque)
   - `summary.totalMinutes`
   - Lista de `summary.periods`: cada item `start - stop` e duração (ex.: “Xh Ym”).

5. Histórico do dia:
   - Lista de `records`: para cada um mostrar tipo (Entrada/Saída), data/hora formatada e hora (HH:mm:ss).

6. Atualizar:
   - Botão “Atualizar” que chama de novo `getTimeSummary()` e `getTimeRecords()`.

No Flutter você pode ter uma tela única com: status, botões Iniciar/Encerrar, resumo do dia e lista de registros, seguindo esse fluxo.

---

## 4. Estoque

**Página principal no front:** `src/app/estoque/page.tsx`  
**API:** `src/lib/api.ts` (funções de estoque)

Para o mobile “por enquanto” basta a **visão resumo** da tela de estoque (cards + alerta de estoque baixo). As telas de produtos, entrada, saída e relatórios podem ser implementadas depois.

### Endpoints usados na tela de resumo

| Descrição           | Método | Rota                 | Query (opcional)     | Retorno principal                    |
|---------------------|--------|----------------------|----------------------|-------------------------------------|
| Valor total         | GET    | `/stock/total-value`  | -                    | totalValue, totalProducts, productsWithStock |
| Estoque baixo       | GET    | `/stock/low-stock`    | `page`, `limit`      | products[], pagination               |
| Estoque atual (contagem) | GET | `/stock/current`      | `category`, `page`, `limit` | products[], pagination        |
| Uso do dia          | GET    | `/stock/daily-usage`  | `date=YYYY-MM-DD`    | date, products[], totalExits        |

Todos com `Authorization: Bearer <token>`.

### Tipos úteis (resumo)

```dart
// Valor total
class TotalValueResponse {
  String totalValue;  // ex.: "15000.50"
  int totalProducts;
  int productsWithStock;
}

// Produto em estoque baixo
class LowStockProduct {
  String id, name, unit;
  int currentStock, minStock;
  int deficit;  // quanto falta
  // + code, category, averageCost, totalValue se precisar
}

class LowStockResponse {
  List<LowStockProduct> products;
  PaginationInfo pagination;
}

// Uso diário (para “itens utilizados hoje”)
class DailyUsageProduct {
  ProductInfo product;  // id, name, unit
  int totalQuantity;
  List<DailyUsageExit> exits;
}
```

### O que a tela de estoque (resumo) mostra no front

1. **Header**
   - Título: "Controle de Estoque"
   - Subtítulo: "Gerencie produtos, entradas e saídas"
   - Botão Voltar (dashboard) e botão Atualizar (rechama as 4 APIs).

2. **Quatro cards de resumo**
   - **Valor Total:** `TotalValueResponse.totalValue` em BRL (R$ X.XXX,XX); subtítulo: “X produtos com valor”.
   - **Total de Produtos:** total de itens em `getCurrentStock()` (pagination.total ou length de products).
   - **Estoque Baixo:** total de itens em `getLowStock()` (pagination.total ou length); número em destaque (ex.: vermelho).
   - **Uso Hoje:** soma de `totalQuantity` de todos os `products` em `getDailyUsage(hoje)`; subtítulo “Itens utilizados hoje”.

3. **Ações rápidas (opcional no primeiro momento no mobile)**
   - No web: links para Produtos, Registrar Entrada, Registrar Saída, Relatórios. No Flutter você pode só colocar os 4 cards de resumo e depois adicionar navegação.

4. **Alerta de estoque baixo**
   - Se `lowStock.products.length > 0`: card “Produtos com Estoque Baixo” listando até 5 produtos com:
     - nome
     - `currentStock` e `minStock` + unidade
     - deficit (ex.: “-5”)
   - Se houver mais de 5, texto “+N produto(s) com estoque baixo”.

### Carregamento
- Ao abrir a tela (e no “Atualizar”), chamar em paralelo:
  - `getTotalValue()`
  - `getLowStock()`
  - `getCurrentStock()` (para contar total de produtos)
  - `getDailyUsage(hoje)` com data no formato `yyyy-MM-dd`

No Flutter você pode fazer o mesmo com `Future.wait` ou equivalente e preencher os 4 cards + lista de estoque baixo.

---

## 5. Resumo para o Flutter

- **Tela de bem-vindo:** ler `user` do armazenamento local; exibir nome, email, perfil; cards para Ponto e Estoque; botão Sair.
- **Bater ponto:** GET summary + GET records ao abrir; botões Iniciar/Encerrar (POST start/stop); exibir status, resumo do dia e histórico do dia.
- **Estoque (resumo):** GET total-value, low-stock, current (para contagem), daily-usage; 4 cards (valor total, total produtos, estoque baixo, uso hoje) + lista de produtos em estoque baixo.

Com isso você cobre a tela de bem-vindo, bater ponto e a parte de estoque que aparece hoje no front, prontas para espelhar no app Flutter.
