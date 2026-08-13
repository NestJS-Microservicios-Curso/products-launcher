# Products App

Docker environment for a NestJS microservices application. It includes two domain microservices, an HTTP gateway, NATS for messaging, and PostgreSQL for Orders.

## Services

| Service          | Responsibility                                                                           | Exposed port                   |
| ---------------- | ---------------------------------------------------------------------------------------- | ------------------------------ |
| `client-gateway` | Inbound HTTP API; communicates with the microservices via NATS.                          | `CLIENT_GATEWAY_PORT` → `3000` |
| `products-ms`    | Product catalog. Uses SQLite persisted in a Docker volume and seeds 47 initial products. | Not exposed to the host        |
| `orders-ms`      | Order management. Uses PostgreSQL.                                                       | Not exposed to the host        |
| `nats-server`    | Messaging between Gateway, Products, and Orders.                                         | `4222`, monitoring `8222`      |
| `orders-db`      | Orders PostgreSQL database.                                                              | `127.0.0.1:5432`               |

## Quick start

1. Clone the repository and enter the root folder:

   ```bash
   git clone <REPOSITORY_URL>
   cd 03-Products-Launcher
   ```

2. Create the environment file from the template:

   ```bash
   cp .env.template .env
   ```

3. Check `CLIENT_GATEWAY_PORT` in `.env` and choose the gateway HTTP port.

4. Build and start all services:

   - **Production / Standard mode:**

     ```bash
     docker compose up --build
     ```

   - **Development mode with Hot Reload (Compose Watch):**

     ```bash
     docker compose -f docker-compose.yml -f docker-compose.watch.yml up --build --watch
     ```

     > The `docker-compose.watch.yml` file is loaded explicitly (it is not auto-loaded like `docker-compose.override.yml`). When you change source files inside `./<microservice>/src`, the changes are synced in real time to the container and NestJS applies hot reload without rebuilding the image.

## Verification

In another terminal, from the project root:

```bash
docker compose ps
docker compose logs -f
```

All five services should appear as running: `nats-server`, `orders-db`, `products-ms`, `orders-ms`, and `client-gateway`.

## Persistent data

- `orders_db_data`: PostgreSQL data for `orders-ms`.
- `products_db_data`: SQLite file and catalog for `products-ms`.

To stop the environment without deleting data:

```bash
docker compose down
```

To remove containers, volumes, and databases, and start from scratch:

```bash
docker compose down -v
docker compose up --build
```

> `docker compose down -v` deletes the persisted Orders and Products data.

## Git Submodules

### Steps to add and configure submodules

1. Create a new repository on GitHub.
2. Clone the repository to your local machine.
3. Add the submodule, where `<repository_url>` is the repository URL and `<directory_name>` is the target directory for the submodule (it must not exist in the project beforehand):

   ```bash
   git submodule add <repository_url> <directory_name>
   ```

4. Stage, commit, and push the changes to the repository:

   ```bash
   git add .
   git commit -m "Add submodule"
   git push
   ```

5. Initialize and update submodules. When cloning the repository for the first time, run:

   ```bash
   git submodule update --init --recursive
   ```

6. To update submodule references to the latest remote commit:

   ```bash
   git submodule update --remote
   ```

### Important

When working on a repository containing submodules, **always commit and push changes inside the submodule first**, and **then** commit and push the updated submodule reference in the main repository.

Doing it in reverse will cause the main repository to point to commits that do not exist on the remote, leading to submodule reference conflicts.
