$url = ($args[0].ToLower())

if($url.Contains("zip"))
{
	Write-Host "zip"
}
elseif($url.Contains("exe"))
{
	Write-Host "exe"
}
elseif($url.Contains("msi"))
{
	Write-Host "msi"
}
elseif($url.Contains("tar.gz"))
{
	Write-Host "tar.gz"
}