import base64
import hashlib
import hmac
from email.utils import formatdate
from urllib.parse import urlencode


def build_auth_url(host: str, path: str, api_key: str, api_secret: str) -> str:
    date = formatdate(timeval=None, localtime=False, usegmt=True)
    signature_origin = f"host: {host}\ndate: {date}\nGET {path} HTTP/1.1"
    signature = base64.b64encode(
        hmac.new(api_secret.encode(), signature_origin.encode(), hashlib.sha256).digest()
    ).decode()
    authorization_origin = (
        f'api_key="{api_key}", algorithm="hmac-sha256", '
        f'headers="host date request-line", signature="{signature}"'
    )
    authorization = base64.b64encode(authorization_origin.encode()).decode()
    params = urlencode({"authorization": authorization, "date": date, "host": host})
    return f"wss://{host}{path}?{params}"
