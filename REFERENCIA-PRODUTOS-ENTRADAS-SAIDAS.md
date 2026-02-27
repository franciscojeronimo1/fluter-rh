# Referência: Produtos, Registrar Entradas e Saídas (para Flutter)

Este documento descreve como estão implementadas no front web as funcionalidades de **produtos** (listagem, criar, editar, excluir) e **registrar entradas e saídas** de estoque. Use como base para implementar no app Flutter.

---

## 1. Categorias (usadas em produtos)

As categorias são usadas para classificar produtos. Antes de criar/editar produtos, você pode precisar listar ou criar categorias.

### Endpoints de categorias

| Ação        | Método | Rota              | Body / Query              |
|-------------|--------|-------------------|---------------------------|
| Listar      | GET    | `/categories`     | -                         |
| Criar       | POST   | `/categories`     | `{ "name": string }`       |
| Atualizar   | PUT    | `/categories/:id`  | `{ "name": string }`       |
| Excluir     | DELETE | `/categories/:id`  | -                         |

### Tipo Category

```dart
class Category {
  String id;
  String name;
}
```

### Respostas

- **GET /categories:** `{ "categories": Category[] }`
- **POST /categories:** `{ "category": Category }`
- **PUT /categories/:id:** `{ "category": Category }`
- **DELETE /categories/:id:** `{ "message": string }`

---

## 2. Produtos

### Endpoints

| Ação        | Método | Rota             | Body / Query                                      |
|-------------|--------|------------------|---------------------------------------------------|
| Listar      | GET    | `/products`      | `?category=X&includeInactive=true&page=1&limit=10` |
| Buscar por ID | GET  | `/products/:id`  | -                                                 |
| Criar       | POST   | `/products`      | CreateProductRequest                              |
| Atualizar   | PUT    | `/products/:id`  | UpdateProductRequest                              |
| Excluir     | DELETE | `/products/:id`  | -                                                 |

### Parâmetros da listagem (GET /products)

- **category** (opcional): nome da categoria para filtrar
- **includeInactive** (opcional): `true` = retorna ativos + inativos; omitido ou `false` = apenas ativos
- **page** (opcional): página (padrão 1)
- **limit** (opcional): itens por página (ex.: 10, 20, 30)

**Observação:** No front, a busca por nome/código/SKU é feita **no cliente** após carregar a lista. A API não tem parâmetro `q`. Para o mobile, você pode carregar a lista e filtrar localmente, ou implementar busca no backend depois.

### Tipos

```dart
class Product {
  String id;
  String name;
  String? code;
  String? sku;
  String? category;
  int currentStock;
  int minStock;
  String unit;
  String? costPrice;
  String? averageCost;
  bool active;
  String organizationId;
  String createdAt;
  String updatedAt;
}

class PaginationInfo {
  int page;
  int limit;
  int total;
  int totalPages;
  bool hasNext;
  bool hasPrev;
}

class ProductsResponse {
  List<Product> products;
  PaginationInfo pagination;
}
```

### Criar produto (POST /products)

**Body (CreateProductRequest):**

```json
{
  "name": "string",        // obrigatório
  "code": "string",        // opcional
  "sku": "string",         // opcional
  "category": "string",    // opcional - nome da categoria
  "minStock": 0,           // opcional - número >= 0
  "unit": "UN",            // opcional - ex: UN, MT, KG
  "costPrice": 0.00        // opcional - número >= 0
}
```

**Resposta:** `{ "message": string, "product": Product }`

### Atualizar produto (PUT /products/:id)

**Body (UpdateProductRequest):** todos os campos opcionais

```json
{
  "name": "string",
  "code": "string",
  "sku": "string",
  "category": "string",
  "minStock": 0,
  "unit": "string",
  "costPrice": 0.00,
  "active": true
}
```

**Resposta:** `{ "message": string, "product": Product }`

### Excluir produto (DELETE /products/:id)

- Marca o produto como **inativo** (soft delete). Não remove do banco.
- **Resposta:** `{ "message": string }`

---

## 3. Tela de listagem de produtos

**Arquivo no front:** `src/app/estoque/produtos/page.tsx`

### Fluxo

