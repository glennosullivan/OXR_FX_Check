# requires -version 2
<#
.SYNOPSIS
.DESCRIPTION
The script takes the current exchange rate and converts to Euro base
then checks if the value is under a threshold
If so an alert is sent via email and sms
.INPUTS
OXR excahnge rates
.OUTPUTS
Email / Twillo SMS alert
.NOTES
  Version:        1.0
  Author:         Glenn O'Sullivan
  Creation Date:  19/02/2021
  Purpose/Change: Initial script development
  
.EXAMPLE
./FX.ps1
#>
#make api call and take base, euro and time values
$doc = (New-Object System.Net.WebClient).DownloadString("https://openexchangerates.org/api/latest.json?app_id=xxxxxxxxxxxxxxxxxxxxxxxxx")
$doc2 = ConvertFrom-Json -InputObject $doc
$base = $doc2.base
$basevalue = 1
$euro = $doc2.rates.EUR
$time = $doc2.timestamp

# swap from USD base to Eur and limit 4 decimels 
$eurbase = $basevalue / $euro 
$eurbase = [math]::Round($newbase,4)
# convert time from epoch to datetime 
$date = (Get-Date 1/1/1970).AddSeconds($time)
$date = $date.ToString("dd/MM/yyyy HH:mm")

#set the alert level
$Alertlevel = 1.20
#check if current FX is eq or lower to the alert
if ("$eurbase" -le "$Alertlevel")
{

 # structure the mail
$body = "USD value as fallen below the alert level of $Alertlevel `n"
$body += "`n"
$body += "Value as of $date `n"
$body += "Base currency is EUR = 1`n"
$body += "Quote currency USD = $newbase`n"
$body += "`n"
$body += "`n"
$body += "Note: this value was taken from open exchange rates"

#Set the smtp details
$SmtpServer = 'smtp.live.com'
$SmtpUser = 'xxxxxxxxxxxxxxxxxxxxxxxxx@outlook.com'
$smtpPassword = 'xxxxxxxxxxxxxxxxxxxxxxxxx'
$MailFrom = 'xxxxxxxxxxxxxxxxxxxxxxxxx@outlook.com'
$MailSubject =  "FX hourly check " 
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $SmtpUser, $($smtpPassword | ConvertTo-SecureString -AsPlainText -Force) 

#Send mail
Send-MailMessage -To "xxxxxxxxxxxxxxxxxxxxxxxxx" -from "$MailFrom" -Subject $MailSubject  -body $body -SmtpServer $SmtpServer -Port 587 -Credential $Credentials -UseSsl

#Send Twillio SMS
$message = "USD has fallen below alert level, current value $eurbase"

$sid = "xxxxxxxxxxxxxxxxxxxxxxxxx"
$token = "xxxxxxxxxxxxxxxxxxxxxxxxx"
$number = "+xxxxxxxxxxxxxxxxxxxxxxxxx"
$recipient = "+xxxxxxxxxxxxxxxxxxxxxxxxx" 
$url = "https://api.twilio.com/2010-04-01/Accounts/$sid/Messages.json"
$params = @{ To = $recipient; From = $number; Body = $message }

# Create a credential object for HTTP basic auth
$p = $token | ConvertTo-SecureString -asPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($sid, $p)

# Make API request, selecting JSON properties from response
Invoke-WebRequest $url -Method Post -Credential $credential -Body $params  -UseBasicParsing |
ConvertFrom-Json | Select-object sid, body


}

