# Elixir Code Style Guide

## Goal

Write Elixir code that is:

1. **Readable** — the code explains what is happening and why.
2. **Maintainable** — new rules can be added without rewriting the whole module.
3. **Testable** — domain logic can be tested without databases, queues, APIs, email clients, or HTTP layers.
4. **Composable** — functions can be reused in different use cases without depending on a specific caller.
5. **Boundary-safe** — external data formats never leak deep into the domain.

This guide is especially useful for Phoenix, microservices, background jobs, PubSub consumers, and systems using hexagonal architecture / ports and adapters.

---

# 1. Architecture Rules

## 1.1 Separate domain logic from infrastructure

Keep the domain pure. Put external effects in adapters.

**Domain logic:**

* eligibility rules
* pricing rules
* validation rules
* capacity rules
* state transitions
* business decisions

**Infrastructure logic:**

* `Repo`
* HTTP controllers
* LiveViews
* Oban/Broadway jobs
* PubSub event handlers
* email/SMS/WhatsApp clients
* Stripe/Polar/API clients
* JSON parsing
* database schemas and persistence

### Bad

```elixir
def eligible?(event) do
  some_id = event["event_data"]["foo"]["some_id"]
  exists = ThirdPartyApi.exists?(some_id)

  if Repo.get(User, some_id) && exists do
    true
  else
    false
  end
end
```

The domain function knows about:

* event JSON shape
* third-party API
* database
* external field names

### Good

```elixir
def eligible?(%Eligibility{
      supported?: true,
      blocked?: false,
      already_exists?: false
    }) do
  true
end

def eligible?(_), do: false
```

The adapter prepares a clean domain struct. The domain only decides.

---

## 1.2 Primary adapters translate input into domain data

Primary adapters are entry points:

* HTTP controllers
* LiveViews
* PubSub handlers
* queue jobs
* CLI commands
* webhooks

Their job is to receive foreign data and translate it into your internal shape.

### Bad

```elixir
defmodule Billing.InvoiceEligibility do
  def eligible?(%{
        "customer" => %{
          "tax_id" => tax_id,
          "country" => country
        },
        "payment" => %{
          "amount" => amount
        }
      }) do
    country == "IT" and amount > 0 and tax_id != nil
  end
end
```

The domain depends on webhook payload structure.

### Good

```elixir
defmodule Billing.InvoiceRequest do
  defstruct [:tax_id, :country, :amount]
end

defmodule Billing.InvoiceEligibility do
  def eligible?(%Billing.InvoiceRequest{
        tax_id: tax_id,
        country: "IT",
        amount: amount
      })
      when is_binary(tax_id) and amount > 0 do
    true
  end

  def eligible?(_), do: false
end
```

Adapter:

```elixir
defmodule BillingWeb.StripeWebhookController do
  def create(conn, payload) do
    request = %Billing.InvoiceRequest{
      tax_id: get_in(payload, ["customer", "tax_id"]),
      country: get_in(payload, ["customer", "country"]),
      amount: get_in(payload, ["payment", "amount"])
    }

    Billing.InvoiceEligibility.eligible?(request)

    send_resp(conn, 200, "ok")
  end
end
```

---

## 1.3 Secondary adapters are called through ports

Secondary adapters are things your app drives:

* database
* payment APIs
* email
* SMS
* WhatsApp/Telegram
* storage
* search
* external REST APIs

Do not hard-code them deep inside business modules.

### Bad

```elixir
defmodule Accounts.RegisterUser do
  def call(params) do
    org = Repo.get!(Organisation, params.organisation_id)

    if Organisation.Capacity.enough_seats?(org, params.account_type) do
      user =
        %User{}
        |> User.changeset(params)
        |> Repo.insert!()

      EmailClient.send_welcome(user.email)

      {:ok, user}
    else
      {:error, :over_capacity}
    end
  end
end
```

### Good

```elixir
defmodule Accounts.RegisterUser do
  alias Accounts.OrganisationCapacity
  alias Accounts.UserParamsValidator

  @type get_org :: (String.t() -> {:ok, Organisation.t()} | {:error, atom()})
  @type insert_user :: (map(), Organisation.t() -> {:ok, User.t()} | {:error, atom()})
  @type send_welcome :: (User.t() -> :ok | {:error, term()})

  @spec call(map(), get_org(), insert_user(), send_welcome()) ::
          {:ok, User.t()} | {:error, term()}
  def call(params, get_org, insert_user, send_welcome) do
    with {:ok, :valid} <- UserParamsValidator.validate(params),
         {:ok, org} <- get_org.(params.organisation_id),
         :ok <- OrganisationCapacity.check(org, params.account_type),
         {:ok, user} <- insert_user.(params, org),
         :ok <- send_welcome.(user) do
      {:ok, user}
    end
  end
end
```

