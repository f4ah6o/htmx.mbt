describe('simple click test', function() {
  beforeEach(function() {
    this.server = sinon.fakeServer.create()
    clearWorkArea()
  })
  
  afterEach(function() {
    this.server.restore()
    clearWorkArea()
  })
  
  it('should trigger click handler', function() {
    this.server.respondWith('GET', '/test', 'Clicked!')
    
    var btn = make('<button hx-get="/test">Click Me!</button>')
    btn.innerHTML.should.equal('Click Me!')
    btn.click()
    
    this.server.respond()
    
    // Check if the content was swapped
    btn.innerHTML.should.equal('Clicked!')
  })
})
