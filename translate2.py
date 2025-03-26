import ctypes
import socket
import sys
import os
from datetime import datetime, timedelta
from urllib.parse import quote_plus
import functools

import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

from dotenv import load_dotenv
import requests
from celery.apps import worker
from celery import Celery
from loguru import logger

load_dotenv('prod.env')

google_translate_api = "https://translate.googleapis.com/translate_a/single"
default_proxies = {
    "http": os.environ.get("HTTP_PROXY", ""),
    "https": os.environ.get("HTTPS_PROXY", ""),
}
default_headers = {
    "x-client-data": "CJe2yQEIo7bJAQjEtskBCKmdygEImbXKAQisx8oBCOnIygEI3NXKAQie+csB",
    "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36",
}
default_hostname = socket.gethostname()


def wrap_celery_safe_say(msg, f=sys.__stderr__):
    logger.info(f"<worker> {msg}")


worker.safe_say = wrap_celery_safe_say

logger.remove()
logger.add(
    sink=sys.stdout,
    level="INFO",
    format="{time:YYYY/MM/DD HH:mm:ss.SSS} [{level: >7}]: {message}",
    backtrace=True,
)

app = Celery("crawlab.translate")
amqp_url = os.environ.get("AMQP_URL")
app.conf.update(
    accept_content=["msgpack", "json"],
    #
    broker_url=amqp_url,
    broker_connection_retry_on_startup=True,
    #
    # result_backend="rpc://",
    result_backend=amqp_url,
    result_serializer="msgpack",
    # result_expires=timedelta(hours=1),
    result_persistent=True,
    result_exchange="crawlab",
    result_exchange_type="direct",
    result_accept_content=["msgpack"],
    #
    task_acks_late=False,
    task_default_exchange="crawlab",
    task_default_exchange_type="direct",
    task_default_queue="crawlab.translate.task",
    task_default_rate_limit="15/s",
    task_ignore_result=False,
    task_send_sent_event=True,
    task_serializer="msgpack",
    task_track_started=False,
    task_reject_on_worker_lost=True,
    task_protocol=1,
    #
    worker_enable_remote_control=True,
    worker_max_tasks_per_child=1000,
    # worker_prefetch_multiplier=4,
    # worker_concurrency=10,
    worker_send_task_events=True,
    worker_log_format="%(asctime)s [%(levelname)7s]: <worker> %(message)s",
    worker_task_log_format="%(asctime)s [%(levelname)7s]: %(task_name)s[%(task_id)s] %(message)s",
)


# Translate Sign
def sign_tk(content):
    def _int_overflow(val):
        maxint = 2147483647
        if not -maxint - 1 <= val <= maxint:
            val = (val + (maxint + 1)) % (2 * (maxint + 1)) - maxint - 1
        return val

    def _unsigned_right_shitf(n, i):
        if n < 0:
            n = ctypes.c_uint32(n).value
        if i < 0:
            return -_int_overflow(n << abs(i))
        return _int_overflow(n >> i)

    def _sign(data, key):
        for i in range(0, len(key) - 2, 3):
            r = key[i + 2]
            if "a" <= r:
                r = ord(r[0]) - 87
            else:
                r = int(r)
            r = _unsigned_right_shitf(data, r) if "+" == key[i + 1] else data << r
            data = data + r & 4294967295 if "+" == key[i] else data ^ r
        return data

    buffer = []
    n = 0
    for i in range(len(content)):
        charCode = ord(content[i])
        if 128 > charCode:
            buffer.append(charCode)
        else:
            if 2048 > charCode:
                buffer.append(charCode >> 6 | 192)
            else:
                buffer.append(charCode >> 12 | 224)
                buffer.append(charCode >> 6 & 63 | 128)
            buffer.append(63 & charCode | 128)

    result = 0
    for n in range(len(buffer)):
        result += buffer[n]
        result = _sign(result, "+-a^+6")
    result = _sign(result, "+-3^+b+-f")
    if 0 > result:
        result = 2147483648 + (2147483647 & result)
    result %= 1e6
    result = int(result)
    return f"{result}.{0 ^ result}"


def do_google_trans(sl, tl, content):
    try:
        translated_items = []
        tk = sign_tk(content)
        params = f"client=gtx&sl={sl}&tl={tl}&dj=1&dt=t&dt=bd&dt=qc&dt=rm&dt=ex&dt=at&dt=ss&dt=rw&dt=ld"
        # sl: source language
        # tl: target language
        # dj: JSON format
        url = f"{google_translate_api}?{params}&q={quote_plus(content)}&tk={tk}"
        r = requests.get(
            url,
            headers=default_headers,
            proxies=default_proxies,
            verify=False,
            timeout=60,
        )
        r.raise_for_status()
        reply = r.json()
        for item in reply.get("sentences", []):
            if not item:
                continue
            translated = item.get("trans", None)
            if translated:
                translated_items.append(translated)
        return True, "".join(translated_items)
    except Exception as exc:
        return False, exc


@app.task(
    bind=True,
    name="crawlab.translate.task.app",
    ignore_result=False,
    ack_late=False,
    track_started=True,
    reject_on_worker_lost=True,
    rate_limit="5/s",
    max_retries=5,
    default_retry_delay=300,
)
def translate_message(self, data: dict):
    started_at = datetime.now().timestamp()
    param = data.get("param", {})
    sl = param.get("sl", "auto")
    tl = param.get("tl", "en")
    body = data.get("body", {})
    fields = data.get("fields", [])

    try:
        for field in fields:
            value_ = body.get(field, None)
            if value_:
                ok, translated_or_exc = do_google_trans(sl, tl, value_)
                if ok:
                    body[f"{field}_trans"] = translated_or_exc
                else:
                    body[f"{field}_trans"] = ""
                    logger.error(
                        f"{self.name}[{self.request.id}] failed to translate {field}: {translated_or_exc}"
                    )
                    continue

        return {
            "id": self.request.id,
            "host": default_hostname,
            "duration": datetime.now().timestamp() - started_at,
            "param": param,
            "body": body,
        }

    except Exception as exc:
        raise self.retry(exc=exc)