Production caller:

```elixir
Accounts.RegisterUser.call(
  params,
  &Accounts.Organisations.get/1,
  &Accounts.Users.insert/2,
  &Accounts.Emails.send_welcome/1
)
```

Test caller:

```elixir
get_org = fn _ -> {:ok, %Organisation{capacity: 10, used: 1}} end
insert_user = fn _, _ -> {:ok, %User{id: 1}} end
send_welcome = fn _ -> :ok end

assert {:ok, %User{id: 1}} =
         Accounts.RegisterUser.call(params, get_org, insert_user, send_welcome)
```

---

# 2. Module Design Rules

## 2.1 One module should have one reason to change

Split modules by responsibility, not by convenience.

### Bad

```elixir
defmodule Animals do
  def create_mammal, do: :todo
  def create_carnivorous, do: :todo

  def add_hat(animal), do: :todo
  def add_shirt(animal), do: :todo

  def get_picture(animal), do: :todo
  def send_picture_email(picture, email), do: :todo
  def send_picture_whatsapp(picture, number), do: :todo
end
```

This module changes when:

* animal creation changes
* clothing changes
* picture generation changes
* email sending changes
* WhatsApp sending changes

### Good

```elixir
defmodule Animals.Mammal do
  def create, do: :todo
end

defmodule Animals.Carnivorous do
  def create, do: :todo
end

defmodule Animals.Clothes do
  def add_hat(animal), do: :todo
  def add_shirt(animal), do: :todo
end

defmodule Animals.Pictures do
  def get(animal), do: :todo
end

defmodule Animals.PictureDelivery.Email do
  def send(picture, email), do: :todo
end

defmodule Animals.PictureDelivery.WhatsApp do
  def send(picture, number), do: :todo
end
```

---

## 2.2 Prefer small modules with domain names

A good module name should explain the business concept.

### Bad

```elixir
defmodule Utils do
  def check(user, org), do: :todo
end
```

### Good

```elixir
defmodule Organisations.Capacity do
  def check(org, account_type), do: :todo
end
```

---

## 2.3 Extract functions when logic has a name

If you need a comment to explain what a block does, often that block wants a function.

### Bad

```elixir
valid =
  case account_type do
    "basic" -> org.used + 1 <= org.capacity
    "pro" -> org.used + 2 <= org.capacity
    "elite" ->
      if org.grandfathered do
        org.used + 1 <= org.capacity
      else
        org.used + 3 <= org.capacity
      end
  end
```

### Good

```elixir
defmodule Organisations.Capacity do
  def check(org, account_type) do
    account_type
    |> required_seats(org.grandfathered)
    |> fits_capacity?(org.used, org.capacity)
    |> to_result()
  end

  defp required_seats("basic", _grandfathered?), do: 1
  defp required_seats("pro", _grandfathered?), do: 2

  # Grandfathered elite accounts only count as one seat.
  defp required_seats("elite", true), do: 1
  defp required_seats("elite", false), do: 3

  defp fits_capacity?(required, used, capacity), do: used + required <= capacity

  defp to_result(true), do: :ok
  defp to_result(false), do: {:error, :over_capacity}
end
```

Use comments for business history or non-obvious policy, not for explaining basic syntax.

---

# 3. Function Rules

## 3.1 Prefer multiple function clauses over nested conditionals

Pattern matching is one of Elixir’s best readability tools.

### Bad

```elixir
def eligible?(attrs) do
  if attrs.some_attribute do
    false
  else
    if attrs.some_other_attribute do
      false
    else
      if attrs.something_else == false do
        false
      else
        not attrs.exists_in_lorem_ipsum_foobar
      end
    end
  end
end
```

### Good

```elixir
def eligible?(%{some_attribute: true}), do: false
def eligible?(%{some_other_attribute: true}), do: false
def eligible?(%{something_else: false}), do: false
def eligible?(%{exists_in_lorem_ipsum_foobar: true}), do: false
def eligible?(%{some_id: some_id}), do: is_lorem_ipsum(some_id)
```

This reads like a list of business rules.

---

## 3.2 Do not prefix boolean functions with `is_` unless used in guards

In Elixir, `is_*` names are normally associated with guard-safe checks.

### Avoid

```elixir
def is_foobar_eligible(attrs), do: ...
```

### Prefer

```elixir
def foobar_eligible?(attrs), do: ...
def eligible?(attrs), do: ...
def supported?(attrs), do: ...
```

---

