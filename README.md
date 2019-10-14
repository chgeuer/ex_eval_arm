# Microsoft.ARM.Evaluator

# demo

```cmd
set iex_with_werl=
iex -S mix
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
