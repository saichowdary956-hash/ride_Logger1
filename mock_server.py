from http.server import BaseHTTPRequestHandler, HTTPServer
import json

HOST = '127.0.0.1'
PORT = 8000

class Handler(BaseHTTPRequestHandler):
    def _set_headers(self, code=200):
        self.send_response(code)
        self.send_header('Content-type', 'application/json')
        self.end_headers()

    def do_POST(self):
        if self.path == '/upload':
            length = int(self.headers.get('content-length', 0))
            body = self.rfile.read(length).decode('utf-8')
            try:
                data = json.loads(body)
            except Exception:
                data = {'raw': body}
            print('Received:', data)
            self._set_headers(200)
            self.wfile.write(json.dumps({'status': 'ok'}).encode('utf-8'))
        else:
            self._set_headers(404)
            self.wfile.write(json.dumps({'error': 'not found'}).encode('utf-8'))

    def log_message(self, format, *args):
        # suppress default logging
        return

if __name__ == '__main__':
    print(f"Starting mock server at http://{HOST}:{PORT}/upload")
    server = HTTPServer((HOST, PORT), Handler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    server.server_close()
    print('Server stopped')
