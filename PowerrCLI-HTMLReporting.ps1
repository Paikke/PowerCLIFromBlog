# Details on this script are described in the following https://pascalswereld.nl/2014/05/13/powercli-reporting-html/
# 

# Settings
# vCenter Connection details
$vCenterFQDN=”<vcenter>”
$vCenterUser=”<user>”
$vCenterPass=”<password>”

# Name of the Cluster on which you need to run the report
$ClusterName=”<cluster>”

#Location where you want to place generated report
$OutputPath=”<output path>”

# Set the SMTP Server address
$SMTPSRV = “<SMTP Server>”

# Set the Email address to recieve from
$EmailFrom = “<from email address>”

# Set the Email address to send the email to, comma separate when using multiple reciptients
$EmailTo = “<to e-mail address>”

Write-Host “Connecting to vCenter” -foregroundcolor “red”
Connect-VIServer -Server $vCenterFQDN -User $vCenterUser -Password $vCenterPass

# Style of the Report in Css
$Css=”<style>
body {
	font-family: Verdana, sans-serif;
	font-size: 14px;
	color: #666666;
	background: #FEFEFE;
}
#title{
	color:#FF0000;
	font-size: 30px;
	font-weight: bold;
	padding-top:25px;
	margin-left:35px;
	height: 50px;
}
#subtitle{
	font-size: 11px;
	margin-left:35px;
}
#main {
	position:relative;
	padding-top:10px;
	padding-left:10px;
	padding-bottom:10px;
	padding-right:10px;
}
#box1{
	position:absolute;
	background: #F8F8F8;
	border: 1px solid #DCDCDC;
	margin-left:10px;
	padding-top:10px;
	padding-left:10px;
	padding-bottom:10px;
	padding-right:10px;
}
#boxheader{
	font-family: Arial, sans-serif;
	padding: 5px 20px;
	position: relative;
	z-index: 20;
	display: block;
	height: 30px;
	color: #777;
	text-shadow: 1px 1px 1px rgba(255,255,255,0.8);
	line-height: 33px;
	font-size: 19px;
	background: #fff;
	background: -moz-linear-gradient(top, #ffffff 1%, #eaeaea 100%);
	background: -webkit-gradient(linear, left top, left bottom, color-stop(1%,#ffffff), color-stop(100%,#eaeaea));
	background: -webkit-linear-gradient(top, #ffffff 1%,#eaeaea 100%);
	background: -o-linear-gradient(top, #ffffff 1%,#eaeaea 100%);
	background: -ms-linear-gradient(top, #ffffff 1%,#eaeaea 100%);
	background: linear-gradient(top, #ffffff 1%,#eaeaea 100%);
	filter: progid:DXImageTransform.Microsoft.gradient( startColorstr=’#ffffff’, endColorstr=’#eaeaea’,GradientType=0 );
	box-shadow:
		0px 0px 0px 1px rgba(155,155,155,0.3),
		1px 0px 0px 0px rgba(255,255,255,0.9) inset,
		0px 2px 2px rgba(0,0,0,0.1);
}

table{
	width:100%;
	border-collapse:collapse;
}
table td, table th {
	border:1px solid #FA5858;
	padding:3px 7px 2px 7px;
}
table th {
	text-align:left;
	padding-top:5px;
	padding-bottom:4px;
	background-color:#FA5858;
	color:#fff;
}
table tr.alt td {
	color:#000;
	background-color:#F5A9A9;
}
</style>”
# End the Style.

# HTML Markup
$PageBoxOpener=”<div id=’box1’>”
$ReportClusterStats=”<div id=’boxheader’>ClusterTotal $ClusterName</div>”
$ReportClusterHeader=”<table><tr><th>vCPU Count</th><th>Memory GB Total</th></tr>”
$BoxContentOpener=”<div id=’boxcontent’>”
$PageBoxCloser=”</div>”
$br=”<br>”
$ReportGetVmCluster=”<div id=’boxheader’>VM Details $ClusterName</div>”

Write-Host “Getting Cluster Details for CPU and Memory totals” -foregroundcolor “red”
#Get VMHost info for CPU and Memory totals
$countcpu = 0
$countmem = 0
$MemoryGBtot = 0
$cpu=Get-VM -Location (Get-Cluster -Name $ClusterName) | Select-Object NumCPU
Foreach ($itemcpu in $cpu) { $countcpu += $itemcpu.NumCpu }

$memory=Get-VM -Location (Get-Cluster -Name $ClusterName) | Select-Object @{Name = ‘MemoryGBtot’; Expression = {“{0:N2}” -f ($_.MemoryGB)}}
Foreach ($itemmem in $memory) { $countmem += $itemmem.MemoryGBtot }
	# Now we have $countcpu and $countmem for cluster totals
	# Memory should be formatted to two decimals

	Write-Host “Getting VM information for $ClusterName” -foregroundcolor “red”
	#Get VM infos
	$GetVmCluster=Get-VM -Location (Get-Cluster -Name $ClusterName) | Select-Object Name,PowerState,NumCPU, MemoryGB | Sort-Object Name | ConvertTo-HTML -Fragment

	# Create HTML report
	# and export to HTML out file
	# Use $fileNameReport = “$OutputPathReportVMDetails-$ClusterName-$(Get-Date -Format o | foreach {$_ -replace “:”, “.”}).html” and | Out-File $fileNameReport when wanting to save
	$MyReport = ConvertTo-Html -Title “VM Details Report” -Head “<div id=’title’>VM CPU and Memory Reporting</div>$br<div id=’subtitle’>Report generated on: $(Get-Date)</div>” -Body ” $Css $PageBoxOpener $ReportClusterStats $BoxContentOpener $ReportClusterHeader <tr><td>$countcpu</td> <td>$countmem</td></tr> $PageBoxCloser </table> $br $ReportGetVmCluster $BoxContentOpener $GetVmCluster $PageBoxCloser”

	# Disconnect
	Write-Host “Closing vCenter connection” -foregroundcolor “red”
	Disconnect-VIServer -Confirm:$false

	function Send-SMTPmail($to, $from, $subject, $smtpserver, $body) {
		$mailer = new-object Net.Mail.SMTPclient($smtpserver)
		$msg = new-object Net.Mail.MailMessage($from,$to,$subject,$body)
		$msg.IsBodyHTML = $true
		$mailer.send($msg)
	}

Write-Host “Sending e-mail” -foregroundcolor “red”
# Sending the report
Send-SMTPmail $EmailTo $EmailFrom “$ClusterName Capacity Report $(Get-Date)” $SMTPSRV $MyReport
