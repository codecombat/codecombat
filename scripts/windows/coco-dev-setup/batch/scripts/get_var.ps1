$xml_file = [xml](get-content $args[0])
if($args.count -eq 2)
{
    $var_output = ($xml_file.variables.($args[1]))
}
elseif($args.count -eq 3)
{
    $var_output = ($xml_file.variables.($args[1]).($args[2]))
}
elseif($args.count -eq 4)
{
    $var_output = ($xml_file.variables.($args[1]).($args[2]).($args[3]))
}
elseif($args.count -eq 5)
{
    $var_output = ($xml_file.variables.($args[1]).($args[2]).($args[3]).($args[4]))
}
elseif($args.count -eq 6)
{
    $var_output = ($xml_file.variables.($args[1]).($args[2]).($args[3]).($args[4]).($args[5]))
}
elseif($args.count -eq 7)
{
    $var_output = ($xml_file.variables.($args[1]).($args[2]).($args[3]).($args[4]).($args[5]).($args[6]))
}

Write-Host "$var_output"