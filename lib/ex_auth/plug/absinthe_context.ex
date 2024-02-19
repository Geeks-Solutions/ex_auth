defmodule ExAuth.Plug.AbsintheContext do
    @moduledoc """
    Extracts User information for a valid Auth Token present in the header
    as `authorization Bearer {token}`
    Also supports the `token-type: {type}` header (default to `login`, can also be `reset`)
    """
    @behaviour Plug
    import Plug.Conn
    require Logger

    alias ExAuth.AuthAPI
    alias ExGeeks.Helpers, as: GeeksHelpers

    def init(opts), do: opts

    def call(conn, _) do
      with {:absinthe, {:module, _}} <- {:absinthe, Code.ensure_compiled(Absinthe.Plug)},
      %{current_user: _} = context <- build_user_context(conn) do
          apply(Absinthe.Plug, :put_options, [conn, %{context: context}])

      else
        {:absinthe, {:error, _}} ->
          Logger.error("ex_auth: Can't use the Absinthe Plug without Absinthe")
          conn

        %{error: _} = context ->
          apply(Absinthe.Plug, :put_options, [conn, %{context: context}])
      end
    end

    # Return the current user context based on the authorization header
    defp build_user_context(conn) do
      if get_req_header(conn, "authorization") != [] do
        user_process(conn, get_req_header(conn, "token-type"))
      else
        default_value_user(conn) |> add_fields(conn)
      end
    end

    defp user_process(conn, []), do: user_process(conn, ["login"])

    defp user_process(conn, [type]) do
      with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
           {:ok, current_user} <- authorize(token, type) do
        %{current_user: current_user, token: token, token_type: type} |> add_fields(conn)
      else
        {:error, "invalid authorization token"} ->
          conn
          |> send_resp(
            401,
            ~s({"message": "Token invalid or expired." ,"status": "failed"})
          )
          |> halt

        _ ->
          default_value_user(conn) |> add_fields(conn)
      end
    end

    defp default_value_user(%{
      private: %{absinthe: %{context: %{current_user: current_user}}}
    }) do
      %{current_user: current_user}
    end

    defp default_value_user(_), do: %{current_user: nil}

    defp add_fields(main_data, conn) do
      roles = get_roles(main_data)

      bo =
        case get_req_header(conn, "bo") do
          ["true"] ->
            true

          _ ->
            false
        end

      new_current_user =
        return_add_fields(main_data.current_user, %{
          role: roles,
          bo: bo
        })

      main_data
      |> Map.put(:current_user, new_current_user)
    end

    defp get_roles(main_data) do
      case main_data do
        %{current_user: %{user: %{info: info}}, token: _token} ->
          roles =
            Enum.reduce(info.roles_object, [], fn %{title: title} = _role, acc ->
              List.insert_at(acc, -1, title)
            end)

          roles

        _ ->
          nil
      end
    end

    defp return_add_fields(current_user, %{
           role: role,
           bo: bo
         }) do
      map =
        case current_user do
          nil ->
            %{}

          _ ->
            current_user
        end

      map
      |> Map.put(:roles, role)
      |> Map.put(:bo, bo)
    end

    defp authorize(token, type \\ "login") do
      case AuthAPI.verify_token(token, type) do
        %{
          "data" => %{
            "token" => %{"token" => _token, "type" => ^type},
            "user" => user
          }
        } ->
          {:ok,
           %{
             user: %{
               info: user |> GeeksHelpers.atomize_keys()
             }
           }}
        %{"message" => err, "status" => "failed"} ->
          Logger.error("GQL Context: #{err}")
          {:error, "ex_auth: GQL Context - #{err}"}
        %{"error" => _} ->
          Logger.error("ex_auth: GQL Context - invalid authorization token")
          {:error, "invalid authorization token"}
      end
    end
end
