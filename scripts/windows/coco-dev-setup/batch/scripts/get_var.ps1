$xml_file = [xml](get-content $args[0])
if($args.count -eq 2)
{
    $xml_file.variables.($args[1])
}
elseif($args.count -eq 3)
{
    $xml_file.variables.($args[1]).($args[2])
}
elseif($args.count -eq 4)
{
    $xml_file.variables.($args[1]).($args[2]).($args[3])
}
elseif($args.count -eq 5)
{
    $xml_file.variables.($args[1]).($args[2]).($args[3]).($args[4])
}