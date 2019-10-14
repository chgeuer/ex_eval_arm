# Microsoft.ARM.Evaluator

## How to install

- Install Erlang from [erlang.org](https://www.erlang.org/downloads)
- Install Elixir from [elixir-lang.org](https://elixir-lang.org/install.html)

### Clone the code

```bash
git clone https://github.com/chgeuer/ex_microsoft_arm_evaluator
cd ex_microsoft_arm_evaluator
```

### Fetch required Elixir packages

```bash
mix deps.get
```

### Compile the whole thing

```bash
mix compile
```

### On Windows, set this env variable

```cmd
set iex_with_werl=true
```

### Launch the interactive Elixir shell

```bash
iex -S mix
```

## demo time

```cmd
start https://microsoft.com/devicelogin
```

```elixir
alias Microsoft.Azure.TemplateLanguageExpressions.{Resource, Context, DeploymentContext, Evaluator.Resource}

login_cred = DemoUtil.login()

deploymentContext = %DeploymentContext{ subscriptionId: "724467b5-bee4-484b-bf13-d6a5505d2b51", resourceGroup: "longterm" } |> DeploymentContext.with_device_login(login_cred)

Resource.subscription([], Context.new() |> Context.with_deployment_context(deploymentContext))

~S"C:\Users\chgeuer\Desktop\f\1.json" |> DemoUtil.transform(deploymentContext, %{})

~S"C:\Users\chgeuer\Desktop\automation\templates\azuretemplate.json" |> DemoUtil.transform(deploymentContext, %{"adminPassword" => "SuperSecret123.-##"})
```
