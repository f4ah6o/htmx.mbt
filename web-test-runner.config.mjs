import { defaultReporter, summaryReporter } from '@web/test-runner'

const config = {
  testRunnerHtml: (testFramework) => `
  <html lang="en">
    <head>
      <meta charset="utf-8" />
      <title>htmx.mbt web-test-runner</title>
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <meta http-equiv="cache-control" content="no-cache, must-revalidate, post-check=0, pre-check=0" />
      <meta http-equiv="cache-control" content="max-age=0" />
      <meta http-equiv="expires" content="0" />
      <meta http-equiv="expires" content="Tue, 01 Jan 1980 1:00:00 GMT" />
      <meta http-equiv="pragma" content="no-cache" />
      <meta name="htmx-config" content='{"historyEnabled":false,"defaultSettleDelay":0}' />
    </head>
    <body style="padding:20px;font-family: sans-serif">
      <h2>htmx.mbt Test Suite</h2>
      <p id="version-number">Version:&nbsp;</p>

      <script src="node_modules/chai/chai.js"></script>
      <script src="node_modules/chai-dom/chai-dom.js"></script>
      <script src="node_modules/sinon/pkg/sinon.js"></script>
      <script src="node_modules/mock-socket/dist/mock-socket.js"></script>
      <script src="target/js/release/build/cmd/htmx_test/htmx_test.js"></script>
      <script>
        const versionNode = document.getElementById('version-number')
        if (versionNode && window.htmx && window.htmx.version) {
          versionNode.innerText += window.htmx.version
        }
      </script>

      <script class="mocha-init">
        window.should = window.chai.should()
      </script>

      <script src="test/util/util.js"></script>

      <script type="module" src="${testFramework}"></script>

      <script src="test/lib/_hyperscript.js"></script>

      <div hx-trigger="restored" hidden>just for htmx:restored event testing</div>
      <em>Work Area</em>
      <hr />
      <div id="work-area" hx-history-elt></div>
    </body>
  </html>`,
  nodeResolve: true,
  files: ['test/attributes/**/*.js', 'test/core/**/*.js'],
  reporters: [
    summaryReporter({
      flatten: false,
      reportTestLogs: false,
      reportTestErrors: true
    }),
    defaultReporter({ reportTestProgress: true, reportTestResults: true })
  ]
}

export default config
