$json_in = [Console]::In.ReadLine()
$json = ConvertFrom-Json $json_in

$terraformSubscriptionId = $json.subscriptionId
$terraformResourceGroup = $json.resourceGroup

try {
    az group show --name $terraformResourceGroup --subscription Get-AzSubscription -SubscriptionId $terraformSubscriptionId > $null
    $out_json = @{
        qty = "1";
    } | ConvertTo-Json
} catch {
    $out_json = @{
        qty = "0";
    } | ConvertTo-Json
    Write-Error $_
    exit 1
}
Write-Output $out_json