defmodule ItsmWeb.GraphiqlController do
  use ItsmWeb, :controller

  def index(conn, _params) do
    html_content = """
    <!DOCTYPE html>
    <html lang="ko">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>GraphiQL(3.8.3)</title>

      <link href="/css/graphiql.min.css" rel="stylesheet">

      <style>
        html, body, #root {
          height: 100%;
          margin: 0;
          overflow: hidden;
          width: 100%;
          background: #1e1e1e;
        }
      </style>
    </head>
    <body class="graphiql-dark">

      <div id="root">GraphiQL 로딩 중...</div>

      <script src="/js/fetch.min.js"></script>
      <script src="/js/react.production.min.js"></script>
      <script src="/js/react-dom.production.min.js"></script>
      <script src="/js/graphiql.min.js"></script>

      <script>
        function 최신_fetcher(graphQLParams) {
          return fetch('/api/graphql', {
            method: 'post',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(graphQLParams),
          }).then(function (response) {
            return response.json();
          });
        }

        ReactDOM.render(
          React.createElement(GraphiQL, {
            fetcher: 최신_fetcher,
            defaultEditorToolsVisibility: true
          }),
          document.getElementById("root")
        );
      </script>
    </body>
    </html>
    """

    html(conn, html_content)
  end
end
