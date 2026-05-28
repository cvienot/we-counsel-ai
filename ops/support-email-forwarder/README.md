# Support Email Forwarder

This Lambda backs `support@we-connect-app.com`.

Inbound mail is received by Amazon SES in `eu-west-1`, stored in S3, then
forwarded to the configured operator inbox from `support@we-connect-app.com`.
The forwarded message keeps the original sender in `Reply-To` so replying from
Gmail goes back to the customer.

Required environment variables:

- `INBOUND_BUCKET`: S3 bucket containing raw SES inbound messages.
- `INBOUND_PREFIX`: S3 prefix for support messages, currently `support/`.
- `FORWARD_FROM`: verified sender, currently `support@we-connect-app.com`.
- `FORWARD_TO`: monitored mailbox.
- `SEND_REGION`: SES send region, currently `eu-west-3`.
