defmodule Lotus.Web.RouterTest do
  use ExUnit.Case, async: true

  import Plug.Test

  alias Lotus.Web.Router

  describe "__options__" do
    test "setting default options in the router module" do
      {session_name, session_opts, route_opts} = Router.__options__("/lotus", [])

      assert session_name == :lotus_dashboard
      assert route_opts[:as] == :lotus_dashboard
      assert session_opts[:root_layout] == {Lotus.Web.Layouts, :root}
    end

    test "passing the transport through to the session" do
      assert %{"live_transport" => "longpoll"} = options_to_session(transport: "longpoll")
    end

    test "passing the live socket path through to the session" do
      assert %{"live_path" => "/alt"} = options_to_session(socket_path: "/alt")
    end

    test "passing csp nonce assign keys to the session" do
      assert %{"csp_nonces" => nonces} = options_to_session(csp_nonce_assign_key: nil)

      assert %{style: nil, script: nil} = nonces

      assert %{"csp_nonces" => %{style: "abc", script: "abc"}} =
               :get
               |> conn("/lotus")
               |> Plug.Conn.assign(:my_nonce, "abc")
               |> options_to_session(csp_nonce_assign_key: :my_nonce)
    end

    test "validating transport values" do
      assert_raise ArgumentError, ~r/invalid option for lotus_dashboard/, fn ->
        Router.__options__("/lotus", transport: "webpoll")
      end
    end
  end

  defp options_to_session(opts) do
    :get
    |> conn("/lotus")
    |> options_to_session(opts)
  end

  defp options_to_session(conn, opts) do
    {_name, sess_opts, _opts} = Router.__options__("/lotus", opts)

    {Router, :__session__, session_opts} = Keyword.get(sess_opts, :session)

    apply(Router, :__session__, [conn | session_opts])
  end
end
