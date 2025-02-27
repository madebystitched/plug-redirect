defmodule Plug.Redirect do
  @moduledoc """
  A plug builder for redirecting requests.
  """

  alias Plug.Redirect.Route

  @redirect_codes [301, 302, 303, 307, 308]

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__), only: [redirect: 3, redirect: 2]
      @before_compile unquote(__MODULE__)
      def init(opts), do: opts
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def call(conn, _opts), do: conn
    end
  end

  @doc """
  Specify a redirect.

  The first argument is the request to match upon for the redirect.

  The second argument is the location to redirect the request to.

  ## Options

  * `:status` - The HTTP status code to use for the redirect.
  * `:query` - The HTTP request is using query parameters.
  """
  defmacro redirect(from, to, options \\ [{:status, 301}])

  defmacro redirect(from, to, [{:status, status}, {:query, query}])
           when query == true and status in @redirect_codes do
    [request_path, query_string] = String.split(from, "?")
    to_segments = to |> Route.to_path_info_ast()

    quote do
      def call(
            %Plug.Conn{request_path: unquote(request_path), query_string: unquote(query_string)} =
              conn,
            _opts
          ) do
        to = unquote(to_segments) |> Enum.join("/")

        conn
        |> Plug.Conn.put_resp_header("location", to)
        |> Plug.Conn.resp(unquote(status), "You are being redirected.")
        |> Plug.Conn.halt()
      end
    end
  end

  defmacro redirect(from, to, [{:status, status}])
           when status in @redirect_codes do
    from_segments = from |> Route.to_path_info_ast() |> Enum.filter(&(&1 != ""))
    to_segments = to |> Route.to_path_info_ast()

    quote do
      def call(%Plug.Conn{path_info: unquote(from_segments)} = conn, _opts) do
        to = unquote(to_segments) |> Enum.join("/")

        conn
        |> Plug.Conn.put_resp_header("location", to)
        |> Plug.Conn.resp(unquote(status), "You are being redirected.")
        |> Plug.Conn.halt()
      end
    end
  end

  defmacro redirect(status, from, to) when is_integer(status) do
    quote do
      Plug.Redirect.redirect(unquote(from), unquote(to), status: unquote(status))
    end
  end
end
