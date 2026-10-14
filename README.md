# Starter Kit Full-Stack

Base pronta para iniciar novos projetos com **Laravel + React + PostgreSQL + Redis**, tudo rodando em Docker. Um comando cria um projeto independente; outro deixa o ambiente funcionando.

| Camada | Tecnologia |
|---|---|
| Backend | Laravel 13, PHP 8.3, Sanctum |
| Frontend | React 19, TypeScript, Vite, Tailwind 4 |
| Banco de dados | PostgreSQL 16 |
| Cache / filas | Redis 7 |
| Infraestrutura | Docker Compose, Makefile |

## Estrutura

```text
fullstack-starter/
├── backend/        API Laravel (rotas em routes/api/v1.php)
├── frontend/       App React + TypeScript + Vite
├── docker/         Dockerfiles (PHP, Node) e init do PostgreSQL
├── bin/
│   ├── new-project   Gera um projeto novo a partir deste kit
│   └── setup-env     Cria o .env e gera senhas (usado por make init)
├── tests/          Testes do gerador
├── compose.yaml    Serviços: backend, frontend, postgres, redis
├── Makefile        Comandos do dia a dia (make help)
└── .env.example    Modelo de configuração
```

## Pré-requisitos (macOS)

PHP, Composer e Node **não** precisam estar instalados: rodam dentro dos containers.

| Ferramenta | Para quê | Como obter |
|---|---|---|
| Docker Desktop | Executa todos os serviços | https://www.docker.com/products/docker-desktop/ |
| Git | O gerador lê os arquivos versionados | `xcode-select --install` |
| make | Comandos `make ...` | vem com `xcode-select --install` |
| curl | `make health` | já vem no macOS |

Abra o Docker Desktop e aguarde ele ficar em execução antes de continuar.

## Instalação do Starter Kit

```bash
cd /Users/diogo/Desktop/Desenvolvimento
git clone https://github.com/Diogo1006br/Starter-Kit.git fullstack-starter
```

O gerador copia os arquivos versionados pelo Git, então o kit precisa ser um repositório com tudo commitado.

## Criar um novo projeto

```bash
cd /Users/diogo/Desktop/Desenvolvimento/fullstack-starter
bin/new-project meu-app
cd ../meu-app
make init
```

O que acontece:

1. `bin/new-project meu-app` cria `../meu-app` (ao lado do kit) como projeto independente, com seu próprio `git init`. Nenhum container é iniciado.
2. As portas do host são escolhidas automaticamente: livres e diferentes das de outros projetos.
3. `make init` constrói as imagens, instala as dependências (pelos lockfiles), gera senhas e `APP_KEY`, sobe os serviços e roda as migrations. A primeira execução leva alguns minutos.

O projeto novo **não** recebe o `.env` do kit, senhas, chaves, logs, `node_modules`, `vendor` nem o histórico Git. Cada projeto gera os próprios segredos.

Opções do gerador:

| Opção | Descrição |
|---|---|
| `--dir CAMINHO` | Pasta de destino (não pode existir) |
| `--backend-port N` / `--frontend-port N` | Portas da API e do frontend |
| `--postgres-port N` / `--redis-port N` | Portas do PostgreSQL e Redis |
| `--dry-run` | Mostra o plano sem criar nada |
| `--no-git` | Não executa `git init` |

O nome deve usar minúsculas, números e hífens (ex.: `meu-app`).

## Acessar a aplicação

As portas exatas aparecem no fim do `make init` e no `.env` do projeto. O kit em si usa:

| Serviço | URL |
|---|---|
| Frontend | http://localhost:5174 |
| API | http://localhost:8080 |
| Health | http://localhost:8080/api/v1/health |

Em projetos gerados as portas são outras: use `make health` ou consulte `FRONTEND_PORT` e `BACKEND_PORT` no `.env`. A página inicial mostra o status da API, do PostgreSQL e do Redis.

## Iniciar e parar

```bash
make up      # inicia os containers
make down    # para e remove os containers (os dados do banco são mantidos)
make stop    # apenas para, sem remover
make ps      # status e health dos serviços
```

Depois de reiniciar o computador, abra o Docker Desktop e rode `make up`.

## Testes e verificações

```bash
make test     # testes do backend (SQLite) e do frontend
make test-pg  # testes do backend contra PostgreSQL real
make lint     # Pint + Oxlint
make check    # tudo: lint, formatação, testes e build do frontend
```

Para testar o gerador (no kit; não inicia containers):

```bash
bash tests/new-project.sh
```

## Comandos do dia a dia

| Comando | Descrição |
|---|---|
| `make help` | Lista todos os comandos |
| `make logs` / `make logs c=backend` | Acompanha logs |
| `make health` | Chama o endpoint de health |
| `make shell-backend` / `make shell-frontend` | Terminal dentro do container |
| `make artisan c="migrate:status"` | Executa artisan |
| `make composer c="require vendor/pacote"` | Executa composer |
| `make npm c="install pacote"` | Executa npm no frontend |
| `make migrate` | Roda as migrations |
| `make fresh` | Recria as tabelas (apaga os dados de desenvolvimento) |
| `make format` | Formata backend e frontend |
| `make up-workers` | Sobe também fila e scheduler |
| `make reset` | **Perigoso:** remove containers e volumes (banco e Redis) |

## Problemas comuns

| Sintoma | Solução |
|---|---|
| `Docker is not running` | Abra o Docker Desktop e aguarde iniciar |
| `port ... is already in use` | Gere com outra porta: `bin/new-project meu-app --backend-port 8090`. Em projeto existente, altere a porta no `.env` e rode `make up` |
| `destination already exists` | Escolha outro nome ou `--dir` |
| `make: command not found` | Rode `xcode-select --install` |
| Frontend não atualiza ao editar | Defina `CHOKIDAR_USEPOLLING=true` no `.env` e rode `make restart` |
| `make health` falha logo após subir | Aguarde alguns segundos ou veja `make logs c=backend` |
| Recomeçar do zero (dados incluídos) | `make reset` e depois `make init` |

## Publicar seu projeto

O projeto gerado não tem remoto. Crie um repositório vazio no GitHub e execute:

```bash
git add .
git commit -m "chore: initial commit"
git remote add origin https://github.com/SEU-USUARIO/meu-app.git
git push -u origin main
```

O `.env` está no `.gitignore` e não é versionado.

## Mais informações

Decisões técnicas e versões instaladas: [docs/DECISIONS.md](docs/DECISIONS.md).
