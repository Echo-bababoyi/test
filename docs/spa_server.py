"""SPA-aware static server for Flutter Web."""
import http.server
import mimetypes
import os
import sys

ROOT = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else ".")
PORT = int(sys.argv[2]) if len(sys.argv) > 2 else 3080

class SPAHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        url_path = self.path.split("?")[0].split("#")[0]
        file_path = os.path.join(ROOT, url_path.lstrip("/").replace("/", os.sep))

        # SPA fallback: non-existent paths → index.html
        if not os.path.isfile(file_path):
            file_path = os.path.join(ROOT, "index.html")

        try:
            with open(file_path, "rb") as f:
                data = f.read()
            mime, _ = mimetypes.guess_type(file_path)
            mime = mime or "application/octet-stream"
            self.send_response(200)
            self.send_header("Content-Type", mime)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        except FileNotFoundError:
            self.send_response(404)
            self.end_headers()

    def log_message(self, fmt, *args):
        pass

if __name__ == "__main__":
    with http.server.ThreadingHTTPServer(("", PORT), SPAHandler) as httpd:
        print(f"Serving {ROOT} at http://localhost:{PORT}", flush=True)
        httpd.serve_forever()
