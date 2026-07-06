# GraphQL Learning Notes

## What is GraphQL?

GraphQL is a query language for APIs.

Instead of multiple endpoints like REST, GraphQL exposes a **single endpoint** (`/graphql`) where the client specifies exactly what data it needs.

---

# REST vs GraphQL

| REST | GraphQL |
|------|----------|
| Multiple endpoints | Single endpoint |
| GET / POST / PATCH / DELETE | query / mutation |
| Server decides response | Client decides response fields |
| Can over-fetch | Returns only requested fields |

---

# GraphQL Architecture

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

# Schema

The Schema is the entry point of the GraphQL API.

Responsibilities:

- Starts GraphQL execution
- Registers QueryType
- Registers MutationType
- Validates incoming GraphQL requests

Example

```ruby
class GraphqlLearningSchema < GraphQL::Schema
  query Types::QueryType
  mutation Types::MutationType
end
```

---

# QueryType

Contains all read operations.

Example

```ruby
field :users, [Types::UserType], null: false

def users
  User.all
end
```

Responsibilities:

- Define available queries
- Accept arguments
- Fetch data through resolvers

---

# MutationType

Contains all write operations.

Examples:

- Create
- Update
- Delete

Instead of resolver methods, each mutation delegates execution to its own mutation class.

Example

```ruby
field :create_user, mutation: Mutations::CreateUser
```

---

# GraphQL Types

Types define the structure of the response.

Example

```ruby
field :id, ID, null: false
field :name, String, null: false
field :email, String, null: false
```

Types expose only the fields that clients are allowed to request.

---

# Query Resolver

Resolvers fetch data.

Example

```ruby
def users
  User.all
end
```

---

# Mutation resolve()

The `resolve` method executes business logic.

Example

```ruby
def resolve(name:, email:)
```

Responsibilities:

- Create records
- Update records
- Delete records
- Return response

---

# Arguments

Arguments define input accepted from the client.

Example

```ruby
argument :email, String, required: true
```

---

# Fields

Fields define output returned to the client.

Example

```ruby
field :user, Types::UserType
field :errors, [String]
```

---

# required: true

Used for arguments.

Meaning:

The client must provide the argument.

Example

```ruby
argument :email, String, required: true
```

---

# null: false

Used for fields.

Meaning:

The resolver must not return `nil`.

Example

```ruby
field :user, Types::UserType, null: false
```

---

# Why GraphQL Types?

Resolvers return Ruby objects.

Example

```ruby
User.all
```

GraphQL checks the field definition.

```ruby
field :users, [Types::UserType]
```

It serializes every ActiveRecord object using `UserType`.

Only requested fields are returned in the response.

---

# Why Mutations Return Hashes?

Example

```ruby
{
  user: user,
  errors: []
}
```

Mutations usually return:

- Result object
- Validation errors

This provides useful feedback to clients when an operation fails.

---

# Basic Error Handling

Example

```ruby
if user.save
  {
    user: user,
    errors: []
  }
else
  {
    user: nil,
    errors: user.errors.full_messages
  }
end
```

Successful response:

```json
{
  "user": {
    "id": "1",
    "name": "Alice"
  },
  "errors": []
}
```

Failed response:

```json
{
  "user": null,
  "errors": [
    "Email has already been taken"
  ]
}
```

---

# GraphQL Request Lifecycle

1. Client sends a GraphQL request.
2. Request reaches `/graphql`.
3. Rails routes it to `GraphqlController`.
4. Controller executes `GraphqlLearningSchema`.
5. Schema identifies whether the operation is a Query or Mutation.
6. Query → `QueryType`
7. Mutation → `MutationType`
8. Resolver or `resolve()` executes business logic.
9. ActiveRecord interacts with the database.
10. GraphQL Types serialize Ruby objects.
11. GraphQL returns a JSON response.

---

# Key Takeaways

- GraphQL exposes a single endpoint.
- Schema is the entry point of GraphQL.
- QueryType handles read operations.
- MutationType handles write operations.
- Types define the API response.
- Arguments define client input.
- Fields define server output.
- Resolvers contain business logic.
- GraphQL serializes Ruby objects using GraphQL Types.
- GraphiQL is useful for testing GraphQL APIs.