## 3.3 Return meaningful tagged tuples instead of naked booleans

Booleans often push interpretation to the caller.

### Bad

```elixir
def has_capacity?(org, account_type) do
  ...
end
```

Caller:

```elixir
case has_capacity?(org, type) do
  true -> create_user()
  false -> {:error, :over_capacity}
end
```

### Good

```elixir
def check_capacity(org, account_type) do
  if enough_seats?(org, account_type) do
    :ok
  else
    {:error, :over_capacity}
  end
end
```

Caller:

```elixir
with :ok <- check_capacity(org, type),
     {:ok, user} <- create_user(params) do
  {:ok, user}
end
```

---

## 3.4 Keep return shapes consistent

Avoid functions that sometimes return atoms, sometimes tuples, sometimes structs, sometimes booleans.

### Bad

```elixir
def find_user(id) do
  case Repo.get(User, id) do
    nil -> false
    user -> user
  end
end
```

### Good

```elixir
def find_user(id) do
  case Repo.get(User, id) do
    nil -> {:error, :not_found}
    user -> {:ok, user}
  end
end
```

---

## 3.5 Keep functions small enough to test without a story

If testing one function requires setting up:

* database records
* email client
* HTTP mocks
* PubSub events
* background jobs
* three different schemas

then the function is probably doing too much.

Extract the pure part first.

---

# 4. `with`, Pipes, and Control Flow

## 4.1 Use `with` for multi-step workflows

Use `with` when each step can fail and the next step should only run on success.

### Bad

```elixir
case validate(params) do
  {:ok, params} ->
    case get_org(params.org_id) do
      {:ok, org} ->
        case check_capacity(org, params.type) do
          :ok ->
            insert_user(params, org)

          error ->
            error
        end

      error ->
        error
    end

  error ->
    error
end
```

### Good

```elixir
with {:ok, params} <- validate(params),
     {:ok, org} <- get_org(params.org_id),
     :ok <- check_capacity(org, params.type),
     {:ok, user} <- insert_user(params, org) do
  {:ok, user}
end
```

---

## 4.2 Avoid complex `else` blocks in `with`

If your `else` block becomes a second workflow, extract functions or normalize errors earlier.

### Bad

```elixir
with {:ok, user} <- get_user(id),
     {:ok, invoice} <- create_invoice(user) do
  {:ok, invoice}
else
  nil ->
    {:error, :not_found}

  {:error, :stripe_failed, reason} ->
    Logger.error("Stripe failed: #{inspect(reason)}")
    {:error, :payment_failed}

  {:error, reason} when is_binary(reason) ->
    {:error, String.to_atom(reason)}
end
```

### Better

```elixir
with {:ok, user} <- fetch_user(id),
     {:ok, invoice} <- create_invoice(user) do
  {:ok, invoice}
end
```

Normalize inside the called functions:

```elixir
def fetch_user(id) do
  case Repo.get(User, id) do
    nil -> {:error, :not_found}
    user -> {:ok, user}
  end
end
```

---

## 4.3 Use pipes for transformations, not orchestration

Pipes are best when one data structure is transformed step by step.

### Good pipe

```elixir
params
|> normalize_email()
|> trim_name()
|> cast_to_user_attrs()
```

### Bad pipe

```elixir
params
|> validate()
|> get_organisation()
|> check_capacity()
|> insert_user()
|> send_welcome_email()
```

This forces each function to return the exact shape needed by the next function, making the functions less reusable.

Use `with` instead.

---

## 4.4 Prefer pattern matching over manual extraction

### Bad

```elixir
def process(attrs) do
  id = attrs["id"]
  amount = attrs["amount"]

  if is_integer(id) and is_integer(amount) do
    {:ok, id, amount}
  else
    {:error, :invalid}
  end
end
```

### Good

```elixir
def process(%{"id" => id, "amount" => amount})
    when is_integer(id) and is_integer(amount) do
  {:ok, id, amount}
end

def process(_), do: {:error, :invalid}
```

---

# 5. Boundary and Adapter Rules

## 5.1 Do not leak external map keys into the domain

External payloads often use string keys, nested JSON, weird naming, or third-party abstractions.

Translate them once.

### Bad

```elixir
def eligible?(%{
      event_data: %{
        "event_data_we_are_interested" => %{
          "foo" => %{"some_id" => some_id},
          "bar" => %{"some_attribute" => some_attribute}
        }
      }
    }) do
  some_id > 0 and some_attribute == 2
end
```

### Good

```elixir
defmodule FoobarEligibility.Input do
  defstruct [
    :some_id,
    :some_attribute,
    :some_other_attribute,
    :something_else?,
    :exists_in_lorem_ipsum_foobar?
  ]
end
```

