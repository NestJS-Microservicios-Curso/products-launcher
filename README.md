# Products App (Products Launcher)

Docker environment and multi-repo orchestrator for a NestJS microservices application. It includes domain microservices (`products-ms`, `orders-ms`, `payments-ms`), an HTTP API gateway, NATS messaging, PostgreSQL, SQLite, and Stripe payment processing.

## Services

| Service          | Responsibility                                                                           | Exposed port                   |
| ---------------- | ---------------------------------------------------------------------------------------- | ------------------------------ |
| `client-gateway` | Inbound HTTP API; communicates with the microservices via NATS.                          | `CLIENT_GATEWAY_PORT` → `3000` |
| `products-ms`    | Product catalog. Uses SQLite persisted in a Docker volume and seeds 47 initial products. | Not exposed to the host        |
| `orders-ms`      | Order management. Uses PostgreSQL.                                                       | Not exposed to the host        |
| `payments-ms`    | Payment processing via Stripe checkout sessions and webhook verification.                | `PAYMENTS_PORT` → `3003`       |
| `nats-server`    | Messaging between Gateway, Products, Orders, and Payments.                               | `4222`, monitoring `8222`      |
| `orders-db`      | Orders PostgreSQL database.                                                              | `127.0.0.1:5432`               |

---

## Quick start

1. Clone the repository and enter the root folder:

   ```bash
   git clone <REPOSITORY_URL>
   cd 03-products-launcher
   ```

2. Create the environment file from the template and configure your ports and Stripe credentials:

   ```bash
   cp .env.template .env
   ```

3. Initialize and clone all git submodules:

   ```bash
   git submodule update --init --recursive
   ```

4. Build and start all services:

   - **Production / Standard mode:**

     ```bash
     docker compose up --build
     ```

   - **Development mode with Hot Reload (Compose Watch):**

     ```bash
     docker compose -f docker-compose.yml -f docker-compose.watch.yml up --build --watch
     ```

   > [!NOTE]
   > **Architecture Note: File Separation, Compose Watch vs. Legacy Bind Mounts & Volumes**
   > - **Environment Separation & Production Parity:** We keep development and production configurations in separate files.
   >   - `docker-compose.yml` (Production Base): Builds the multi-stage `runner` target, runs compiled code (`node dist/main.js`), prunes `devDependencies`, and avoids any runtime watching overhead.
   >   - `docker-compose.watch.yml` (Development Overlay): Extends the base configuration to use the `dev` target, runs `npm run start:dev`, and activates Compose Watch.
   > - **Code Hot Reloading without Bind Mounts:** Instead of legacy bind mounts (`volumes: - ./src:/app/src`) that cause severe I/O degradation on macOS and file permission issues, **Compose Watch (`develop.watch`)** detects local file changes and syncs them directly into the running container for instant NestJS hot reloading.
   > - **Data Persistence vs. Code Syncing:** Named database volumes (`orders_db_data`, `products_db_data`) are strictly for persistent storage (PostgreSQL/SQLite) and are defined only in the base file. Stateless services (such as `payments-ms`) require no volumes. Compose files automatically merge when both `-f` flags are supplied.

---

## Verification

In another terminal, from the project root:

```bash
docker compose ps
docker compose logs -f
```

All six services should appear as running: `nats-server`, `orders-db`, `products-ms`, `orders-ms`, `payments-ms`, and `client-gateway`.

---

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

---

## Git Submodules

### Steps to add and configure submodules

1. Create a new repository on GitHub.
2. Clone the repository to your local machine.
3. Add the submodule, where `<repository_url>` is the repository URL and `<submodule_name>` is the optional target directory for the submodule (if omitted, Git uses the repository name):

   ```bash
   git submodule add <repository_url> <submodule_name>

   # Example:
   git submodule add https://github.com/NestJS-Microservicios-Curso/payments-microservice.git payments-microservice
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
