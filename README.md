# DataFish

A microservices e-commerce fish store built for observability demos. 8 services, 5 languages, deployed on bare metal EC2 with systemd.

## Architecture

```
                         ┌──────────────────┐
                         │     Frontend     │
                         │  React + Vite    │
                         │    port 3000     │
                         └────────┬─────────┘
                                  │
                         ┌────────▼─────────┐
                         │   API Gateway    │
                         │  Node.js/Express │
                         │    port 8080     │
                         └──┬────┬────┬─────┘
                            │    │    │
              ┌─────────────┘    │    └─────────────┐
              │                  │                  │
    ┌─────────▼────────┐ ┌──────▼──────────┐ ┌─────▼──────────────┐
    │ Product Service  │ │  Order Service  │ │Notification Service│
    │ Java/Spring Boot │ │ Python/FastAPI  │ │      Go/Gin        │
    │   port 8081      │ │   port 8082     │ │    port 8083       │
    └──────────────────┘ └──┬────┬────┬────┘ └────────────────────┘
                            │    │    │
              ┌─────────────┘    │    └─────────────┐
              │                  │                  │
    ┌─────────▼────────┐ ┌──────▼──────────┐ ┌─────▼──────────────┐
    │ Payment Service  │ │Inventory Service│ │ Analytics Service  │
    │ Python/FastAPI   │ │Java/Spring Boot │ │  Python/FastAPI    │
    │   port 8084      │ │   port 8085     │ │    port 8086       │
    └──────────────────┘ └─────────────────┘ └────────────────────┘
```

| Service              | Language/Framework    | Port |
|----------------------|-----------------------|------|
| Frontend             | React + Vite          | 3000 |
| API Gateway          | Node.js + Express     | 8080 |
| Product Service      | Java + Spring Boot    | 8081 |
| Order Service        | Python + FastAPI      | 8082 |
| Notification Service | Go + Gin              | 8083 |
| Payment Service      | Python + FastAPI      | 8084 |
| Inventory Service    | Java + Spring Boot    | 8085 |
| Analytics Service    | Python + FastAPI      | 8086 |

## Deploy to EC2

```bash
./scripts/deploy-to-ec2.sh <ec2-hostname> <pem-file>
```

## Local Development

```bash
./scripts/install-all.sh
./scripts/start-all.sh
```

App runs at http://localhost:3000

## Prerequisites

- Java 17+
- Python 3.8+
- Go 1.24+
- Node.js 18+