Adapter:

```elixir
defmodule FoobarEligibility.Mapper do
  alias FoobarEligibility.Input

  def from_event(event, exists_result, something_else?) do
    foo = get_in(event, [:event_data, "event_data_we_are_interested", "foo"])
    bar = get_in(event, [:event_data, "event_data_we_are_interested", "bar"])

    %Input{
      some_id: foo["some_id"],
      some_attribute: bar["some_attribute"],
      some_other_attribute: foo["some_other_attribute"],
      something_else?: something_else?,
      exists_in_lorem_ipsum_foobar?: exists_result["exists"]
    }
  end
end
```

Domain:

```elixir
defmodule FoobarEligibility do
  alias FoobarEligibility.Input

  def eligible?(%Input{some_attribute: 2}), do: false
  def eligible?(%Input{some_other_attribute: 2}), do: false
  def eligible?(%Input{something_else?: false}), do: false
  def eligible?(%Input{exists_in_lorem_ipsum_foobar?: true}), do: false
  def eligible?(%Input{some_id: some_id}), do: LoremIpsum.lorem_ipsum?(some_id)
end
```

---

## 5.2 Controllers should not contain business logic

Phoenix controllers should:

* parse request
* call application service
* convert result to HTTP response

### Bad

```elixir
def create(conn, params) do
  if params["email"] && params["password"] do
    org = Repo.get!(Organisation, params["organisation_id"])

    if org.used < org.capacity do
      {:ok, user} = Accounts.create_user(params)
      json(conn, %{id: user.id})
    else
      send_resp(conn, 422, "over capacity")
    end
  else
    send_resp(conn, 400, "invalid params")
  end
end
```

### Good

```elixir
def create(conn, params) do
  case Accounts.register_user(params) do
    {:ok, user} ->
      json(conn, %{id: user.id})

    {:error, :invalid_params} ->
      send_resp(conn, 400, "invalid params")

    {:error, :over_capacity} ->
      send_resp(conn, 422, "over capacity")
  end
end
```

---

## 5.3 Jobs should not contain business logic

### Bad

```elixir
def perform(%Oban.Job{args: %{"invoice_id" => id}}) do
  invoice = Repo.get!(Invoice, id)

  if invoice.status == "paid" and invoice.sent_at == nil do
    Provider.send_invoice(invoice)
    Repo.update!(Invoice.sent(invoice))
  end
end
```

### Good

```elixir
def perform(%Oban.Job{args: %{"invoice_id" => id}}) do
  Billing.SendInvoice.call(id)
end
```

The job is only an adapter.

---

# 6. Dependency Rules

## 6.1 Dependencies point inward

Inner modules should not know outer modules.

### Bad

```elixir
defmodule Billing.InvoiceRules do
  alias MyApp.Repo
  alias MyApp.External.FattureInCloud

  def sendable?(invoice_id) do
    invoice = Repo.get!(Invoice, invoice_id)
    FattureInCloud.available?() and invoice.status == :paid
  end
end
```

### Good

```elixir
defmodule Billing.InvoiceRules do
  def sendable?(%Invoice{status: :paid, sent_at: nil}), do: true
  def sendable?(_), do: false
end
```

The application layer fetches the invoice and checks provider availability.

---

## 6.2 Use behaviours when modules share a contract

Use behaviours for adapters, strategies, plugins, providers, classifiers, delivery channels, storage backends, etc.

### Behaviour

```elixir
defmodule Messaging.DeliveryChannel do
  @callback send_message(
              recipient :: String.t(),
              body :: String.t()
            ) :: :ok | {:error, term()}
end
```

### Implementation

```elixir
defmodule Messaging.DeliveryChannel.WhatsApp do
  @behaviour Messaging.DeliveryChannel

  @impl Messaging.DeliveryChannel
  def send_message(recipient, body) do
    # call WhatsApp adapter
    :ok
  end
end
```

### Caller

```elixir
defmodule Messaging.SendNotification do
  @spec call(module(), String.t(), String.t()) :: :ok | {:error, term()}
  def call(channel, recipient, body) do
    channel.send_message(recipient, body)
  end
end
```

---

## 6.3 Use explicit `@impl BehaviourName`

Prefer this:

```elixir
@impl Messaging.DeliveryChannel
def send_message(recipient, body), do: :ok
```

Over this:

```elixir
@impl true
def send_message(recipient, body), do: :ok
```

Explicit `@impl SomeBehaviour` is easier to navigate when a module implements multiple behaviours.

---

## 6.4 Use dependency injection for lightweight orchestration

