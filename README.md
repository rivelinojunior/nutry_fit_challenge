# Nutry.fit — Desafio

Mini webapp para criação de desafios focados em hábitos alimentares e exercícios.

Filosofia do produto:

> A vida não é fit... mas a gente tenta (juntos em comunidade).
> Básico bem feito, porque perfeição cansa.

---

## Objetivo do MVP

Permitir que um administrador crie um desafio com tarefas diárias pontuáveis, e que participantes:

* entrem no desafio
* marquem tarefas realizadas ao longo do dia
* acumulem pontos
* acompanhem um ranking simples

O foco é **comportamento consistente**, não perfeição.

---

## Escopo do MVP

### Inclui

* Criação de desafio (admin)
* Definição de tarefas com pontuação
* Geração de tarefas materializadas por dia
* Entrada de participantes (antes do início)
* Check-in diário de tarefas
* Ranking por desafio
* UI simples com Hotwire + DaisyUI

### Não inclui (por agora)

* Comentários
* Upload de fotos
* Ranking global
* Múltiplos desafios simultâneos
* Moderação / validação de ações
* Notificações
* Histórico detalhado

---

## Modelo de domínio

### Challenge

Representa o desafio.

* name
* description
* start_date
* end_date
* timezone (default: America/Sao_Paulo)
* status (draft | published)

Regras:

* editável enquanto `today < start_date`
* travado após início

---

### ChallengeTask (materializada)

Uma tarefa concreta em um dia específico.

* challenge_id
* name
* description
* points
* scheduled_on (date)
* start_time (optional)
* end_time (optional)

---

### User

Autenticação via Devise.

* name
* email
* password

---

### Participant

Usuário inscrito no desafio.

* user_id
* challenge_id
* joined_at

Regra:

* único por desafio (`user_id + challenge_id`)
* entrada permitida apenas antes do início

---

### Checkin

Registro de execução de uma tarefa.

* participant_id
* challenge_task_id
* checked_at (datetime)

Constraint:

* único por tarefa e partipante

---

## Arquitetura

### Stack

* Rails 8
* PostgreSQL
* Hotwire (Turbo)
* DaisyUI + Tailwind
* Devise
* RSpec + FactoryBot

---

### Estrutura

```
app/models/
app/controllers/
app/views/
app/processes/
app/jobs
```

---

### Padrão de lógica

A lógica de negócio fica em **processes** (inspirado em `Solid::Process`):

* entrada explícita
* dependências injetáveis
* retorno estruturado
* fácil de testar

Controllers são finos.

---

## Fluxos principais

### 1. Admin cria desafio

* define período
* define descrição
* publica

---

### 2. Admin define tarefas

* define nome e pontos
* define janela (opcional)
* define repetição (UI)
* sistema gera tarefas materializadas por dia

---

### 3. Participante entra

* cadastro via Devise
* entra antes do início

---

### 4. Check-in diário

* lista tarefas do dia
* marca ações
* pontos acumulados

---

### 5. Ranking

* visível durante e após o desafio
* atualizado por request (sem realtime)

---

## Setup local

```bash
git clone <repo>
cd nutry_fit_challenge

bundle install
yarn install

rails db:create
rails db:migrate
```

Rodar:

```bash
bin/dev
```

---

## Testes

```bash
bundle exec rspec
```

Foco:

* models
* processes
* requests

---

## Nome do produto

**Desafio Nutry.fit**

---
