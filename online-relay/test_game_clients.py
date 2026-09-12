"""Two real Godot clients, a local relay, and a forced host disconnect."""
import argparse
import os
from pathlib import Path
import socket
import subprocess
import sys
import time
import tempfile
import shutil
import secrets
from concurrent.futures import ThreadPoolExecutor
from urllib.request import urlopen


def run(godot, server=None, impaired=False, browser=False):
    # Launch the engine directly and isolate each client's persistent settings.
    engine = godot.replace("_console.exe", ".exe")
    if Path(engine).exists():
        godot = engine
    root = Path(__file__).resolve().parent.parent
    relay = None
    if server is None:
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            port = sock.getsockname()[1]
        env = dict(os.environ, AKSOY_TANK_RELAY_PORT=str(port))
        relay = subprocess.Popen([sys.executable, "server.py"], cwd=root / "online-relay", env=env,
                                 stdout=subprocess.DEVNULL, stderr=None)
        server = f"ws://127.0.0.1:{port}/ws"
    elif not server.startswith("wss://"):
        raise ValueError("Remote tests require wss://")
    children = []
    client_data = tempfile.TemporaryDirectory(prefix="aksoy-network-test-")
    try:
        guest_root = Path(client_data.name) / "project"
        guest_root.mkdir()
        shutil.copy2(root / "project.godot", guest_root / "project.godot")
        for directory in ("src", "tools", "assets", ".godot"):
            shutil.copytree(root / directory, guest_root / directory)
        for _ in range(100):
            if relay is None:
                break
            try:
                with urlopen(f"http://127.0.0.1:{port}/aksoy-tank/health", timeout=0.2):
                    break
            except OSError:
                time.sleep(0.1)
        else:
            raise RuntimeError("Relay startup timeout")
        directory_server = server
        if impaired:
            with socket.socket() as sock:
                sock.bind(("127.0.0.1", 0))
                proxy_port = sock.getsockname()[1]
            proxy = subprocess.Popen([sys.executable, "traffic_proxy.py", "--port", str(proxy_port),
                                      "--upstream", server, "--latency-ms", "100", "--jitter-ms", "30",
                                      "--bandwidth-kbps", "512"], cwd=root / "online-relay",
                                     stdout=subprocess.PIPE, stderr=None, text=True)
            children.append(proxy)
            # stdout is a single readiness line; no traffic is logged by the proxy.
            if proxy.stdout.readline().strip() != "TRAFFIC_PROXY: READY":
                raise RuntimeError("Traffic proxy startup failed")
            server = f"ws://127.0.0.1:{proxy_port}/ws"
            print("IMPAIRED_NETWORK: each direction latency=100ms jitter=30ms bandwidth=512kbps")
        for mode in ("online_coop", "online_vs"):
            args = [godot, "--headless", "--path", str(root), "--script",
                    "res://tools/network_client_integration.gd", "--",
                    f"--mode={mode}", f"--server={server}", f"--room=IT{secrets.token_hex(3).upper()}"]
            if browser:
                args += ["--browser", f"--directory-server={directory_server}"]
            host_args = args[:1] + ["--log-file", str(root.parent / "aksoy-tank-builds" / "integration-host.log")] + args[1:] + ["--leader"]
            guest_args = args[:1] + ["--log-file", str(root.parent / "aksoy-tank-builds" / "integration-guest.log")] + args[1:]
            guest_args[guest_args.index("--path") + 1] = str(guest_root)
            host = subprocess.Popen(host_args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
                                    env=dict(os.environ, APPDATA=str(Path(client_data.name) / "host")))
            children.append(host)
            time.sleep(1.0)
            guest = subprocess.Popen(guest_args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
                                     env=dict(os.environ, APPDATA=str(Path(client_data.name) / "guest")))
            children.append(guest)
            failures = []
            with ThreadPoolExecutor(max_workers=2) as executor:
                futures = [executor.submit(process.communicate, timeout=90) for process in (host, guest)]
                for process, future in zip((host, guest), futures):
                    output, _ = future.result()
                    print(output)
                    if process.returncode or "ERROR:" in output or "NETWORK_CLIENT: PASS" not in output:
                        failures.append(output)
            if failures:
                raise RuntimeError(f"{mode} integration failed")
            time.sleep(0.5)
    finally:
        for process in children + ([relay] if relay else []):
            if process.poll() is None:
                process.terminate()
            process.wait(timeout=10)
        client_data.cleanup()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--server", help="Optional production wss:// endpoint")
    parser.add_argument("--impaired", action="store_true", help="Test through local latency/jitter/bandwidth proxy")
    parser.add_argument("--browser", action="store_true", help="Create/list/join a password-protected room")
    args = parser.parse_args()
    run(args.godot, args.server, args.impaired, args.browser)
