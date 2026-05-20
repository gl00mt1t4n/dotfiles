#!/usr/bin/env python3
import argparse
import http.client
import http.server
import os
import socketserver
import sys


DROP_HEADERS = {
    "authorization",
    "connection",
    "host",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailer",
    "transfer-encoding",
    "upgrade",
}


class OpenAIProxy(http.server.BaseHTTPRequestHandler):
    upstream_host = "api.openai.com"
    upstream_port = 443
    key_path = None

    def log_message(self, fmt, *args):
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))

    def _api_key(self):
        with open(self.key_path, "r", encoding="utf-8") as key_file:
            return key_file.read().strip()

    def _forward(self):
        length = int(self.headers.get("content-length", "0"))
        body = self.rfile.read(length) if length else None
        headers = {
            key: value
            for key, value in self.headers.items()
            if key.lower() not in DROP_HEADERS
        }
        headers["Authorization"] = f"Bearer {self._api_key()}"
        if body is not None:
            headers["Content-Length"] = str(len(body))

        conn = http.client.HTTPSConnection(self.upstream_host, self.upstream_port, timeout=120)
        try:
            conn.request(self.command, self.path, body=body, headers=headers)
            response = conn.getresponse()
            payload = response.read()

            self.send_response(response.status, response.reason)
            for key, value in response.getheaders():
                if key.lower() not in DROP_HEADERS:
                    self.send_header(key, value)
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
        finally:
            conn.close()

    def do_GET(self):
        self._forward()

    def do_POST(self):
        self._forward()

    def do_DELETE(self):
        self._forward()


class ReusableThreadingTCPServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True


def main():
    parser = argparse.ArgumentParser(description="Local OpenAI API proxy with server-side key injection.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=11435)
    parser.add_argument("--key-file", required=True)
    args = parser.parse_args()

    if not os.path.exists(args.key_file):
        raise SystemExit(f"missing key file: {args.key_file}")

    OpenAIProxy.key_path = args.key_file
    with ReusableThreadingTCPServer((args.host, args.port), OpenAIProxy) as server:
        server.serve_forever()


if __name__ == "__main__":
    main()
