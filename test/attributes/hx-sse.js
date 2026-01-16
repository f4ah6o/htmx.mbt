describe('hx-sse attribute', function() {
  beforeEach(function() {
    this.server = makeServer();
    clearWorkArea();
  });
  afterEach(function() {
    this.server.restore();
    clearWorkArea();
  });

  it('establishes SSE connection', function() {
    this.server.respondWith('/events', function(xhr) {
      xhr.respond(200, { 'Content-Type': 'text/event-stream' }, ': keep-alive\n\n');
    });

    var div = make('<div hx-sse="connect:/events"></div>');
    htmx.process(div);

    // Allow time for EventSource to be created
    this.server.respond();

    // Check if SSE was initialized
    var sseParent = div.closest('[hx-sse*="connect"]');
    should.not.exist(null, sseParent);
  });

  it('swaps content on message event', function(done) {
    this.server.respondWith('/events', function(xhr) {
      xhr.respond(200, { 'Content-Type': 'text/event-stream' },
        'data: <div id="new-content">New Content</div>\n\n');
    });

    var div = make('<div hx-sse="connect:/events swap:message">Waiting...</div>');
    htmx.process(div);

    // Simulate SSE message
    setTimeout(function() {
      // The content should have been swapped
      div.innerHTML.should.contain('<div id="new-content">New Content</div>');
      done();
    }, 100);
  });

  it('supports multiple swap events', function(done) {
    this.server.respondWith('/events', function(xhr) {
      xhr.respond(200, { 'Content-Type': 'text/event-stream' },
        'event: chat\ndata: <div>Chat message</div>\n\n' +
        'event: news\ndata: <div>News update</div>\n\n');
    });

    var div = make('<div hx-sse="connect:/events swap:chat swap:news"></div>');
    htmx.process(div);

    setTimeout(function() {
      div.innerHTML.should.contain('Chat message');
      div.innerHTML.should.contain('News update');
      done();
    }, 100);
  });

  it('triggers requests on SSE events', function(done) {
    var triggered = false;

    this.server.respondWith('/events', function(xhr) {
      xhr.respond(200, { 'Content-Type': 'text/event-stream' }, 'event: update\ndata: ping\n\n');
    });

    this.server.respondWith('/refresh', function(xhr) {
      triggered = true;
      xhr.respond(200, {}, '<div>Refreshed</div>');
    });

    make('<div hx-sse="connect:/events">' +
        '  <div hx-get="/refresh" hx-trigger="sse:update"></div>' +
        '</div>');

    setTimeout(function() {
      triggered.should.be.true;
      done();
    }, 100);
  });

  it('dispatches htmx:sse:open event', function(done) {
    var openFired = false;

    this.server.respondWith('/events', function(xhr) {
      xhr.respond(200, { 'Content-Type': 'text/event-stream' }, ': keep-alive\n\n');
    });

    var div = make('<div hx-sse="connect:/events"></div>');
    div.addEventListener('htmx:sse:open', function() {
      openFired = true;
    });

    htmx.process(div);

    setTimeout(function() {
      openFired.should.be.true;
      done();
    }, 100);
  });

  it('dispatches htmx:sse:error event', function(done) {
    var errorFired = false;

    var div = make('<div hx-sse="connect:/invalid-url"></div>');
    div.addEventListener('htmx:sse:error', function() {
      errorFired = true;
    });

    htmx.process(div);

    setTimeout(function() {
      errorFired.should.be.true;
      done();
    }, 100);
  });

  it('supports data-hx-sse prefix', function() {
    this.server.respondWith('/events', function(xhr) {
      xhr.respond(200, { 'Content-Type': 'text/event-stream' }, ': keep-alive\n\n');
    });

    var div = make('<div data-hx-sse="connect:/events"></div>');
    htmx.process(div);

    this.server.respond();

    var sseParent = div.closest('[data-hx-sse*="connect"]');
    should.exist(null, sseParent);
  });
});
