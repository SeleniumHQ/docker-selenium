from http.server import BaseHTTPRequestHandler,HTTPServer
from os import environ
import json
import psutil
import signal
import sys

video_ready_port = int(environ.get('VIDEO_READY_PORT', 9000))

class Handler(BaseHTTPRequestHandler):

    def do_GET(self):
        if environ.get('SE_VIDEO_UPLOAD_ENABLED', 'false').lower() != 'true' and environ.get('SE_VIDEO_FILE_NAME', 'video.mp4').lower() != 'auto':
            video_ready = "ffmpeg" in (p.name().lower() for p in psutil.process_iter())
        else:
            video_ready = True
        response_code = 200 if video_ready else 404
        response_text = "ready" if video_ready else "not ready"
        self.send_response(response_code)
        self.end_headers()
        self.wfile.write(json.dumps({'status': response_text}).encode('utf-8'))

def graceful_shutdown(signum, frame):
    print("Trapped SIGTERM/SIGINT/x so shutting down video-ready...")
    httpd.shutdown()
    sys.exit(0)

signal.signal(signal.SIGINT, graceful_shutdown)
signal.signal(signal.SIGTERM, graceful_shutdown)

httpd = HTTPServer( ('0.0.0.0', video_ready_port), Handler )
httpd.serve_forever()
