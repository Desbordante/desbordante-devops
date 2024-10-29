# Desbordante DevOps

## Installation

```shell
make init
```

### Don't forget to change values in .env

## Update GitHub org secrets & variables

Update the secrets and variables in the organization settings on GitHub

Secrets:

- `SSH_HOST`
- `SSH_USERNAME`
- `SSH_PASSWORD`

Variables:

- `PROJECT_DIR` - Project directory on the server, example: `~/desbordante`

## Commands

Execute `make` to see all available rules with documentation

1. Pull containers: `make pull`
2. Start containers: `make up`
3. Pull & start (update): `make update`

## Accessing Services

After starting the containers, you can access the following services on `localhost`:

- **FastAPI documentation (Swagger UI):** [http://localhost:8000/docs](http://localhost:8000/docs)
- **Flower Celery monitoring panel:** [http://localhost:5555](http://localhost:5555)
