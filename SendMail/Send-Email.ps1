param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$From,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$To,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Subject,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Body,

    [string]$SmtpServer = "smtp.enru.io",

    [ValidateRange(1, 65535)]
    [int]$Port = 25,

    [string]$LogFile = (Join-Path $PSScriptRoot "Send-Email.log"),

    [switch]$UseSendGrid,

    [System.Management.Automation.PSCredential]$Credential,

    [string]$SmtpUser = "apikey",

    [string]$Passkey,

    [switch]$SendVolume,

    [ValidateRange(1, 1000)]
    [int]$MessageCount = 1000
)

$ErrorActionPreference = "Stop"

if ($SendVolume -and $UseSendGrid) {
    throw "-SendVolume cannot be combined with -UseSendGrid. Volume mode uses the unauthenticated SMTP server."
}

if ($UseSendGrid) {
    if ($null -eq $Credential -and [string]::IsNullOrWhiteSpace($Passkey)) {
        throw "Specify either -Credential or -Passkey when -UseSendGrid is used."
    }

    if ($null -ne $Credential -and -not [string]::IsNullOrWhiteSpace($Passkey)) {
        throw "Specify -Credential or -Passkey, but not both."
    }

    $SmtpServer = "smtp.sendgrid.net"
    $Port = 587
}

function Write-MailLog {
    param([Parameter(Mandatory = $true)][string]$Message)

    $entry = "{0} {1}" -f [DateTimeOffset]::Now.ToString("o"), $Message
    Write-Host $entry
    Add-Content -LiteralPath $LogFile -Value $entry -Encoding UTF8
}

$client = [System.Net.Mail.SmtpClient]::new($SmtpServer, $Port)

try {
    # The default server uses no authentication or TLS. SendGrid uses both.
    $client.UseDefaultCredentials = $false
    if ($UseSendGrid) {
        if ($null -ne $Credential) {
            $client.Credentials = $Credential.GetNetworkCredential()
        }
        else {
            $client.Credentials = [System.Net.NetworkCredential]::new($SmtpUser, $Passkey)
        }
        $client.EnableSsl = $true
    }
    else {
        $client.Credentials = $null
        $client.EnableSsl = $false
    }

    $totalMessages = if ($PSBoundParameters.ContainsKey("MessageCount")) {
        $MessageCount
    }
    elseif ($SendVolume) {
        1000
    }
    else {
        1
    }

    for ($messageNumber = 1; $messageNumber -le $totalMessages; $messageNumber++) {
        $message = [System.Net.Mail.MailMessage]::new()
        $stopwatch = [System.Diagnostics.Stopwatch]::new()

        try {
            $requestInitiatedAt = [DateTimeOffset]::Now
            $requestTimeText = $requestInitiatedAt.ToString("yyyy-MM-dd HH:mm:ss zzz")
            $subjectPrefix = if ($totalMessages -gt 1) {
                $numberWidth = $totalMessages.ToString().Length
                $paddedMessageNumber = $messageNumber.ToString("D${numberWidth}")
                "{0} {1} of {2}" -f $Subject, $paddedMessageNumber, $totalMessages
            }
            else {
                $Subject
            }

            $message.From = $From
            $message.To.Add($To)
            $message.Subject = "{0} [{1}]" -f $subjectPrefix, $requestTimeText
            $message.Body = "{0}{1}{1}Sent at: {2}" -f `
                $Body, `
                [Environment]::NewLine, `
                $requestTimeText
            $message.IsBodyHtml = $false

            Write-MailLog "SEND_REQUESTED message=${messageNumber}/${totalMessages} server=${SmtpServer}:${Port} from=${From} to=${To}"
            $stopwatch.Start()
            $client.Send($message)
            $stopwatch.Stop()
            Write-MailLog "SMTP_ACCEPTED message=${messageNumber}/${totalMessages} server=${SmtpServer}:${Port} to=${To} elapsed_ms=$($stopwatch.ElapsedMilliseconds)"
        }
        finally {
            $message.Dispose()
        }
    }
}
catch {
    if ($null -ne $stopwatch) {
        $stopwatch.Stop()
    }
    Write-MailLog "SEND_FAILED message=${messageNumber}/${totalMessages} server=${SmtpServer}:${Port} to=${To} elapsed_ms=$($stopwatch.ElapsedMilliseconds) error=$($_.Exception.Message)"
    Write-Error "Email could not be sent: $($_.Exception.Message). See $LogFile"
    exit 1
}
finally {
    $client.Dispose()
}
