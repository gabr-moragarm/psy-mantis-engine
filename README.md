# Psy-Mantis-Engine

> **⚠️ Work in Progress** – Ruby/Sinatra backend API to analyze a Steam games library and provide Psycho Mantis-style commentary.
> Currently implements only the base structure with a placeholder /analyze endpoint.

![Build Status](https://github.com/gabr-moragarm/psy-mantis-engine/actions/workflows/ci.yml/badge.svg)

---

## 📌 Project Status

- **Completed**
  - Base Sinatra structure
  - Custom PsyMantis::Logger with LOG_LEVEL configuration
  - Containerization with Docker and docker-compose for local development
  - Automated testing with RSpec and GitHub Actions CI
  - Optional integration with SimpleCov for coverage (local only)

- **In Progress**
  - Steam Web API integration
  - Implementation of game profile analysis logic
  - Steam API Key handling
  - Structured JSON output with real analysis
  - Full project roadmap

---

## 🛠️ Tech Stack

- [Ruby](https://www.ruby-lang.org/) (versione 3.3)
- [Sinatra](https://sinatrarb.com/)
- [RSpec](https://rspec.info/)
- [Docker](https://www.docker.com/) + [Docker Compose](https://docs.docker.com/compose/)
- [GitHub Actions](https://docs.github.com/en/actions)

---

## 🚀 Installation & Run

Clone the repo and start the project:

```bash
git clone https://github.com/gabr-moragarm/psy-mantis-engine.git
cd psy-mantis-engine
cp .env.example .env
docker compose up --build
```

The API will be available at http://localhost:`${HOST_PORT}` (default 4567).

---

## 📡 API Usage

### GET /analyze

Analyzes a Steam profile based on the provided steam_id.
Currently returns only a placeholder message.

Example request:

```bash
curl "http://localhost:4567/analyze?steam_id=123456789"
```

Example response:

```json
{
  "message": "Analysis for Steam ID 123456789 is not yet implemented."
}
```

---

## ⚙️ Environment Variables

| Variabile         | Default       | Description |
|-------------------|--------------|-------------|
| `LOG_LEVEL`       | `DEBUG`      | Log level (`DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`) |
| `RACK_ENV`        | `development`| Application environment |
| `HOST`            | `0.0.0.0`    | Application bind host |
| `CONTAINER_PORT`  | `4567`       | Internal container port |
| `HOST_PORT`       | `4567`       | Local exposed port |
| `COVERAGE`        | `false`      | Enables SimpleCov if `true` |

---

## 🧪 Tests

Run tests locally:

```bash
docker compose run --rm test
```

This runs RSpec in “documentation” format.
To enable SimpleCov, set `COVERAGE=true` in the `.env` file.

---

## 📅 Next Steps

- [ ] Steam Web API integration
- [ ] Game profile analysis & personalized report generation
- [ ] Steam API key handling
- [ ] Test coverage > 90% in CI
- [ ] Production container deployment

---

## 📄 License

This project is licensed under the [MIT](LICENSE).
You are free to use, copy, modify, and distribute it, provided that you retain the original attribution.
