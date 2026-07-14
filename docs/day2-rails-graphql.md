# Day 2 – Ruby on Rails API with GraphQL

> Part of my **Incubyte COE Learning Journey**

## Overview

The objective of this module was to build a **Ruby on Rails API-only application** integrated with **GraphQL** and understand how GraphQL works internally.

This project covers GraphQL fundamentals, including Schema, Types, Queries, Resolvers, Mutations, and testing APIs using GraphiQL.

---

## Learning Objectives

- Understand Rails API-only architecture
- Integrate GraphQL with Rails
- Learn GraphQL fundamentals
- Define GraphQL Types
- Implement Queries and Resolvers
- Implement CRUD Mutations
- Handle basic validation errors
- Test GraphQL APIs using GraphiQL

---

## Tech Stack

- Ruby
- Ruby on Rails (API Only)
- GraphQL
- PostgreSQL
- GraphiQL

---

## Getting Started

```bash
git clone https://github.com/HarshKIncubyte/graphql-learning.git
cd graphql-learning
bundle install
rails db:create db:migrate
rails server
```

Visit `http://localhost:3000/graphiql` to explore the API.

---

## Models

### User

- id
- name
- email

### Post

- id
- title
- published

### Associations

- A User has many Posts
- A Post belongs to a User

---

## GraphQL Features Implemented

### Types

- UserType
- PostType

### Queries

- Fetch all users
- Fetch a single user by ID
- Fetch all posts
- Filter posts by published status

### Mutations

- Create User
- Update User
- Delete User

### Basic Error Handling

Mutation responses include validation errors when an operation fails.

Example:

```json
{
  "user": null,
  "errors": [
    "Email has already been taken"
  ]
}
```

---

## Sample Query

```graphql
query {
  users {
    id
    name
    email
    posts {
      title
      published
    }
  }
}
```

---

## Sample Mutation

```graphql
mutation {
  createUser(
    input: {
      name: "Alice"
      email: "alice@example.com"
    }
  ) {
    user {
      id
      name
      email
    }
    errors
  }
}
```

---

## GraphQL Request Flow

```text
Client
   │
   ▼
POST /graphql
   │
   ▼
GraphqlController
   │
   ▼
GraphQL Schema
   │
   ├───────────────┐
   ▼               ▼
QueryType      MutationType
   │               │
   ▼               ▼
Resolver      resolve()
   │
   ▼
ActiveRecord Models
   │
   ▼
GraphQL Types
   │
   ▼
JSON Response
```

---

## Key Learnings

- Built a Rails API-only application using GraphQL.
- Understood the role of GraphQL Schema.
- Learned how GraphQL Types define API responses.
- Implemented Queries and Resolvers.
- Implemented CRUD Mutations.
- Understood the difference between QueryType and MutationType.
- Learned how GraphQL serializes Ruby objects into JSON.
- Tested GraphQL APIs using GraphiQL.