For pure application services, passing functions can be cleaner than building a behaviour for everything.

### Good

```elixir
def call(params, get_org, insert_user, send_welcome) do
  with {:ok, org} <- get_org.(params.org_id),
       {:ok, user} <- insert_user.(params, org),
       :ok <- send_welcome.(user) do
    {:ok, user}
  end
end
```

Use this when:

* the dependency is simple
* you want fast unit tests
* the function is application orchestration
* you do not need a full plugin system

Use behaviours when:

* multiple modules implement the same adapter contract
* you want compile-time callback checks
* the abstraction is part of your public architecture

---

# 7. SOLID in Elixir

SOLID was created around OOP, but the ideas map well to Elixir.

## 7.1 Single Responsibility

One module should have one reason to change.

```elixir
Animals.Mammal.create()
Animals.Clothes.add_hat(animal)
Animals.Pictures.get(animal)
```

Better than one giant `Animals` module.

---

## 7.2 Open/Closed

Open for extension, closed for modification.

### Bad

```elixir
def send_picture_email(picture, email), do: :todo
def send_picture_whatsapp(picture, number), do: :todo
def send_picture_telegram(picture, chat_id), do: :todo
```

Each new channel modifies the same module.

### Good

```elixir
defmodule Pictures.DeliveryChannel do
  @callback send(Picture.t(), String.t()) :: :ok | {:error, term()}
end

defmodule Pictures.EmailDelivery do
  @behaviour Pictures.DeliveryChannel

  @impl Pictures.DeliveryChannel
  def send(picture, email), do: :todo
end

defmodule Pictures.WhatsAppDelivery do
  @behaviour Pictures.DeliveryChannel

  @impl Pictures.DeliveryChannel
  def send(picture, number), do: :todo
end
```

---

## 7.3 Interface Segregation

Prefer small specific behaviours over one giant behaviour.

### Bad

```elixir
defmodule Provider do
  @callback send_email(term()) :: term()
  @callback send_sms(term()) :: term()
  @callback create_invoice(term()) :: term()
  @callback refund_payment(term()) :: term()
end
```

### Good

```elixir
defmodule EmailProvider do
  @callback send_email(Email.t()) :: :ok | {:error, term()}
end

defmodule SmsProvider do
  @callback send_sms(Sms.t()) :: :ok | {:error, term()}
end

defmodule InvoiceProvider do
  @callback create_invoice(Invoice.t()) :: {:ok, Invoice.t()} | {:error, term()}
end
```

---

## 7.4 Liskov Substitution through behaviours

Any module implementing a behaviour should be usable without the caller knowing which implementation it is.

```elixir
defmodule Clothes.Clothing do
  @callback add(Animal.t()) :: Animal.t()
end

defmodule Clothes.Hat do
  @behaviour Clothes.Clothing

  @impl Clothes.Clothing
  def add(animal), do: %{animal | clothes: [:hat | animal.clothes]}
end

defmodule Clothes.Shirt do
  @behaviour Clothes.Clothing

  @impl Clothes.Clothing
  def add(animal), do: %{animal | clothes: [:shirt | animal.clothes]}
end

defmodule Clothes do
  def apply(animal, clothing_module) do
    clothing_module.add(animal)
  end
end
```

---

## 7.5 Dependency Inversion

Depend on abstractions, not concrete modules.

### Bad

```elixir
def apply(animal, :hat), do: Clothes.Hat.add(animal)
def apply(animal, :shirt), do: Clothes.Shirt.add(animal)
```

### Good

```elixir
def apply(animal, clothing_module) do
  clothing_module.add(animal)
end
```

---

# 8. Refactoring Rules

## 8.1 Refactor without changing behavior

A refactor should preserve existing functionality.

Safe refactoring process:

1. Add or strengthen tests.
2. Extract one function.
3. Run tests.
4. Extract one module.
5. Run tests.
6. Normalize return values.
7. Run tests.
8. Move infrastructure outward.
9. Run tests.

Never mix behavior changes and refactoring in the same commit unless the change is tiny and obvious.

---

## 8.2 Use method/function decomposition

When a function contains several ideas, extract them.

### Bad

```elixir
def register_user(params) do
  # validate params
  # fetch org
  # check capacity
  # insert user
  # send email
end
```

### Good

```elixir
def register_user(params) do
  with {:ok, params} <- validate_user_params(params),
       {:ok, org} <- fetch_organisation(params),
       :ok <- ensure_capacity(org, params),
       {:ok, user} <- create_user(params, org),
       :ok <- send_welcome(user) do
    {:ok, user}
  end
end
```

---

## 8.3 Replace nested branches with pattern matching

### Bad

