# WorkForce — Backend API

REST API for the WorkForce HRMS Portal built with **Spring Boot 4**.

## Tech Stack

- Spring Boot 4.0.2
- Spring Security (JWT + 2FA)
- Spring Data JPA
- Spring WebSocket (STOMP)
- MySQL
- Swagger / OpenAPI
- JUnit 5, Mockito, H2

## Modules

- **Authentication** — Login, JWT, refresh tokens, 2FA with email OTP
- **Employee Management** — Register, update, activate/deactivate, assign managers
- **Department & Designation** — CRUD with activate/deactivate
- **Attendance** — Geo-fenced check-in/check-out, IP validation, late tracking
- **Leave Management** — Apply, approve/reject, balance tracking
- **Performance Reviews** — Self-assessment, manager rating, goal tracking
- **Chat** — Real-time 1-on-1 messaging via WebSocket
- **Notifications** — Real-time push notifications
- **Announcements** — Company-wide announcements
- **Activity Logs** — Audit trail for admin actions
- **IP Access Control** — Restrict access by IP range
- **Office Locations** — Manage office locations for geo-attendance
- **Dashboard & Reports** — Admin, Manager, and Employee dashboards

## Roles

| Role     | Access                     |
|----------|----------------------------|
| Admin    | Full system access         |
| Manager  | Team management, approvals |
| Employee | Self-service portal        |

## ER Diagram

![ER Diagram](ER%20diagram%201.png)

## Project Structure

```
src/
├── main/java/org/example/workforce/
│   ├── config/         # Security, JWT, WebSocket, Swagger
│   ├── controller/     # REST & WebSocket controllers
│   ├── dto/            # Request/Response objects
│   ├── exception/      # Global exception handling
│   ├── model/          # JPA entities & enums
│   ├── repository/     # Spring Data repositories
│   ├── service/        # Business logic
│   └── util/           # Utility classes
└── test/java/          # Unit & integration tests
```

## Prerequisites

- Java 17+
- MySQL 8+

## Setup

1. Create a MySQL database.

2. Update `src/main/resources/application.properties`:

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/your_db
spring.datasource.username=your_user
spring.datasource.password=your_password
jwt.secret=your_base64_secret
jwt.expiration=86400000
```

3. Run:

```bash
./mvnw spring-boot:run
```

Runs on `http://localhost:8080`

## Running Tests

```bash
./mvnw test
```

## API Docs

Swagger UI: `http://localhost:8080/swagger-ui.html`
