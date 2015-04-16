$xml_file = [xml](get-content $args[0])
$arr_value = $args[1]
$arr_name = $args[2]
$arr_counter = $args[3]
$counter = $args[4]

if($args.count -eq 6)
{
	$root = $xml_file.variables.($args[5])
}
elseif($args.count -eq 7)
{	
	$root = $xml_file.variables.($args[5]).($args[6])
}
elseif($args.count -eq 8)
{
	$root = $xml_file.variables.($args[5]).($args[6]).($args[7])
}
elseif($args.count -eq 9)
{
	$nodes = $xml_file.variables.($args[5]).($args[6]).($args[7]).($args[8])
}

foreach ($node in $root.ChildNodes)
{
	$counter += 1
	$value = $node.InnerText
	$name = $node.Name
	Write-Host set "$arr_value[$counter]=$value"
	Write-Host set "$arr_name[$counter]=$name"
}

Write-Host set "$arr_counter=$counter"