```elixir
case user do
  nil ->
    {:error, :not_found}

  user ->
    if user.active do
      {:ok, user}
    else
      {:error, :inactive}
    end
end
```

### Good

```elixir
def validate_user(nil), do: {:error, :not_found}
def validate_user(%User{active: false}), do: {:error, :inactive}
def validate_user(%User{} = user), do: {:ok, user}
```

---

## 8.4 Replace repeated literals with module attributes

### Bad

```elixir
Enum.all?(["name", "email", "password", "organisation_id"], &Map.has_key?(params, &1))
```

### Good

```elixir
defmodule UserParamsValidator do
  @required_fields ~w(name email password organisation_id)a

  def validate(params) do
    if Enum.all?(@required_fields, &Map.has_key?(params, &1)) do
      {:ok, :valid}
    else
      {:error, :invalid_params}
    end
  end
end
```

---

## 8.5 Move duplicated logic into one named function

### Bad

```elixir
def create_basic(org), do: org.used + 1 <= org.capacity
def create_pro(org), do: org.used + 2 <= org.capacity
def create_elite(org), do: org.used + 3 <= org.capacity
```

### Good

```elixir
def can_add_account?(org, account_type) do
  required = required_seats(account_type, org.grandfathered)
  org.used + required <= org.capacity
end
```

---

## 8.6 Expand grouped aliases for grepability

Grouped aliases are compact but harder to search and refactor.

### Avoid

```elixir
alias Billing.{Invoice, Customer, Provider}
```

### Prefer

```elixir
alias Billing.Invoice
alias Billing.Customer
alias Billing.Provider
```

This makes `alias Billing.Customer` searchable.

---

## 8.7 Avoid alias shortcuts with `as:` unless there is a strong reason

### Avoid

```elixir
alias Billing.Invoice.Provider.FattureInCloud, as: FIC
```

### Prefer

```elixir
alias Billing.Invoice.Provider.FattureInCloud
```

Then use:

```elixir
FattureInCloud.create_invoice(invoice)
```

Use shortcuts only for very long names that are repeated heavily and where the shortcut is obvious across the project.

---

## 8.8 Prefer explicit module names over cleverness

Code is read more than written.

### Avoid

```elixir
B.create(i)
```

### Prefer

```elixir
FattureInCloud.create_invoice(invoice)
```

---

# 9. Data Rules

## 9.1 Prefer structs for internal domain data

Maps are fine at boundaries. Structs are better inside the domain.

### Bad

```elixir
%{
  some_id: 123,
  some_attribute: 2,
  something_else: true
}
```

### Good

```elixir
defmodule FoobarEligibility.Input do
  @enforce_keys [:some_id, :some_attribute]
  defstruct [
    :some_id,
    :some_attribute,
    :some_other_attribute,
    :something_else?,
    :exists_in_lorem_ipsum_foobar?
  ]
end
```

---

## 9.2 Use `@enforce_keys` for required struct fields

```elixir
defmodule Invoice do
  @enforce_keys [:id, :amount, :currency]
  defstruct [:id, :amount, :currency, :sent_at]
end
```

This prevents half-valid domain data from being created accidentally.

---

## 9.3 Avoid accessing fields that may not exist

### Bad

```elixir
def paid?(invoice), do: invoice.status == :paid
```

If `invoice` is a map without `:status`, this can fail or behave unexpectedly.

### Better

```elixir
def paid?(%Invoice{status: :paid}), do: true
def paid?(%Invoice{}), do: false
```

---

## 9.4 Normalize external data once

### Bad

```elixir
def process(payload) do
  amount = payload["amount"] || payload[:amount]
  email = payload["customer"]["email"] || payload[:customer][:email]

  ...
end
```

### Good

```elixir
defmodule PaymentMapper do
  def from_stripe(payload) do
    %Payment{
      amount: payload["amount"],
      email: get_in(payload, ["customer", "email"])
    }
  end
end
```

---

# 10. Naming Rules

## 10.1 Name functions after business meaning

### Bad

```elixir
def check(data), do: ...
def process(params), do: ...
def handle(input), do: ...
```

### Good

```elixir
def eligible_for_invoice?(payment), do: ...
def check_capacity(organisation, account_type), do: ...
def register_user(params), do: ...
def send_welcome_email(user), do: ...
```

---

## 10.2 Use `?` for predicates

```elixir
active?(user)
paid?(invoice)
over_capacity?(organisation)
eligible?(request)
```

---

## 10.3 Use command names for side-effect functions

```elixir
send_email(email)
insert_user(params)
publish_event(event)
enqueue_job(args)
```

Do not hide side effects behind harmless names.

