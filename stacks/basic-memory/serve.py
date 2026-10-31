"""Basic Memory over streamable HTTP, protected by Authentik (OIDC) via FastMCP's OIDCProxy.
Bound to loopback only; reached from the internet through the <redacted-domain> Cloudflare Tunnel."""
import os

os.environ["BASIC_MEMORY_FORCE_LOCAL"] = "true"
os.environ.pop("BASIC_MEMORY_FORCE_CLOUD", None)
os.environ["BASIC_MEMORY_EXPLICIT_ROUTING"] = "true"

import basic_memory.mcp.tools  # noqa: F401  (registers tools)
import basic_memory.mcp.prompts  # noqa: F401
import basic_memory.mcp.resources  # noqa: F401
from basic_memory.config import init_mcp_logging
from basic_memory.mcp.server import mcp
from fastmcp.server.auth.oidc_proxy import OIDCProxy

init_mcp_logging()

PUBLIC_URL = os.environ.get("BM_PUBLIC_URL", "https://<redacted-domain>")
CLIENT_ID = os.environ["BM_OIDC_CLIENT_ID"]

mcp.auth = OIDCProxy(
    config_url="https://<redacted-domain>/application/o/basic-memory/.well-known/openid-configuration",
    client_id=CLIENT_ID,
    client_secret=os.environ["BM_OIDC_CLIENT_SECRET"],
    audience=CLIENT_ID,
    base_url=PUBLIC_URL,
    jwt_signing_key=os.environ["BM_JWT_SIGNING_KEY"],
    valid_scopes=["openid", "profile", "email", "offline_access"],
    # Only Claude's connector callbacks may register as clients
    allowed_client_redirect_uris=[
        "https://claude.ai/api/mcp/auth_callback",
        "https://claude.com/api/mcp/auth_callback",
        "http://127.0.0.1:*/mcp-oauth-callback",
        "http://localhost:*/mcp-oauth-callback",
    ],
)

mcp.run(
    transport="streamable-http",
    host="127.0.0.1",
    port=int(os.environ.get("BM_PORT", "8765")),
    path="/mcp",
    log_level="INFO",
    host_origin_protection=True,
)
