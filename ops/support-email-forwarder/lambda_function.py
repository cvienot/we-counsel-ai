import email
import os
from email.header import decode_header, make_header
from email.message import EmailMessage
from email.utils import getaddresses, parseaddr

import boto3


s3 = boto3.client("s3")
ses = boto3.client("ses", region_name=os.environ.get("SEND_REGION", "eu-west-3"))


def _header(value, fallback=""):
    if not value:
        return fallback
    try:
        return str(make_header(decode_header(value)))
    except Exception:
        return value


def _body_part(message):
    if message.is_multipart():
        for part in message.walk():
            if part.get_content_maintype() == "multipart":
                continue
            disposition = part.get_content_disposition()
            if disposition == "attachment":
                continue
            if part.get_content_type() == "text/plain":
                return part
        for part in message.walk():
            if part.get_content_type() == "text/html":
                return part
        return None

    return message


def _body_text(message):
    part = _body_part(message)
    if part is None:
        return "(No readable message body found.)"

    payload = part.get_payload(decode=True)
    if payload is None:
        payload = part.get_payload()
        if isinstance(payload, str):
            return payload
        return "(No readable message body found.)"

    charset = part.get_content_charset() or "utf-8"
    return payload.decode(charset, errors="replace")


def handler(event, context):
    record = event["Records"][0]
    mail = record["ses"]["mail"]
    message_id = mail["messageId"]

    bucket = os.environ["INBOUND_BUCKET"]
    prefix = os.environ.get("INBOUND_PREFIX", "support/")
    destination = os.environ["FORWARD_TO"]
    source = os.environ["FORWARD_FROM"]

    obj = s3.get_object(Bucket=bucket, Key=f"{prefix}{message_id}")
    raw = obj["Body"].read()
    original = email.message_from_bytes(raw)

    original_from = _header(original.get("From"), "unknown sender")
    original_to = _header(original.get("To"), ", ".join(mail.get("destination", [])))
    original_subject = _header(original.get("Subject"), "(no subject)")
    original_date = _header(original.get("Date"), "")
    reply_to = original.get("Reply-To") or original.get("From") or source
    reply_to_addr = parseaddr(reply_to)[1] or source

    forwarded = EmailMessage()
    forwarded["From"] = f"We Connect Support <{source}>"
    forwarded["To"] = destination
    forwarded["Reply-To"] = reply_to_addr
    forwarded["Subject"] = f"[We Connect support] {original_subject}"

    recipients = ", ".join(addr for _, addr in getaddresses([original_to]) if addr)
    body = _body_text(original)
    forwarded.set_content(
        "\n".join(
            [
                "New message received at support@we-connect-app.com",
                "",
                f"From: {original_from}",
                f"To: {recipients or original_to}",
                f"Date: {original_date}",
                f"Original subject: {original_subject}",
                "",
                "--- Message body ---",
                body,
            ]
        )
    )

    ses.send_raw_email(
        Source=source,
        Destinations=[destination],
        RawMessage={"Data": forwarded.as_bytes()},
    )

    return {"messageId": message_id, "forwardedTo": destination}
