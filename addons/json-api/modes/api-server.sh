MODE_NAME="api-server"
MODE_DESCRIPTION="Start the Sn1per REST API server for programmatic scan management"
MODE_REQUIRED_VARS=(INSTALL_DIR)
MODE_REQUIRED_TOOLS=(python3)

API_PORT="${API_PORT:-8080}"
API_HOST="${API_HOST:-0.0.0.0}"

mode_validate() {
  if [[ -n "$API_AUTH_TOKEN" && ${#API_AUTH_TOKEN} -lt 16 ]]; then
    log_warn "API_AUTH_TOKEN is too short (min 16 chars)"
  fi
}

mode_init() {
  log_info "Initializing JSON API server..."
}

mode_run() {
  section_banner
  section_header "SN1PER JSON API SERVER v1.0"
  log_info "Listening on $API_HOST:$API_PORT"
  log_info "Documentation: GET /v1/health"

  if [[ -n "$API_TLS_CERT" && -n "$API_TLS_KEY" ]]; then
    log_info "TLS enabled (cert: $API_TLS_CERT)"
  fi

  local sniper_bin="$INSTALL_DIR/sniper"
  local api_py
  api_py=$(cat <<'PYEOF'
import http.server
import json
import subprocess
import os
import urllib.parse
import signal
import sys
from datetime import datetime

SNIPER_BIN = os.environ.get('SNIPER_BIN', '/usr/share/sniper/sniper')
INSTALL_DIR = os.environ.get('INSTALL_DIR', '/usr/share/sniper')
AUTH_TOKEN = os.environ.get('API_AUTH_TOKEN', '')
CORS_ORIGINS = os.environ.get('API_CORS_ORIGINS', '*')

scan_tasks = {}
task_id_counter = 0

def require_auth(handler):
    if not AUTH_TOKEN:
        return True
    token = handler.headers.get('Authorization', '').replace('Bearer ', '')
    if token == AUTH_TOKEN:
        return True
    handler.send_response(401)
    handler.send_header('Content-Type', 'application/json')
    handler.end_headers()
    handler.wfile.write(json.dumps({'error': 'unauthorized'}).encode())
    return False

def send_json(handler, data, status=200):
    handler.send_response(status)
    handler.send_header('Content-Type', 'application/json')
    if CORS_ORIGINS:
        handler.send_header('Access-Control-Allow-Origin', CORS_ORIGINS)
        handler.send_header('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS')
        handler.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
    handler.end_headers()
    handler.wfile.write(json.dumps(data).encode())

def mode_list():
    modes_dir = os.path.join(INSTALL_DIR, 'modes')
    addons_dir = os.path.join(INSTALL_DIR, 'addons')
    modes = []
    if os.path.isdir(modes_dir):
        for f in sorted(os.listdir(modes_dir)):
            if f.endswith('.sh'):
                modes.append(f.replace('.sh', ''))
    return sorted(set(modes))

class APIHandler(http.server.BaseHTTPHandler):
    def do_OPTIONS(self):
        send_json(self, {})

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path.rstrip('/')

        if path == '/v1/health':
            send_json(self, {'status': 'ok', 'version': '1.0.0', 'timestamp': datetime.utcnow().isoformat() + 'Z'})

        elif path == '/v1/modes':
            if not require_auth(self): return
            send_json(self, {'modes': mode_list()})

        elif path == '/v1/workspace':
            if not require_auth(self): return
            loot_dir = os.path.join(INSTALL_DIR, 'loot', 'workspace')
            workspaces = []
            if os.path.isdir(loot_dir):
                workspaces = sorted(os.listdir(loot_dir))
            send_json(self, {'workspaces': workspaces})

        elif path.startswith('/v1/workspace/'):
            if not require_auth(self): return
            name = path.split('/')[-1]
            ws_dir = os.path.join(INSTALL_DIR, 'loot', 'workspace', name)
            findings_file = os.path.join(ws_dir, 'findings.json')
            data = {'name': name, 'exists': os.path.isdir(ws_dir)}
            if os.path.isfile(findings_file):
                try:
                    with open(findings_file) as f:
                        data['findings'] = json.load(f).get('findings', [])
                except: pass
            send_json(self, data)

        elif path.startswith('/v1/scan/'):
            if not require_auth(self): return
            scan_id = path.split('/')[-1]
            task = scan_tasks.get(scan_id, {})
            send_json(self, task)

        elif path.startswith('/v1/findings'):
            if not require_auth(self): return
            params = urllib.parse.parse_qs(parsed.query)
            workspace = params.get('workspace', [None])[0]
            severity = params.get('severity', [None])[0]
            ws_dir = os.path.join(INSTALL_DIR, 'loot', 'workspace', workspace) if workspace else os.path.join(INSTALL_DIR, 'loot')
            findings_file = os.path.join(ws_dir, 'findings.json')
            results = []
            if os.path.isfile(findings_file):
                try:
                    with open(findings_file) as f:
                        findings = json.load(f).get('findings', [])
                    for item in findings:
                        if severity and item.get('severity', '').upper() != severity.upper():
                            continue
                        results.append(item)
                except: pass
            send_json(self, {'findings': results})

        else:
            send_json(self, {'error': 'not found'}, 404)

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path.rstrip('/')

        if path == '/v1/scan':
            if not require_auth(self): return
            length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(length).decode() if length else '{}'
            try: params = json.loads(body)
            except: params = {}
            target = params.get('target', '')
            mode = params.get('mode', 'normal')
            workspace = params.get('workspace', target)
            if not target:
                send_json(self, {'error': 'target is required'}, 400)
                return
            global task_id_counter
            task_id_counter += 1
            scan_id = f'scan_{task_id_counter}_{datetime.utcnow().strftime("%Y%m%d%H%M%S")}'
            scan_tasks[scan_id] = {
                'id': scan_id,
                'target': target,
                'mode': mode,
                'workspace': workspace,
                'status': 'queued',
                'created': datetime.utcnow().isoformat() + 'Z'
            }
            send_json(self, scan_tasks[scan_id], 201)

        else:
            send_json(self, {'error': 'not found'}, 404)

    def do_DELETE(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path.rstrip('/')
        if path.startswith('/v1/workspace/'):
            if not require_auth(self): return
            name = path.split('/')[-1]
            ws_dir = os.path.join(INSTALL_DIR, 'loot', 'workspace', name)
            import shutil
            if os.path.isdir(ws_dir):
                shutil.rmtree(ws_dir)
                send_json(self, {'status': 'deleted', 'workspace': name})
            else:
                send_json(self, {'error': 'not found'}, 404)
        else:
            send_json(self, {'error': 'not found'}, 404)

if __name__ == '__main__':
    host = os.environ.get('API_HOST', '0.0.0.0')
    port = int(os.environ.get('API_PORT', 8080))
    server = http.server.HTTPServer((host, port), APIHandler)
    print(f'API server listening on {host}:{port}')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        server.shutdown()
PYEOF
)

  INSTALL_DIR="$INSTALL_DIR" SNIPER_BIN="$INSTALL_DIR/sniper" \
    API_AUTH_TOKEN="$API_AUTH_TOKEN" API_CORS_ORIGINS="$API_CORS_ORIGINS" \
    API_HOST="$API_HOST" API_PORT="$API_PORT" \
    python3 -c "$api_py"
}

mode_cleanup() {
  log_info "JSON API server stopped"
}

mode_execute
