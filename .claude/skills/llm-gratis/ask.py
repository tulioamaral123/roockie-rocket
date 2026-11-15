#!/usr/bin/env python3
"""Manda um pedido a um LLM gratuito (API compatível com OpenAI) e imprime só a resposta.

Uso:
  ask.py [-p kilo|llm7|groq|gemini] [-m modelo] [-f arquivo ...] [-s "instrução de sistema"] "pedido"
  echo "texto" | ask.py "pedido sobre o texto da entrada"

Chaves: variáveis GROQ_API_KEY / GEMINI_API_KEY ou o arquivo ~/.config/llm-gratis/keys.env
(linhas KEY=valor). Só usa a biblioteca padrão.
"""
import argparse, json, os, sys, time, urllib.request, urllib.error
from pathlib import Path

# (url, variável da chave, modelo padrão, chave obrigatória?)
PROVIDERS = {
    "kilo": ("https://api.kilo.ai/api/gateway/chat/completions", "KILO_API_KEY", "nvidia/nemotron-3.5-lightning:free", False),
    "llm7": ("https://api.llm7.io/v1/chat/completions", "LLM7_API_KEY", "gpt-oss:20b", False),
    "groq": ("https://api.groq.com/openai/v1/chat/completions", "GROQ_API_KEY", "openai/gpt-oss-120b", True),
    "gemini": ("https://generativelanguage.googleapis.com/v1beta/openai/chat/completions", "GEMINI_API_KEY", "gemini-3.8-flash", True),
}
KEYS_FILE = Path.home() / ".config/llm-gratis/keys.env"


def load_key(var):
    if os.environ.get(var):
        return os.environ[var]
    if KEYS_FILE.exists():
        for line in KEYS_FILE.read_text().splitlines():
            k, _, v = line.strip().removeprefix("export ").partition("=")
            if k.strip() == var and v.strip():
                return v.strip().strip('"').strip("'")
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("prompt")
    ap.add_argument("-p", "--provider", default=os.environ.get("LLM_GRATIS_PROVIDER", "kilo"), choices=PROVIDERS)
    ap.add_argument("-m", "--model")
    ap.add_argument("-f", "--file", action="append", default=[])
    ap.add_argument("-s", "--system", default="Responda de forma direta e concisa, sem preâmbulo.")
    ap.add_argument("--max-tokens", type=int, default=4000)
    a = ap.parse_args()

    url, var, default_model, needs_key = PROVIDERS[a.provider]
    key = load_key(var)
    if not key and needs_key:
        sys.exit(f"Sem chave: defina {var} no ambiente ou em {KEYS_FILE}")

    parts = [a.prompt]
    if not sys.stdin.isatty():
        data = sys.stdin.read()
        if data.strip():
            parts.append("--- ENTRADA ---\n" + data)
    for f in a.file:
        parts.append(f"--- ARQUIVO {f} ---\n" + Path(f).read_text())

    body = json.dumps({
        "model": a.model or default_model,
        "messages": [{"role": "system", "content": a.system}, {"role": "user", "content": "\n\n".join(parts)}],
        "max_tokens": a.max_tokens,
    }).encode()
    headers = {"Content-Type": "application/json", "User-Agent": "llm-gratis/1.0"}
    if key:
        headers["Authorization"] = f"Bearer {key}"
    req = urllib.request.Request(url, body, headers)

    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=180) as r:
                out = json.load(r)
            text = ((out.get("choices") or [{}])[0].get("message") or {}).get("content") or ""
            if text.strip():
                print(text.strip())
                return
            if attempt < 2:
                continue  # resposta vazia (modelo gastou tudo raciocinando): tenta de novo
            sys.exit(f"Resposta vazia ({a.provider}, {a.model or default_model}); tente -p llm7 ou outro -m")
        except urllib.error.HTTPError as e:
            msg = e.read().decode(errors="replace")[:500]
            if e.code == 429 and attempt < 2:
                time.sleep(int(e.headers.get("retry-after", "10") or 10))
                continue
            sys.exit(f"Erro HTTP {e.code} ({a.provider}): {msg}")
        except urllib.error.URLError as e:
            sys.exit(f"Erro de rede ({a.provider}): {e.reason}")


if __name__ == "__main__":
    main()
