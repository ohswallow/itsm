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

        const addHomeButton = function() {
          const sidebarSection = document.getElementsByClassName("graphiql-sidebar-section")[0];
          if (sidebarSection) {
            const customButton = document.createElement("button");
            customButton.type = "button";
            customButton.className = "graphiql-un-styled test-check-button";
            customButton.setAttribute("aria-label", "Custom Setting");

            customButton.innerHTML = `
              <svg height="1.2em" viewBox="0 0 60 24" fill="none" xmlns="http://www.w3.org/2000/svg" style="width: auto; max-width: 100%;">
                <text
                  x="50%"
                  y="55%"
                  dominant-baseline="middle"
                  text-anchor="middle"
                  fill="currentColor"
                  font-size="9"
                  font-weight="bold"
                  font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
                  letter-spacing="-0.5px"
                >
                  KB ITSM
                </text>
              </svg>
            `;

            Object.assign(customButton.style, {
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              width: "100%",
              height: "44px",
              cursor: "pointer",
              color: "var(--color-neutral-60, currentColor)"
            });

            customButton.addEventListener("click", function() {
              window.location.href = "/main";
            });

            sidebarSection.insertBefore(customButton, sidebarSection.firstChild);
          }
        };

        window.addEventListener("load", addHomeButton);
      </script>
    </body>
    </html>
    """

    html(conn, html_content)
  end
end