### Bad

```elixir
def welcome(user), do: EmailClient.send(...)
```

### Good

```elixir
def send_welcome_email(user), do: EmailClient.send(...)
```

---

# 11. Typespec and Documentation Rules

## 11.1 Add `@spec` to public functions

Typespecs improve readability and make contracts explicit.

```elixir
@spec register_user(user_params()) :: {:ok, User.t()} | {:error, term()}
def register_user(params), do: ...
```

---

## 11.2 Define custom types for important domain concepts

```elixir
@type user_params :: %{
        required(:name) => String.t(),
        required(:email) => String.t(),
        required(:password) => String.t(),
        required(:organisation_id) => String.t()
      }
```

---

## 11.3 Use `@moduledoc` for module purpose

```elixir
defmodule Organisations.Capacity do
  @moduledoc """
  Checks whether an organisation has enough remaining seats for a new account.

  This module contains pure business rules and does not access the database.
  """
end
```

---

## 11.4 Use comments for business exceptions

Comments are valid when they explain why a rule exists.

```elixir
# Grandfathered elite accounts were sold under the old pricing model,
# so they consume only one seat instead of three.
defp required_seats("elite", true), do: 1
```

Avoid comments that only repeat the code.

---

# 12. Testing Rules

## 12.1 Test pure domain modules without infrastructure

### Good

```elixir
test "basic account fits when one seat is available" do
  org = %Organisation{used: 9, capacity: 10, grandfathered: false}

  assert :ok = Organisations.Capacity.check(org, "basic")
end
```

No database needed.

---

## 12.2 Use injected functions to test orchestration

```elixir
test "returns error when organisation cannot be found" do
  params = valid_params()

  get_org = fn _ -> {:error, :org_not_found} end
  insert_user = fn _, _ -> flunk("should not insert user") end
  send_welcome = fn _ -> flunk("should not send email") end

  assert {:error, :org_not_found} =
           RegisterUser.call(params, get_org, insert_user, send_welcome)
end
```

---

## 12.3 Keep integration tests for wiring

Unit tests should cover domain edge cases.

Integration tests should check:

* Repo wiring
* external adapter wiring
* API payload mapping
* controller responses
* job execution

Do not force every edge case through full infrastructure.

---

# 13. Enumeration Rules

## 13.1 Use comprehensions when they read clearer

### Good

```elixir
for i <- 0..3, do: i
```

### Also fine

```elixir
Enum.map(0..3, & &1)
```

Use comprehensions when generating or filtering combinations.

```elixir
for user <- users,
    user.active?,
    invoice <- user.invoices,
    invoice.status == :paid do
  invoice
end
```

Use `Enum` when the operation name communicates intent better:

```elixir
Enum.group_by(invoices, & &1.customer_id)
Enum.reduce(items, 0, fn item, acc -> item.price + acc end)
```

---

# 14. Error Handling Rules

## 14.1 Prefer explicit domain errors

### Bad

```elixir
:error
```

### Good

```elixir
{:error, :invalid_params}
{:error, :over_capacity}
{:error, :not_found}
{:error, :provider_unavailable}
```

---

## 14.2 Do not leak provider errors into the domain

### Bad

```elixir
{:error, %HTTPoison.Error{reason: :timeout}}
```

### Good

```elixir
{:error, :provider_timeout}
```

Adapter:

```elixir
def create_invoice(invoice) do
  case HTTPoison.post(...) do
    {:ok, response} -> decode_response(response)
    {:error, %HTTPoison.Error{reason: :timeout}} -> {:error, :provider_timeout}
    {:error, reason} -> {:error, {:provider_failed, reason}}
  end
end
```

---

# 15. Practical Refactoring Example

## Before

```elixir
defmodule Apply.ApplicationsProcessing.FoobarEligibility do
  import Apply.ApplicationsProcessing.LoremIpsum

  def is_foobar_eligible(
        %{
          event_data: %{
            "event_data_we_are_interested" => %{
              "foo" =>
                %{
                  "some_id" => some_id
                } = foo,
              "bar" => %{
                "some_attribute" => some_attribute
              }
            }
          },
          exists_at_loremipsum: exists_at_loremipsum_result
        },
        something_else
      )
      when is_integer(some_attribute) and is_integer(some_id) do
    is_lorem_ipsum = is_lorem_ipsum(some_id)

    exists_in_lorem_ipsum_foobar =
      case is_lorem_ipsum do
        false -> false
        true -> exists_at_loremipsum_result["exists"]
      end

    is_supported_foobar = is_lorem_ipsum

    case is_supported_foobar do
      false ->
        false

      true ->
        some_other_attribute = foo["some_other_attribute"]
        not_some_attribute = some_attribute == 2
        not_some_other_attribute = some_other_attribute == 2

        not_some_attribute &&
          not_some_other_attribute &&
          something_else &&
          !exists_in_lorem_ipsum_foobar
    end
  end
end
```

