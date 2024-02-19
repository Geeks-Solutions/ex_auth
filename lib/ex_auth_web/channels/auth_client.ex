defmodule ExAuth.AuthClient do
  @moduledoc false
  require Logger
  alias ExAuth.Helpers
  alias Phoenix.Channels.GenSocketClient

  @behaviour GenSocketClient

  def start_link do
    GenSocketClient.start_link(
      __MODULE__,
      Phoenix.Channels.GenSocketClient.Transport.WebSocketClient,
      Helpers.ws_endpoint(),
      [],
      name: :auth_websocket
    )
  end

  def init(url) do
    {:connect, url, [], %{first_join: true, ping_ref: 1, msg_ref: 1}}
  end

  def auth_channel_room do
    "users_credentials"
  end

  def handle_connected(transport, state) do
    Logger.info("ex_auth: connected to socket")

    GenSocketClient.join(
      transport,
      auth_channel_room(),
      payload()
    )

    {:ok, state}
  end

  def handle_disconnected(reason, state) do
    Logger.error("ex_auth: disconnected - #{inspect(reason)}")
    Process.send_after(self(), :connect, :timer.seconds(1))
    {:ok, state}
  end

  def handle_joined(topic, _payload, _transport, state) do
    Logger.info("ex_auth: joined the topic #{topic}")

    {:ok, state}
  end

  def handle_join_error(topic, payload, _transport, state) do
    Logger.error("ex_auth: join error on the topic #{topic} - #{inspect(payload)}")
    {:ok, state}
  end

  def handle_channel_closed(topic, payload, _transport, state) do
    Logger.error("ex_auth: disconnected from the topic #{topic} - #{inspect(payload)}")

    Process.send_after(self(), {:join, topic}, :timer.seconds(1))
    {:ok, state}
  end

  def handle_message(
        topic,
        "reset_password",
        payload,
        _transport,
        state
      ) do
    Logger.debug("ex_auth: message on topic #{topic} - reset_password #{inspect(payload)}")
    # Utils.send_email("reset_password", [user["email"]], token)
    action = Helpers.env(:reset_password_action, %{raise: true})

    apply(action[:module], action[:function], [payload])

    {:ok, state}
  end

  def handle_message(
        topic,
        "resend_verification",
        payload,
        _transport,
        state
      ) do
    Logger.debug("ex_auth: message on topic #{topic} - send_verification #{inspect(payload)}")

    action = Helpers.env(:resend_verification_action, %{raise: true})

    apply(action[:module], action[:function], [payload])

    {:ok, state}
  end

  def handle_message(topic, event, payload, _transport, state) do
    Logger.debug("ex_auth: message on topic #{topic} - #{event} #{inspect(payload)}")

    {:ok, state}
  end

  def handle_call(request, from, _transport, state) do
    Logger.debug("ex_auth: message from #{inspect(from)} - #{inspect(request)}")

    {:reply, "ok", state}
  end

  def handle_reply(topic, _ref, payload, _transport, state) do
    Logger.debug("ex_auth: message on topic #{topic} - #{inspect(payload)}")
    {:ok, state}
  end

  def handle_info(:connect, _transport, state) do
    Logger.debug("ex_auth: connecting")
    {:connect, state}
  end

  def handle_info({:join, topic}, transport, state) do
    Logger.debug("ex_auth: joining the topic #{topic}")

    case GenSocketClient.join(transport, topic, payload()) do
      {:error, reason} ->
        Logger.error("ex_auth: error joining the topic #{topic} - #{inspect(reason)}")

        Process.send_after(self(), {:join, topic}, :timer.seconds(1))

      {:ok, _ref} ->
        :ok
    end

    {:ok, state}
  end

  def handle_info(:ping_server, _transport, state) do
    Logger.debug("ex_auth: sending ping ##{state.ping_ref}")
    # GenSocketClient.push(transport, "ping", "ping", %{ping_ref: state.ping_ref})
    {:ok, %{state | ping_ref: state.ping_ref + 1}}
  end

  def handle_info(message, _transport, state) do
    Logger.warning("ex_auth: Unhandled message #{inspect(message)}")
    {:ok, state}
  end

  def payload do
    %{key: Helpers.private_key(), project_id: Helpers.project_id()}
  end
end
