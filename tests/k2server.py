#!/usr/bin/env python3
import json
import sys

from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse

agent_flags_hash = "8c3503bd-c9f7-4503-ba8e-a51215e3e565"

class K2MockServer(BaseHTTPRequestHandler):

    def do_POST(self):
        req_path = str(self.path)
        req_path_parsed = urlparse(req_path)

        # Device server: JSONRPC endpoint
        if req_path_parsed.path == "/":
            # Check `method` param: RequestEnrollment and RequestConfig require specific responses
            req_body = json.loads(self.rfile.read(int(self.headers.get('Content-Length'))))

            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()

            if req_body["method"] == "RequestEnrollment":
                self.wfile.write(json.dumps({
                    "node_key": "abd",
                    "node_invalid": False
                }).encode())
            elif req_body["method"] == "RequestConfig":
                self.wfile.write(json.dumps({
                    "config": "{}",
                    "node_invalid": False
                }).encode())
            else:
                self.wfile.write(json.dumps({
                    "node_invalid": False
                }).encode())            
            
            return

        # Control server: get subsystems and hashes
        elif req_path_parsed.path == "/api/agent/config":
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "token": "4223b8d9-3d29-4ec9-ba18-957650cbeff0",
                "config": {
                    "agent_flags": agent_flags_hash
                }
            }).encode())
            return
        
        # Not a supported endpoint
        else:
            self.send_response(404)
            self.end_headers()
            return

    def do_GET(self):
        req_path = str(self.path)
        req_path_parsed = urlparse(req_path)

        # Control server: get challenge
        if req_path_parsed.path == "/api/agent/config":
            self.send_response(200)
            self.send_header('Content-type', 'application/octet-stream')
            self.end_headers()
            self.wfile.write(b'1676065364')
            return

        # Control server: get agent flags
        elif req_path_parsed.path == "/api/agent/object/" + agent_flags_hash:
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"desktop_enabled": "1"}).encode())
            return

        # Not a supported endpoint
        else:
            self.send_response(404)
            self.end_headers()
            return


if __name__ == '__main__':
    s = HTTPServer(('app.kolide.test', 80), K2MockServer)
    s.serve_forever()