## Problems

* External event shape leaks into the domain.
* Function does parsing, checking, external lookup, and business rules.
* Boolean names are confusing.
* Nested conditionals hide the rule list.
* Hard to test without building a full external event payload.
* `is_foobar_eligible` should be `foobar_eligible?` or `eligible?`.

## After

```elixir
defmodule Apply.ApplicationsProcessing.FoobarEligibility.Input do
  @enforce_keys [:some_id]
  defstruct [
    :some_id,
    some_attribute_blocked?: false,
    some_other_attribute_blocked?: false,
    something_else?: false,
    exists_in_lorem_ipsum_foobar?: false
  ]
end
```

```elixir
defmodule Apply.ApplicationsProcessing.FoobarEligibility do
  alias Apply.ApplicationsProcessing.FoobarEligibility.Input
  alias Apply.ApplicationsProcessing.LoremIpsum

  @spec eligible?(Input.t()) :: boolean()
  def eligible?(%Input{some_attribute_blocked?: true}), do: false
  def eligible?(%Input{some_other_attribute_blocked?: true}), do: false
  def eligible?(%Input{something_else?: false}), do: false
  def eligible?(%Input{exists_in_lorem_ipsum_foobar?: true}), do: false

  def eligible?(%Input{some_id: some_id}) do
    LoremIpsum.lorem_ipsum?(some_id)
  end
end
```

```elixir
defmodule Apply.ApplicationsProcessing.FoobarEligibility.Mapper do
  alias Apply.ApplicationsProcessing.FoobarEligibility.Input

  def from_event(event, exists_result, something_else?) do
    foo = get_in(event, [:event_data, "event_data_we_are_interested", "foo"])
    bar = get_in(event, [:event_data, "event_data_we_are_interested", "bar"])

    %Input{
      some_id: foo["some_id"],
      some_attribute_blocked?: bar["some_attribute"] == 2,
      some_other_attribute_blocked?: foo["some_other_attribute"] == 2,
      something_else?: something_else?,
      exists_in_lorem_ipsum_foobar?: exists_result["exists"] == true
    }
  end
end
```

Now:

* the mapper knows the external event
* the domain knows only clean internal data
* each business rule is a function clause
* the code is easier to extend
* tests can call `eligible?/1` with a small struct

---

# 16. Project-Level Checklist

Before merging Elixir code, check:

## Architecture

* [ ] Does the domain avoid `Repo`, HTTP clients, email clients, queues, and PubSub?
* [ ] Are external payloads mapped at the boundary?
* [ ] Are adapters thin?
* [ ] Do dependencies point inward?

## Modules

* [ ] Does each module have one responsibility?
* [ ] Is the module name a real domain concept?
* [ ] Is there any `Utils`, `Helpers`, or `Manager` module that should be split?

## Functions

* [ ] Is the function small enough to test easily?
* [ ] Are nested `case` / `if` blocks replaceable with pattern matching?
* [ ] Are return values consistent?
* [ ] Are errors explicit?
* [ ] Are boolean functions named with `?`?

## Flow

* [ ] Is `with` used for multi-step failure workflows?
* [ ] Are pipes used only for clean transformations?
* [ ] Is the `with else` block simple?

## Dependencies

* [ ] Should this dependency be injected?
* [ ] Should this adapter use a behaviour?
* [ ] Are `@impl` declarations explicit?

## Style

* [ ] Are aliases expanded instead of grouped?
* [ ] Are alias shortcuts avoided?
* [ ] Are public functions documented with `@spec`?
* [ ] Are comments explaining business decisions, not syntax?

## Testing

* [ ] Can business rules be tested without DB/API setup?
* [ ] Are infrastructure tests separated from domain tests?
* [ ] Are edge cases tested at the cheapest possible layer?

---

# 17. Final Rule

Elixir code is clean when a future developer can add one more business rule without touching five unrelated things.

Good Elixir should feel like this:

```elixir
def eligible?(%Request{blocked?: true}), do: false
def eligible?(%Request{expired?: true}), do: false
def eligible?(%Request{already_used?: true}), do: false
def eligible?(%Request{}), do: true
```

Not like this:

```elixir
def eligible?(payload) do
  # parse JSON
  # fetch DB
  # call API
  # inspect nested maps
  # branch 7 times
  # return true or false
end
```

Push foreign details outward. Pull business meaning inward.
