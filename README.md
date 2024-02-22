## ExAuth

ExAuth is a library that serves to integrate your project the fastest way possible with AUTH application. AUTH is a user management system. In order to have users management available for your project all you have to do is the following:

1. Head to [AUTH registration page](https://auth.geeks.solutions/register).
2. Register your project.
3. Retrieve your credentials after redirection. Your credentials are: your `project id` and your `private key`.
4. Add ex_auth to you `mix.exs`
5. Add ex_auth configuration as follows:
 ```elixir
 config :ex_auth,
 private_key: "your_private_key",
 project_id: "your_project_id",
 endpoint: "https://auth.geeks.solutions", ## endpoint can point to the test site or to the live site.
 ws_endpoint: "ws://auth.geeks.solutions/socket/websocket"
 ```
6. Now in order to use the reset password feature, you need to add the following:
 - In your `config.ex`, add the following: 
 ```elixir
 config :ex_auth,
 reset_password_action: %{module: TestingHelpers, function: :action}
 ```
 - This also applies to use the resend_verification feature through: 
 ```elixir
 config :ex_auth,
 resend_verification_action: %{module: TestingHelpers, function: :action}
 ```
 By specifying the module and function (arity 1) you are telling `ex_auth` what is the action that your project would like to do when a reset password is requested for a user. This is the function that will be called.  i.e. some projects send an email.
7. If your project uses absinthe this library provides the `ExAuth.Plug.AbsintheContext` plug to use in your router pipeline to automatically populate your context with the user information when providing a valid auth token
8. You can also enable caching for certain calls to limit the API calls, supported resources are:
 - roles
To enable caching simply set your ExGeeks ETS Caching process in your app and then set the `:ex_auth` cache table in your :ex_geeks config finally enable caching by setting the `cache` config to true in your :ex_auth config

And that's it, you project now have an up and running users management system!