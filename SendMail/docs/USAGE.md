# Send-Email.ps1 Usage Guide

## Basic syntax

```powershell
.\Send-Email.ps1 -From <address> -To <address> -Subject <text> -Body <text> [options]
```

The four required parameters are `-From`, `-To`, `-Subject`, and `-Body`.

## Parameters

| Parameter | Required | Default | Description |
| --- | --- | --- | --- |
| `-From` | Yes | — | Sender email address. |
| `-To` | Yes | — | Recipient email address. |
| `-Subject` | Yes | — | Base subject. The script adds the request timestamp and, for batches, the message number. |
| `-Body` | Yes | — | Plain-text message body. The script appends the send timestamp. |
| `-SmtpServer` | No | `smtp.enru.io` | SMTP server used when SendGrid mode is off. |
| `-Port` | No | `25` | SMTP port used when SendGrid mode is off. Valid range: 1–65535. |
| `-LogFile` | No | `Send-Email.log` beside the script | Destination for send-event logs. |
| `-UseSendGrid` | No | Off | Overrides the server with `smtp.sendgrid.net:587`, enables TLS, and requires authentication. |
| `-Credential` | No | — | PowerShell credential object used for SendGrid authentication. |
| `-SmtpUser` | No | `apikey` | Username used with `-Passkey`. |
| `-Passkey` | No | — | SendGrid password or API key supplied as plain text. Do not combine with `-Credential`. |
| `-SendVolume` | No | Off | Sends 1,000 messages unless `-MessageCount` specifies another total. Cannot be combined with `-UseSendGrid`. |
| `-MessageCount` | No | 1 normally; 1,000 with `-SendVolume` | Number of messages to send. Valid range: 1–1000. |

## Unauthenticated SMTP examples

### Send one message

```powershell
.\Send-Email.ps1 `
  -From "sender@example.com" `
  -To "recipient@example.com" `
  -Subject "Test message" `
  -Body "This is a test."
```

### Override the SMTP server and port

```powershell
.\Send-Email.ps1 `
  -SmtpServer "mail.example.net" `
  -Port 2525 `
  -From "sender@example.com" `
  -To "recipient@example.com" `
  -Subject "Relay test" `
  -Body "Testing a custom SMTP relay."
```

Custom unauthenticated SMTP mode does not enable TLS or authentication.

## SendGrid examples

### Recommended: secure credential prompt

```powershell
$credential = Get-Credential -UserName "apikey" -Message "Enter the SendGrid API key as the password"

.\Send-Email.ps1 `
  -UseSendGrid `
  -Credential $credential `
  -From "verified-sender@example.com" `
  -To "recipient@example.com" `
  -Subject "SendGrid test" `
  -Body "This message uses SendGrid."
```

### Supply a passkey directly

```powershell
.\Send-Email.ps1 `
  -UseSendGrid `
  -SmtpUser "apikey" `
  -Passkey "YOUR_SENDGRID_API_KEY" `
  -From "verified-sender@example.com" `
  -To "recipient@example.com" `
  -Subject "SendGrid test" `
  -Body "This message uses SendGrid."
```

The script does not write the passkey to its log, but PowerShell may retain a command containing `-Passkey` in its history.

## Sending multiple messages

Use `-MessageCount` to choose an exact count:

```powershell
.\Send-Email.ps1 `
  -MessageCount 10 `
  -From "sender@example.com" `
  -To "recipient@example.com" `
  -Subject "Volume test" `
  -Body "Numbered test message"
```

The subjects are numbered and zero-padded to the width of the total:

```text
Volume test 01 of 10 [2026-11-17 15:30:01 -06:00]
Volume test 02 of 10 [2026-11-17 15:30:02 -06:00]
...
Volume test 10 of 10 [2026-11-17 15:30:10 -06:00]
```

Examples at other sizes include `001 of 100` and `0001 of 1000`.

Use `-SendVolume` without a count to send 1,000 messages through unauthenticated SMTP:

```powershell
.\Send-Email.ps1 `
  -SendVolume `
  -From "sender@example.com" `
  -To "authorized-test-recipient@example.com" `
  -Subject "Volume test" `
  -Body "SMTP load test"
```

Do not combine `-SendVolume` with `-UseSendGrid`.

## Timestamps

The request time is captured immediately before each SMTP send. It is added to the subject:

```text
Test message [2026-11-17 15:30:01 -06:00]
```

It is also appended to the body:

```text
This is a test.

Sent at: 2026-11-17 15:30:01 -06:00
```

The UTC offset makes the timestamp unambiguous across time zones.

## Logging

By default, events are displayed in PowerShell and appended to `Send-Email.log` beside the script:

```text
2026-11-17T15:30:01.1234567-06:00 SEND_REQUESTED message=1/1 server=smtp.enru.io:25 from=sender@example.com to=recipient@example.com
2026-11-17T15:30:01.4567890-06:00 SMTP_ACCEPTED message=1/1 server=smtp.enru.io:25 to=recipient@example.com elapsed_ms=333
```

Failures produce a `SEND_FAILED` event. `SMTP_ACCEPTED` means the configured SMTP server accepted the message; it does not guarantee final inbox delivery.

Choose another log file with:

```powershell
-LogFile "C:\Logs\smtp-test.log"
```

The destination directory must already exist and be writable.

## Script execution policy

If Windows prevents the script from running, use a one-time process-level bypass:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Send-Email.ps1 `
  -From "sender@example.com" `
  -To "recipient@example.com" `
  -Subject "Test" `
  -Body "Hello"
```

## Troubleshooting

- **Connection refused or timed out:** Confirm the hostname, port, firewall rules, and network route. Many networks block outbound port 25.
- **Relay denied:** The unauthenticated SMTP server does not permit your machine or sender to relay mail. Ask the SMTP administrator for access.
- **SendGrid authentication failed:** Check the username, passkey/API key, permissions, and whether the key is active.
- **SendGrid sender rejected:** Confirm that the `-From` address or its domain is verified in the SendGrid account.
- **Accepted but not delivered:** Check the SMTP provider's activity, suppression, bounce, and spam-filter records.
- **Log cannot be written:** Create the log directory or select a writable location using `-LogFile`.

