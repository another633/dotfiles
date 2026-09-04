#!/usr/bin/env python3
"""为 clash 脚本提供一次性上传服务和简单的 Mihomo 配置修改。"""

import argparse
import html
import os
from pathlib import Path
import secrets
from http.server import BaseHTTPRequestHandler, HTTPServer

MAX_UPLOAD_SIZE = 16 * 1024 * 1024


def patch_config(path: Path, allow_lan: str, mixed_port: int) -> None:
    """只修改顶层标量字段，保留配置中的其他 YAML 内容。"""
    replacements = {"allow-lan": allow_lan, "mixed-port": str(mixed_port)}
    found: set[str] = set()
    output: list[str] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        replaced = False
        for key, value in replacements.items():
            if line.startswith(f"{key}:"):
                output.append(f"{key}: {value}")
                found.add(key)
                replaced = True
                break
        if not replaced:
            output.append(line)
    for key, value in replacements.items():
        if key not in found:
            output.insert(0, f"{key}: {value}")
    path.write_text("\n".join(output) + "\n", encoding="utf-8")


def serve(bind: str, port: int, token: str, output: Path, ready: Path) -> None:
    """接收一次带随机令牌的原始文件上传，然后退出。"""
    page_path = f"/{token}/"
    upload_path = f"/{token}/upload"
    page = f"""<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Mihomo 配置上传</title>
<style>
:root {{ color-scheme: light dark; font-family: system-ui, sans-serif; }}
* {{ box-sizing: border-box; }}
body {{
  min-height: 100vh; margin: 0; padding: clamp(16px, 5vw, 48px);
  display: grid; place-items: center; background: #101828; color: #f8fafc;
}}
main {{
  width: min(100%, 680px); padding: clamp(24px, 6vw, 48px);
  border: 1px solid #344054; border-radius: 20px; background: #1d2939;
  box-shadow: 0 24px 64px rgb(0 0 0 / 35%);
}}
h1 {{ margin: 0 0 12px; font-size: clamp(28px, 6vw, 42px); line-height: 1.15; }}
p {{ margin: 0 0 28px; color: #d0d5dd; font-size: clamp(16px, 3vw, 18px); line-height: 1.6; }}
.controls {{ display: grid; gap: 16px; }}
label {{ font-size: 16px; font-weight: 650; }}
input[type="file"] {{
  width: 100%; min-height: 56px; padding: 8px; border: 2px dashed #667085;
  border-radius: 12px; background: #101828; font-size: 16px; cursor: pointer;
}}
input[type="file"]::file-selector-button {{
  min-height: 40px; margin-right: 12px; padding: 8px 16px; border: 0;
  border-radius: 8px; background: #344054; color: #fff; font-weight: 650; cursor: pointer;
}}
button {{
  width: 100%; min-height: 56px; padding: 12px 24px; border: 0; border-radius: 12px;
  background: #12b76a; color: #062d1d; font-size: 18px; font-weight: 750; cursor: pointer;
}}
button:hover {{ background: #32d583; }}
button:focus-visible, input:focus-visible {{ outline: 3px solid #84caff; outline-offset: 3px; }}
button:disabled {{ cursor: wait; opacity: .65; }}
#status {{ min-height: 28px; margin: 20px 0 0; font-size: 16px; line-height: 1.5; white-space: pre-wrap; }}
#status[data-state="error"] {{ color: #fda29b; }}
#status[data-state="success"] {{ color: #6ce9a6; }}
@media (min-width: 640px) {{
  .actions {{ display: grid; grid-template-columns: minmax(0, 1fr) 160px; gap: 16px; align-items: center; }}
}}
@media (prefers-reduced-motion: no-preference) {{
  button {{ transition: background-color .15s ease, transform .15s ease; }}
  button:active {{ transform: translateY(1px); }}
}}
</style>
</head>
<body>
<main>
  <h1>上传 Mihomo 配置</h1>
  <p>选择 YAML 配置文件。上传完成后，此临时服务会自动关闭。</p>
  <div class="controls">
    <label for="file">配置文件</label>
    <div class="actions">
      <input id="file" type="file" accept=".yaml,.yml,application/yaml,text/yaml">
      <button id="upload" type="button" onclick="upload()">上传配置</button>
    </div>
  </div>
  <div id="status" role="status" aria-live="polite"></div>
</main>
<script>
async function upload() {{
  const input = document.getElementById('file');
  const button = document.getElementById('upload');
  const status = document.getElementById('status');
  const file = input.files[0];
  status.dataset.state = 'error';
  if (!file) {{ status.textContent = '请先选择配置文件。'; return; }}
  if (!/\\.ya?ml$/i.test(file.name)) {{ status.textContent = '仅支持 .yaml 或 .yml 文件。'; return; }}
  if (file.size > {MAX_UPLOAD_SIZE}) {{ status.textContent = '文件不能超过 16 MiB。'; return; }}
  button.disabled = true;
  status.dataset.state = '';
  status.textContent = '正在上传…';
  try {{
    const response = await fetch('{html.escape(upload_path)}', {{method: 'POST', body: file}});
    const message = await response.text();
    status.dataset.state = response.ok ? 'success' : 'error';
    status.textContent = message;
    if (!response.ok) button.disabled = false;
  }} catch (error) {{
    status.dataset.state = 'error';
    status.textContent = '上传失败，请检查网络后重试。';
    button.disabled = false;
  }}
}}
</script>
</body>
</html>""".encode()

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, format_string: str, *args: object) -> None:
            return

        def send_content(self, status: int, content: bytes, content_type: str) -> None:
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(content)))
            self.end_headers()
            self.wfile.write(content)

        def do_GET(self) -> None:  # noqa: N802
            if self.path != page_path:
                self.send_content(404, "地址无效".encode(), "text/plain; charset=utf-8")
                return
            self.send_content(200, page, "text/html; charset=utf-8")

        def do_POST(self) -> None:  # noqa: N802
            if self.path != upload_path:
                self.send_content(404, "地址无效".encode(), "text/plain; charset=utf-8")
                return
            try:
                length = int(self.headers.get("Content-Length", "0"))
            except ValueError:
                length = 0
            if length < 1 or length > MAX_UPLOAD_SIZE:
                self.send_content(413, "文件为空或超过 16 MiB".encode(), "text/plain; charset=utf-8")
                return
            content = self.rfile.read(length)
            if len(content) != length:
                self.send_content(400, "上传内容不完整".encode(), "text/plain; charset=utf-8")
                return
            temporary = output.with_suffix(".part")
            temporary.write_bytes(content)
            os.chmod(temporary, 0o600)
            temporary.replace(output)
            self.send_content(200, "上传成功，可以关闭此页面".encode(), "text/plain; charset=utf-8")

    server = HTTPServer((bind, port), Handler)
    ready.touch(mode=0o600)
    while not output.exists():
        server.handle_request()
    server.server_close()


def main() -> None:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("token")
    patch_parser = subparsers.add_parser("patch")
    patch_parser.add_argument("--config", type=Path, required=True)
    patch_parser.add_argument("--allow-lan", choices=("true", "false"), required=True)
    patch_parser.add_argument("--mixed-port", type=int, required=True)
    serve_parser = subparsers.add_parser("serve")
    serve_parser.add_argument("--bind", required=True)
    serve_parser.add_argument("--port", type=int, required=True)
    serve_parser.add_argument("--token", required=True)
    serve_parser.add_argument("--output", type=Path, required=True)
    serve_parser.add_argument("--ready", type=Path, required=True)
    args = parser.parse_args()

    if args.command == "token":
        print(secrets.token_urlsafe(24))
    elif args.command == "patch":
        patch_config(args.config, args.allow_lan, args.mixed_port)
    else:
        serve(args.bind, args.port, args.token, args.output, args.ready)


if __name__ == "__main__":
    main()
