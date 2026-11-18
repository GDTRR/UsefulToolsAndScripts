# Sample Mail Sender

`Send-Email.ps1` is a Windows PowerShell script for sending plain-text email through either:

- an SMTP server without authentication (default: `smtp.enru.io:25`), or
- SendGrid at `smtp.sendgrid.net:587` with TLS and authentication.

It can send one message or a numbered batch of up to 1,000 messages. Every message includes its request time in the subject and body, while request, acceptance, failure, and elapsed-time details are written to a log.

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- Network access to the selected SMTP server and port
- Permission to relay mail through that server
- A verified sender and valid credentials when using SendGrid

## Quick start

Open PowerShell in this directory and send one unauthenticated message:

```powershell
.\Send-Email.ps1 `
  -From "sender@example.com" `
  -To "recipient@example.com" `
  -Subject "SMTP test" `
  -Body "Hello from PowerShell"
```

Send five numbered messages:

```powershell
.\Send-Email.ps1 `
  -From "sender@example.com" `
  -To "recipient@example.com" `
  -Subject "Volume test" `
  -Body "Test message" `
  -MessageCount 5
```

Send through SendGrid with a secure credential prompt:

```powershell
$credential = Get-Credential -UserName "apikey"

.\Send-Email.ps1 `
  -UseSendGrid `
  -Credential $credential `
  -From "verified-sender@example.com" `
  -To "recipient@example.com" `
  -Subject "SendGrid test" `
  -Body "Hello from SendGrid"
```

See [docs/USAGE.md](docs/USAGE.md) for all parameters, examples, logging details, and troubleshooting.

## Safety

`-SendVolume` and `-MessageCount` send real email. Use them only with SMTP infrastructure and recipients authorized for volume testing. Prefer `-Credential` over `-Passkey`, because a passkey supplied on the command line may remain in PowerShell history.

