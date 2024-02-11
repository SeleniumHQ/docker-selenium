from http.server import BaseHTTPRequestHandler,HTTPServer
from os import environ
import json
import psutil

video_ready_port = int(environ.get('VIDEO_READY_PORT', 9000))

class Handler(BaseHTTPRequestHandler):

    def do_GET(self):
        video_ready = "ffmpeg" in (p.name().lower() for p in psutil.process_iter())
        response_code = 200 if video_ready else 404
        response_text = "ready" if video_ready else "not ready"
        self.send_response(response_code)
        self.end_headers()
        self.wfile.write(json.dumps({'status': response_text}).encode('utf-8'))

httpd = HTTPServer( ('0.0.0.0', video_ready_port), Handler )
httpd.serve_forever()