1. **Carregar categorias:** GET `/categories` (para o filtro)
2. **Carregar produtos:** GET `/products` com `category`, `includeInactive`, `page`, `limit`
3. **Busca local (opcional):** filtrar `products` por nome, código ou SKU contendo o termo digitado
4. **Filtros:** categoria (all ou nome), status (all / ativos / inativos), itens por página

### Colunas exibidas na tabela

| Coluna      | Origem                    |
|-------------|---------------------------|
| Nome        | `product.name`             |
| Código      | `product.code` ou "-"      |
| Categoria   | `product.category` ou "-" |
| Estoque     | `product.currentStock` (destaque vermelho se < minStock) |
| Mínimo      | `product.minStock`         |
| Unidade     | `product.unit`             |
| Preço Custo | `product.costPrice` formatado em BRL ou "-" |
| Status      | "Ativo" ou "Inativo"       |
| Ações       | Editar, Excluir            |

### Ações

- **Novo Produto:** navega para `/estoque/produtos/novo`
- **Editar:** navega para `/estoque/produtos/:id`
- **Excluir:** abre diálogo de confirmação; ao confirmar, chama DELETE `/products/:id` e recarrega a lista

### Paginação

- Exibir "Página X de Y"
- Botões Anterior / Próxima (desabilitados quando não há página anterior/próxima)
- Input para ir direto para uma página

### Estoque baixo

- `product.currentStock < product.minStock` → exibir estoque em vermelho e ícone de alerta

---

## 4. Tela de novo produto

**Arquivo no front:** `src/app/estoque/produtos/novo/page.tsx`

### Campos do formulário

| Campo          | Obrigatório | Tipo   | Descrição                          |
|----------------|-------------|--------|------------------------------------|
| Nome           | Sim         | string | Nome do produto                    |
| Código         | Não         | string | Código interno                     |
| SKU            | Não         | string | Código SKU                         |
| Categoria      | Não         | string | Nome da categoria (select)         |
| Estoque Mínimo | Não         | number | >= 0, padrão 0                      |
| Unidade        | Sim         | string | Ex: UN, MT, KG (padrão "UN")       |
| Preço de Custo | Não         | number | >= 0                                |

### Categoria

- Select com lista de categorias (GET `/categories`)
- No front há um `CategorySelect` que permite criar categoria na hora (botão +) via POST `/categories`
- No Flutter: pode ser um dropdown simples ou incluir opção de criar categoria em um modal

### Validação

- Nome: obrigatório
- Unidade: obrigatória
- Estoque mínimo: >= 0
- Preço de custo: se informado, >= 0

### Submit

- POST `/products` com o body
- Em sucesso: redirecionar para a lista de produtos

---

## 5. Tela de editar produto

**Arquivo no front:** `src/app/estoque/produtos/[id]/page.tsx`

### Fluxo

1. GET `/products/:id` para carregar o produto
2. Preencher o formulário com os dados
3. Ao salvar: PUT `/products/:id` com os dados alterados

### Campos (mesmos do novo, mais)

- **Produto Ativo:** checkbox — produtos inativos não aparecem nas listagens padrão
- **Informações de Estoque (somente leitura):** Estoque Atual, Custo Médio

### Body do PUT

- Enviar apenas os campos que podem ser alterados (name, code, sku, category, minStock, unit, costPrice, active)

---

## 6. Registrar entrada (compra/recebimento)

**Arquivo no front:** `src/app/estoque/entrada/page.tsx`  
**Endpoint:** POST `/stock/entries`

### Campos do formulário

| Campo              | Obrigatório | Tipo   | Descrição                          |
|--------------------|-------------|--------|------------------------------------|
| Produto            | Sim         | select | ID do produto (lista de produtos)   |
| Quantidade         | Sim         | number | > 0                                 |
| Preço Unitário     | Sim         | number | > 0                                 |
| Nome do Fornecedor | Não         | string |                                    |
| CNPJ/CPF Fornecedor| Não         | string |                                    |
| Nº Nota Fiscal     | Não         | string |                                    |
| Observações        | Não         | string |                                    |

### Cálculo do total

- **Total = Quantidade × Preço Unitário** (exibir em tempo real, formatado em BRL)

### Fluxo

