# Microsoft.ARM.Evaluator

Check the blog article here: [blog.geuer-pollmann.de/blog/2019/10/14/locally-evaluating-azure-arm-templates](https://blog.geuer-pollmann.de/blog/2019/10/14/locally-evaluating-azure-arm-templates/) ...

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

sub = "724467b5-bee4-484b-bf13-d6a5505d2b51"

deploymentContext = %DeploymentContext{ subscriptionId: sub, resourceGroup: "longterm" } |> DeploymentContext.with_device_login(login_cred)

Resource.subscription([], Context.new() |> Context.with_deployment_context(deploymentContext))

"sample_files/1.json" |> DemoUtil.transform(deploymentContext, %{})

"sample_files/automation.json" |> DemoUtil.transform(deploymentContext, %{"adminPassword" => "SuperSecret123.-##"})
```

## Implementation Status

- [x] All numeric / logical / array&objects / comparison functions
- [x] Custom function definitions should work
- [ ] The `reference()` function needs more [dummy data](lib/evaluator/dummy_data.json) for scenarios where the users are not signed-in to their real subscription.
- [ ] The `copyIndex()` function currently doesn't duplicate nodes in the document.

## Other projects in that problem space

- Check [`ChrisLGardner/ArmTemplateValidation`](https://github.com/ChrisLGardner/ArmTemplateValidation) for a PowerShell-based implementation by [@HalbaradKenafin](https://twitter.com/HalbaradKenafin/).
