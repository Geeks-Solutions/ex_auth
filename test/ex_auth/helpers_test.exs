defmodule ExAuth.HelpersTest do
  use ExUnit.Case, async: false

  alias ExAuth.Helpers

  describe "websocket/0" do
    setup do
      previous = Application.get_env(:ex_auth, :websocket)

      on_exit(fn ->
        if is_nil(previous) do
          Application.delete_env(:ex_auth, :websocket)
        else
          Application.put_env(:ex_auth, :websocket, previous)
        end
      end)
    end

    test "defaults to true" do
      Application.delete_env(:ex_auth, :websocket)

      assert Helpers.websocket()
    end

    test "can be disabled" do
      Application.put_env(:ex_auth, :websocket, false)

      refute Helpers.websocket()
    end
  end
end