1. **Carregar produtos:** GET `/products` com `limit: 100` (ou paginar se precisar)
2. **Select de produto:** exibir `nome` e opcionalmente `código`
3. **Validação:** quantidade e preço unitário > 0
4. **Submit:** POST `/stock/entries` com o body abaixo

### Body (CreateStockEntryRequest)

```json
{
  "productId": "uuid",
  "quantity": 10,
  "unitPrice": 25.50,
  "supplierName": "string",
  "supplierDoc": "string",
  "invoiceNumber": "string",
  "notes": "string"
}
```

Campos opcionais: `supplierName`, `supplierDoc`, `invoiceNumber`, `notes`.

### Resposta

`{ "message": string, "entry": StockEntry }`

### Após sucesso

- Redirecionar para a tela de estoque (ou lista de entradas, se existir)

---

## 7. Registrar saída (uso/consumo)

**Arquivo no front:** `src/app/estoque/saida/page.tsx`  
**Endpoint:** POST `/stock/exits`

### Campos do formulário

| Campo           | Obrigatório | Tipo   | Descrição                          |
|-----------------|-------------|--------|------------------------------------|
| Produto         | Sim         | select | ID do produto                      |
| Quantidade      | Sim         | number | > 0 e <= estoque disponível        |
| Preço unitário  | Não         | number | Para venda; saídas internas podem ficar vazias |
| Nome do Projeto | Não         | string |                                    |
| Nome do Cliente | Não         | string |                                    |
| Tipo de Serviço | Não         | string |                                    |
| Observações     | Não         | string |                                    |

### Diferenças em relação à entrada

1. **Lista de produtos:** apenas produtos com `currentStock > 0`
2. **Estoque disponível:** ao selecionar o produto, exibir `currentStock` e `unit`
3. **Alerta de estoque baixo:** se `currentStock < minStock`, exibir aviso
4. **Quantidade:** validar `quantidade <= currentStock` antes de enviar
5. **Preço unitário:** opcional — quando informado, calcular e exibir "Total da venda"

### Fluxo

1. **Carregar produtos:** GET `/products` com `limit: 100`, filtrar `currentStock > 0`
2. **Select de produto:** exibir nome, código e estoque (ex.: "Produto X - Estoque: 50 UN")
3. **Ao selecionar:** mostrar card com estoque disponível e alerta se estoque baixo
4. **Validação:** quantidade > 0 e quantidade <= currentStock
5. **Submit:** POST `/stock/exits` com o body abaixo

### Body (CreateStockExitRequest)

```json
{
  "productId": "uuid",
  "quantity": 5,
  "unitPrice": 30.00,
  "projectName": "string",
  "clientName": "string",
  "serviceType": "string",
  "notes": "string"
}
```

- `unitPrice` é opcional (omitir para saídas sem venda)
- Demais campos opcionais

### Resposta

`{ "message": string, "exit": StockExit }`

### Validação no front

- Se `quantidade > currentStock`, exibir erro e não enviar a requisição

---

## 8. Resumo das rotas de API

| Funcionalidade   | Método | Rota                    |
|-----------------|--------|-------------------------|
| Listar categorias| GET    | `/categories`           |
| Criar categoria | POST   | `/categories`           |
| Listar produtos | GET    | `/products`             |
| Buscar produto  | GET    | `/products/:id`         |
| Criar produto   | POST   | `/products`             |
| Atualizar produto | PUT  | `/products/:id`         |
| Excluir produto | DELETE | `/products/:id`         |
| Registrar entrada | POST | `/stock/entries`         |
| Registrar saída | POST   | `/stock/exits`          |

Todas as rotas exigem `Authorization: Bearer <token>`.

---

## 9. Sugestões para o Flutter

1. **Produtos:** use `ListView` ou `DataTable` com paginação; filtros em um `Drawer` ou barra superior.
2. **Categorias:** dropdown com opção de "Nova categoria" que abre um `AlertDialog` ou `BottomSheet`.
3. **Entrada/Saída:** formulário com `TextFormField` e `DropdownButtonFormField` para produto; validação com `validator` ou pacote como `flutter_form_builder`.
4. **Estoque baixo:** `currentStock < minStock` → `TextStyle` em vermelho ou `Container` com borda/background de alerta.
5. **Formatação:** use `intl` para moeda (BRL) e números.
