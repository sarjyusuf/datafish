# Product Service (Java/Spring Boot)

Fish catalog and inventory management service.

## Setup

```bash
cd product-service
./mvnw clean install
./mvnw spring-boot:run
```

Or with pre-installed Maven:

```bash
mvn clean install
mvn spring-boot:run
```

## Endpoints

- `GET /api/products` - List all products
  - Query params: `?category=Tropical`, `?search=clown`, `?habitat=saltwater`, `?featured=true`
- `GET /api/products/{id}` - Get product details
- `POST /api/products` - Create new product
- `PUT /api/products/{id}` - Update product
- `DELETE /api/products/{id}` - Delete product
- `GET /actuator/health` - Health check

## Database

Uses H2 in-memory database with 15 pre-loaded fish products.

## Categories

- Tropical
- Goldfish
- Koi
- Exotic
- Community

