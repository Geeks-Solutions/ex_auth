defmodule ExAuthWeb.UserControllerTest do
  use ExAuthWeb.ConnCase

  describe "Login and register" do
    test "POST /login success", %{conn: conn} do
      conn =
        post(conn, Routes.ex_auth_path(conn, :login), %{
          "email" => "someone@email.com",
          "password" => "password"
        })

      assert json_response(conn, 200)
    end

    test "POST /login failure", %{conn: conn} do
      conn =
        post(conn, Routes.ex_auth_path(conn, :login), %{
          "user" => %{
            "email" => "someone@email.com",
            "password" => "password"
          }
        })

      assert json_response(conn, 400)
    end

    test "POST /register success", %{conn: conn} do
      conn =
        post(conn, Routes.ex_auth_path(conn, :register), %{
          "email" => "someone@email.com",
          "password" => "password"
        })

      assert json_response(conn, 200)
    end

    test "POST /register failure", %{conn: conn} do
      conn =
        post(conn, Routes.ex_auth_path(conn, :register), %{
          "user" => %{
            "email" => "someone@email.com",
            "password" => "password"
          }
        })

      assert json_response(conn, 400)
    end
  end

  describe "Verify Token" do
    test "POST /verify_token success", %{conn: conn} do
      conn =
        post(conn, Routes.ex_auth_path(conn, :verify_token), %{
          "token" => "valid",
          "type" => "login"
        })

      assert json_response(conn, 200)
    end

    test "POST /verify_token failure", %{conn: conn} do
      conn =
        post(conn, Routes.ex_auth_path(conn, :verify_token), %{
          "token" => "invalid"
        })

      assert json_response(conn, 400)
    end
  end

  describe "Reset Password" do
    test "POST /reset_password success", %{conn: conn} do
      conn =
        post(conn, Routes.ex_auth_path(conn, :reset_password), %{
          "user" => "valid"
        })

      assert json_response(conn, 200)
    end

    test "POST /reset_password failure", %{conn: conn} do
      conn =
        post(conn, Routes.ex_auth_path(conn, :reset_password), %{
          "user" => "invalid"
        })

      assert json_response(conn, 400)
    end
  end
end
